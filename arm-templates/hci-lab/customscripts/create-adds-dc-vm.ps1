[CmdletBinding()]
param ()

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
$WarningPreference = [Management.Automation.ActionPreference]::Continue
$VerbosePreference = [Management.Automation.ActionPreference]::Continue
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

Import-Module -Name '.\shared.psm1' -Force

$configParams = GetConfigParameters
Start-Transcript -OutputDirectory $configParams.labHost.folderPath.transcript
$configParams | ConvertTo-Json -Depth 16

function WaitingForReadyToDC
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $VMName,

        [Parameter(Mandatory = $true)]
        [PSCredential] $Credential,

        [Parameter(Mandatory = $false)]
        [int] $CheckInternal = 5
    )

    $params = @{
        VMName       = $VMName
        Credential   = $Credential
        ArgumentList = $VMName  # The DC's computer name is the same as the VM name. It's specified in the unattend.xml.
        ScriptBlock  = {
            $dcComputerName = $args[0]
            (Get-ADDomainController -Server $dcComputerName).Enabled
        }
        ErrorAction  = [Management.Automation.ActionPreference]::SilentlyContinue
    }
    while ((Invoke-Command @params) -ne $true) {
        Start-Sleep -Seconds $CheckInternal
        'Waiting...' | WriteLog -Context $VMName
    }
}

$vmName = $configParams.addsDC.vmName

'Creating the OS disk for the VM...' | WriteLog -Context $vmName
$params = @{
    Differencing = $true
    ParentPath   = [IO.Path]::Combine($configParams.labHost.folderPath.vhd, ('{0}_{1}.vhdx' -f 'ws2022', $configParams.guestOS.culture))
    Path         = [IO.Path]::Combine($configParams.labHost.folderPath.vm, $vmName, 'osdisk.vhdx')
}
$vmOSDiskVhd = New-VHD  @params

'Creating the VM...' | WriteLog -Context $vmName
$params = @{
    Name       = $vmName
    Path       = $configParams.labHost.folderPath.vm
    VHDPath    = $vmOSDiskVhd.Path
    Generation = 2
}
New-VM @params

'Setting the VM''s processor configuration...' | WriteLog -Context $vmName
Set-VMProcessor -VMName $vmName -Count 2

'Setting the VM''s memory configuration...' | WriteLog -Context $vmName
$params = @{
    VMName               = $vmName
    StartupBytes         = 2GB
    DynamicMemoryEnabled = $true
    MinimumBytes         = 512MB
    MaximumBytes         = 2GB
}
Set-VMMemory @params

'Setting the VM''s network adapter configuration...' | WriteLog -Context $vmName
Get-VMNetworkAdapter -VMName $vmName | Remove-VMNetworkAdapter
$params = @{
    VMName       = $vmName
    Name         = $configParams.addsDC.netAdapter.management.name
    SwitchName   = $configParams.labHost.vSwitch.nat.name
    DeviceNaming = 'On'
}
Add-VMNetworkAdapter @params

'Generating the unattend answer XML...' | WriteLog -Context $vmName
$adminPassword = GetSecret -KeyVaultName $configParams.keyVault.name -SecretName $configParams.keyVault.secretName
$encodedAdminPassword = GetEncodedAdminPasswordForUnattendAnswerFile -Password $adminPassword
$unattendAnswerFileContent = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <servicing></servicing>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>{0}</Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <OOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>{1}</InputLocale>
            <SystemLocale>{1}</SystemLocale>
            <UILanguage>{1}</UILanguage>
            <UserLocale>{1}</UserLocale>
        </component>
        <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <fDenyTSConnections>false</fDenyTSConnections>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>{2}</ComputerName>
            <TimeZone>UTC</TimeZone>
        </component>
    </settings>
</unattend>
'@ -f $encodedAdminPassword, $configParams.guestOS.culture, $vmName

'Injecting the unattend answer file to the VM...' | WriteLog -Context $vmName
InjectUnattendAnswerFile -VhdPath $vmOSDiskVhd.Path -UnattendAnswerFileContent $unattendAnswerFileContent

'Installing the roles and features to the VHD...' | WriteLog -Context $vmName
$features = @(
    'AD-Domain-Services'
)
Install-WindowsFeature -Vhd $vmOSDiskVhd.Path -Name $features -IncludeManagementTools

'Starting the VM...' | WriteLog -Context $vmName
while ((Start-VM -Name $vmName -Passthru -ErrorAction SilentlyContinue) -eq $null) {
    'Will retry start the VM. Waiting for unmount the VHD...' | WriteLog -Context $vmName
    Start-Sleep -Seconds 5
}

'Waiting for ready to the VM...' | WriteLog -Context $vmName
$params = @{
    TypeName     = 'System.Management.Automation.PSCredential'
    ArgumentList = 'Administrator', $adminPassword
}
$localAdminCredential = New-Object @params
WaitingForReadyToVM -VMName $vmName -Credential $localAdminCredential

'Configuring the new VM...' | WriteLog -Context $vmName
$params = @{
    VMName       = $vmName
    Credential   = $localAdminCredential
    ArgumentList = ${function:WriteLog}, $vmName, $configParams, $adminPassword
}
Invoke-Command @params -ScriptBlock {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $WriteLog = [scriptblock]::Create($args[0])
    $vmName = $args[1]
    $configParams = $args[2]
    $adminPassword = $args[3]

    'Stop Server Manager launch at logon.' | &$WriteLog -Context $vmName
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' -Name 'DoNotOpenServerManagerAtLogon' -Value 1

    'Stop Windows Admin Center popup at Server Manager launch.' | &$WriteLog -Context $vmName
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' -Name 'DoNotPopWACConsoleAtSMLaunch' -Value 1

    'Stop Windows Admin Center popup at Server Manager launch.' | &$WriteLog -Context $vmName
    New-Item -ItemType Directory -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Network' -Name 'NewNetworkWindowOff'

    'Renaming the network adapters...' | &$WriteLog -Context $vmName
    Get-NetAdapterAdvancedProperty -RegistryKeyword 'HyperVNetworkAdapterName' | ForEach-Object -Process {
        Rename-NetAdapter -Name $_.Name -NewName $_.DisplayValue
    }

    'Setting the IP configuration on the network adapter...' | &$WriteLog -Context $vmName
    $params = @{
        AddressFamily  = 'IPv4'
        IPAddress      = $configParams.addsDC.netAdapter.management.ipAddress
        PrefixLength   = $configParams.addsDC.netAdapter.management.prefixLength
        DefaultGateway = $configParams.addsDC.netAdapter.management.defaultGateway
    }
    Get-NetAdapter -Name $configParams.addsDC.netAdapter.management.name | New-NetIPAddress @params
    
    'Setting the DNS configuration on the network adapter...' | &$WriteLog -Context $vmName
    Get-NetAdapter -Name $configParams.addsDC.netAdapter.management.name |
        Set-DnsClientServerAddress -ServerAddresses $configParams.addsDC.netAdapter.management.dnsServerAddresses

    'Installing AD DS (Creating a new forest)...' | &$WriteLog -Context $vmName
    $params = @{
        DomainName                    = $configParams.addsDC.domainFqdn
        InstallDns                    = $true
        SafeModeAdministratorPassword = $adminPassword
        NoRebootOnCompletion          = $true
        Force                         = $true
    }
    Install-ADDSForest @params
}

'Stopping the VM...' | WriteLog -Context $vmName
Stop-VM -Name $vmName

'Starting the VM...' | WriteLog -Context $vmName
Start-VM -Name $vmName

'Waiting for ready to the domain controller...' | WriteLog -Context $vmName
$domainAdminCredential = CreateDomainCredential -DomainFqdn $configParams.addsDC.domainFqdn -Password $adminPassword
WaitingForReadyToDC -VMName $vmName -Credential $domainAdminCredential

'The AD DS Domain Controller VM creation has been completed.' | WriteLog -Context $vmName

Stop-Transcript