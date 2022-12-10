Configuration hcisandbox {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential] $AdminCreds,

        [Parameter(Mandatory = $false)]
        [string] $Environment = 'AD Domain',

        [Parameter(Mandatory = $false)]
        [string] $DomainName = 'hci.local',

        [Parameter(Mandatory = $false)]
        [bool] $EnableDhcp = $false,

        [Parameter(Mandatory = $false)]
        [string] $CustomRdpPort = '3389',

        [Parameter(Mandatory = $false)]
        [bool] $ApplyUpdatesToSandboxHost = $false,

        [Parameter(Mandatory = $false)]
        [string] $VSwitchNameHost = 'InternalNAT',

        [Parameter(Mandatory = $false)]
        [string] $TargetDrive = 'V',

        [Parameter(Mandatory = $false)]
        [string] $SourceFolderPath = [IO.Path]::Combine($TargetDrive + ':\', 'Source'),

        [Parameter(Mandatory = $false)]
        [string] $UpdatesFolderPath = [IO.Path]::Combine($SourceFolderPath, 'Updates'),

        [Parameter(Mandatory = $false)]
        [string] $SsuFolderPath = [IO.Path]::Combine($UpdatesFolderPath, 'SSU'),

        [Parameter(Mandatory = $false)]
        [string] $CuFolderPath = [IO.Path]::Combine($UpdatesFolderPath, 'CU'),

        [Parameter(Mandatory = $false)]
        [string] $VMFolderPath = [IO.Path]::Combine($TargetDrive + ':\', 'VMs'),

        [Parameter(Mandatory = $false)]
        [string] $BaseVhdFolderPath = [IO.Path]::Combine($VMFolderPath, 'Base'),

        [Parameter(Mandatory = $false)]
        [string] $AddsFolderPath = [IO.Path]::Combine($TargetDrive + ':\', 'ADDS'),

        [Parameter(Mandatory = $false)]
        [string] $WacFolderPath = 'C:\WAC',  # This path is related to "install-wac.ps1".

        [Parameter(Mandatory = $false)]
        [string] $IsoFileUri = 'https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US',  # Windows Server 2022 Evaluation en-US

        [Parameter(Mandatory = $false)]
        [int] $WimImageIndex = 1,

        [Parameter(Mandatory = $false)]
        [string] $NestedVMBaseOsDiskPath = [IO.Path]::Combine($BaseVhdFolderPath, 'nested-vm-base-os-disk.vhdx'),

        [Parameter(Mandatory = $false)]
        [string] $LocalIsoFilePath = [IO.Path]::Combine($SourceFolderPath, 'nested-vm-os.iso'),

        [Parameter(Mandatory = $false)]
        [int] $NumOfNestedVMs = 2,

        [Parameter(Mandatory = $false)]
        [int] $NumOfNestedVMDataDisks = 4,

        [Parameter(Mandatory = $false)]
        [long] $NestedVMDataDiskSize = 250GB,

        [Parameter(Mandatory = $false)]
        [bool] $ApplyUpdatesToNestedVM = $false
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'NetworkingDSC'
    Import-DscResource -ModuleName 'xCredSSP'
    Import-DscResource -ModuleName 'xWindowsUpdate'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
    Import-DscResource -ModuleName 'DnsServerDsc'
    Import-DscResource -ModuleName 'xHyper-v'
    Import-DscResource -ModuleName 'cHyper-v'
    Import-DscResource -ModuleName 'xDHCpServer'
    Import-DscResource -ModuleName 'DSCR_Shortcut'

    $domainCreds = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList ('{0}\{1}' -f $DomainName, $AdminCreds.UserName), $AdminCreds.Password

    # Find a network adapter that has IPv4 default gateway.
    $interfaceAlias = (Get-NetAdapter -Physical -InterfaceDescription 'Microsoft Hyper-V Network Adapter*' | Get-NetIPConfiguration |
        Where-Object -Property 'IPv4DefaultGateway' | Sort-Object -Property 'InterfaceIndex' | Select-Object -First 1).InterfaceAlias

    Node 'localhost' {
        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration'
        }

        #### Enable custom RDP port ####

        if ($CustomRdpPort -ne '3389') {
            Registry 'Set custom RDP port' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
                ValueName = 'PortNumber'
                ValueData = $CustomRdpPort
                ValueType = 'Dword'
            }

            Firewall 'Create csutom RDP port firewall rule' {
                Ensure      = 'Present'
                Name        = 'RemoteDesktop-CustomPort-In-TCP'
                DisplayName = 'Remote Desktop with csutom port (TCP-In)'
                Profile     = 'Any'
                Direction   = 'Inbound'
                LocalPort   = $CustomRdpPort
                Protocol    = 'TCP'
                Description = 'Firewall Rule for Custom RDP Port'
                Enabled     = 'True'
            }
        }

        #### Apply Windows updates ####

        if ($ApplyUpdatesToSandboxHost) {
            xWindowsUpdateAgent 'Apply Windows updates' {
                IsSingleInstance = 'Yes'
                Source           = 'MicrosoftUpdate'
                Category         = 'Security', 'Important'
                UpdateNow        = $true
                Notifications    = 'Disabled'
            }
        }
        
        #### Install Windows roles and features ####

        $installFeatures = @(
            'DNS',
            'RSAT-DNS-Server',
            'Hyper-V',
            'RSAT-Hyper-V-Tools',
            'RSAT-Clustering',
            'DHCP',
            'RSAT-DHCP'
        )

        if ($environment -eq 'AD Domain') {
            $installFeatures += @(
                'AD-Domain-Services',
                'RSAT-ADDS-Tools',
                'RSAT-AD-AdminCenter'
            )
        }

        WindowsFeatureSet 'Install roles and features' {
            Ensure    = 'Present'
            Name      = $installFeatures
        }

        #### Create a data volume ####

        $storagePoolName = 'hcisandboxpool'
        $volumeLabel = 'hcisandbox-data'

        Script 'Create storage pool' {
            TestScript = {
                (Get-StoragePool -FriendlyName $using:storagePoolName -ErrorAction SilentlyContinue).OperationalStatus -eq 'OK'
            }
            SetScript = {
                New-StoragePool -FriendlyName $using:storagePoolName -StorageSubSystemFriendlyName '*storage*' -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
            }
        }

        Script 'Create data volume' {
            TestScript = {
                (Get-Volume -DriveLetter $using:TargetDrive -ErrorAction SilentlyContinue).OperationalStatus -eq 'OK'
            }
            SetScript = {
                New-Volume -StoragePoolFriendlyName $using:storagePoolName -FileSystem NTFS -AllocationUnitSize 64KB -ResiliencySettingName Simple -UseMaximumSize -DriveLetter $using:TargetDrive -FriendlyName $using:volumeLabel
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
            }
            DependsOn = '[Script]Create storage pool'
        }

        #### Create folder structure on the data volume ####

        File 'Create Source folder' {
            DestinationPath = $SourceFolderPath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = '[Script]Create data volume'
        }

        File 'Create Updates folder' {
            DestinationPath = $UpdatesFolderPath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = '[File]Create Source folder'
        }

        File 'Create SSU folder' {
            DestinationPath = $SsuFolderPath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = '[File]Create Updates folder'
        }

        File 'Create CU folder' {
            DestinationPath = $CuFolderPath
            Type            = 'Directory'
            Force           = $true
            DependsOn       = '[File]Create Updates folder'
        }

        File 'Create VM folder' {
            Type            = 'Directory'
            DestinationPath = $VMFolderPath
            DependsOn       = '[Script]Create data volume'
        }

        File 'Create Base VHD folder' {
            Type            = 'Directory'
            DestinationPath = $BaseVhdFolderPath
            DependsOn       = '[File]Create VM folder'
        }

        if ($environment -eq 'AD Domain') {
            File 'Create ADDS folder' {
                Type            = 'Directory'
                DestinationPath = $AddsFolderPath
                DependsOn       = '[Script]Create data volume'
            }
        }

        #### Set Windows Defender exclusions for VM storage ####

        $exclusionPath = $TargetDrive + ':\'

        Script 'Defender Exclusions' {
            TestScript = {
                (Get-MpPreference).ExclusionPath -contains $using:exclusionPath
            }
            SetScript = {
                Add-MpPreference -ExclusionPath $using:exclusionPath
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
            }
            DependsOn  = '[Script]Create data volume'
        }

        #### Tweak scheduled tasks and registry settings ####

        ScheduledTask 'Disable Server Manager at Startup' {
            TaskPath = '\Microsoft\Windows\Server Manager'
            TaskName = 'ServerManager'
            Enable   = $false
        }

        Registry 'Disable Server Manager WAC Prompt' {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Microsoft\ServerManager'
            ValueName = 'DoNotPopWACConsoleAtSMLaunch'
            ValueType = 'Dword'
            ValueData = '1'
        }

        Registry 'DHCP config complete' {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12'
            ValueName = 'ConfigurationState'
            ValueType = 'Dword'
            ValueData = '2'
            DependsOn = '[WindowsFeatureSet]Install roles and features'
        }

        Registry 'Disable Internet Explorer ESC for Admin' {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
            ValueName = 'IsInstalled'
            ValueType = 'Dword'
            ValueData = '0'
        }

        Registry 'Disable Internet Explorer ESC for User' {
            Ensure    = 'Present'
            Key       = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
            ValueName = 'IsInstalled'
            ValueType = 'Dword'
            ValueData = '0'
        }

        Registry 'Disable Network Profile Prompt' {
            Ensure    = 'Present'
            Key       = 'HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff'
            ValueName = ''
        }

        if ($environment -eq 'Workgroup') {
            Registry 'Set Network Private Profile Default' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\010103000F0000F0010000000F0000F0C967A3643C3AD745950DA7859209176EF5B87C875FA20DF21951640E807D7C24'
                ValueName = 'Category'
                ValueType = 'Dword'
                ValueData = '1'
            }

            Registry 'SetWorkgroupDomain' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
                ValueName = 'Domain'
                ValueType = 'String'
                ValueData = $DomainName
            }

            Registry 'SetWorkgroupNVDomain' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
                ValueName = 'NV Domain'
                ValueType = 'String'
                ValueData = $DomainName
            }

            Registry 'NewCredSSPKey' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly'
                ValueName = ''
            }

            Registry 'NewCredSSPKey2' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
                ValueName = 'AllowFreshCredentialsWhenNTLMOnly'
                ValueType = 'Dword'
                ValueData = '1'
                DependsOn = '[Registry]NewCredSSPKey'
            }

            Registry 'NewCredSSPKey3' {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly'
                ValueName = '1'
                ValueType = 'String'
                ValueData = '*.{0}' -f $DomainName
                DependsOn = '[Registry]NewCredSSPKey2'
            }
        }

        #### DNS server related settings ####

        Script 'Enable DNS diags' {
            TestScript = {
                $false  # Applies every time.
            }
            SetScript = {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose 'Enabling DNS client diagnostics.'
            }
            GetScript = {
                @{ Result = 'Applies every time' }
            }
            DependsOn = '[WindowsFeatureSet]Install roles and features'
        }

        DnsServerAddress "DnsServerAddress for $interfaceAlias" {
            Address        = '127.0.0.1'
            InterfaceAlias = $interfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn      = '[WindowsFeatureSet]Install roles and features'
        }

        #### Create a first domain controller ####

        if ($environment -eq 'AD Domain') {
            ADDomain 'Create first DC' {
                DomainName                    = $DomainName
                Credential                    = $domainCreds
                SafemodeAdministratorPassword = $domainCreds
                DatabasePath                  = [IO.Path]::Combine($AddsFolderPath, 'NTDS')
                LogPath                       = [IO.Path]::Combine($AddsFolderPath, 'NTDS')
                SysvolPath                    = [IO.Path]::Combine($AddsFolderPath, 'SYSVOL')
                DependsOn                     = @(
                    '[File]Create ADDS folder',
                    '[WindowsFeatureSet]Install roles and features'
                )
            }

            WaitForADDomain 'Wait for first boot completion of DC' {
                DomainName              = $DomainName
                Credential              = $domainCreds
                WaitTimeout             = 300
                RestartCount            = 3
                WaitForValidCredentials = $true
                DependsOn               = '[ADDomain]Create first DC'
            }
        }

        #### Configure host network interface ####

        NetAdapterBinding 'Disable IPv6 on host network interface' {
            InterfaceAlias = $interfaceAlias
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
        }

        if ($environment -eq 'Workgroup') {
            NetConnectionProfile 'Set network connection profile' {
                InterfaceAlias  = $interfaceAlias
                NetworkCategory = 'Private'
            }
        }

        #### Hyper-V configuration ####

        xVMHost 'Hyper-V Host'
        {
            IsSingleInstance          = 'yes'
            EnableEnhancedSessionMode = $true
            VirtualHardDiskPath       = $VMFolderPath
            VirtualMachinePath        = $VMFolderPath
            DependsOn                 = '[WindowsFeatureSet]Install roles and features'
        }

        #### vSwitch configuration ####

        xVMSwitch 'Create NAT vSwitch'
        {
            Name      = $VSwitchNameHost
            Type      = 'Internal'
            DependsOn = '[WindowsFeatureSet]Install roles and features'
        }

        #### Configure interna NAT network interface ####

        $natInterfaceName = 'vEthernet ({0})' -f $VSwitchNameHost

        IPAddress 'Assign IP address for NAT network interface'
        {
            InterfaceAlias = $natInterfaceName
            AddressFamily  = 'IPv4'
            IPAddress      = '192.168.0.1/16'
            DependsOn      = '[xVMSwitch]Create NAT vSwitch'
        }

        NetIPInterface 'Enable IP forwarding on NAT network interface'
        {
            AddressFamily  = 'IPv4'
            InterfaceAlias = $natInterfaceName
            Forwarding     = 'Enabled'
            DependsOn      = '[IPAddress]Assign IP address for NAT network interface'
        }

        NetAdapterRdma 'Enable RDMA on NAT network interface'
        {
            Name      = $natInterfaceName
            Enabled   = $true
            DependsOn = '[NetIPInterface]Enable IP forwarding on NAT network interface'
        }

        DnsServerAddress 'Set DNS server address for NAT network interface'
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $natInterfaceName
            AddressFamily  = 'IPv4'
            DependsOn      = '[IPAddress]Assign IP address for NAT network interface'
        }

        #### Configure network NAT ####

        $netNatName = 'lab-nat'

        Script 'Create network NAT' {
            TestScript = {
                if (Get-NetNat -Name $using:netNatName -ErrorAction SilentlyContinue) { $true } else { $false }
            }
            SetScript = {
                New-NetNat -Name $using:netNatName -InternalIPInterfaceAddressPrefix '192.168.0.0/16'
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
            }
            DependsOn = '[IPAddress]Assign IP address for NAT network interface'
        }

        NetAdapterBinding 'Disable IPv6 on NAT network interface' {
            InterfaceAlias = $natInterfaceName
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
            DependsOn      = '[Script]Create network NAT'
        }

        #### Configure DHCP server ####

        xDhcpServerScope 'Create DHCP scope' {
            Ensure        = 'Present'
            IPStartRange  = '192.168.0.10'
            IPEndRange    = '192.168.0.149'
            ScopeId       = '192.168.0.0'
            Name          = 'Lab Range'
            SubnetMask    = '255.255.0.0'
            LeaseDuration = '01.00:00:00'
            State         = if ($EnableDhcp) { 'Active' } else { 'Inactive' }
            AddressFamily = 'IPv4'
            DependsOn     = @(
                '[WindowsFeatureSet]Install roles and features',
                '[IPAddress]Assign IP address for NAT network interface'
            )
        }

        DhcpScopeOptionValue 'Set DHCP scope option - Router' {
            Ensure        = 'Present'
            AddressFamily = 'IPv4'
            ScopeId       = '192.168.0.0'
            OptionId      = 3  # Router
            Value         = '192.168.0.1'
            VendorClass   = ''
            UserClass     = ''
            DependsOn     = '[xDhcpServerScope]Create DHCP scope'
        }

        DhcpScopeOptionValue 'Set DHCP scope option - DNS Servers' {
            Ensure        = 'Present'
            AddressFamily = 'IPv4'
            ScopeId       = '192.168.0.0'
            OptionId      = 6  # DNS Servers
            Value         = '192.168.0.1'
            VendorClass   = ''
            UserClass     = ''
            DependsOn     = '[xDhcpServerScope]Create DHCP scope'
        }

        DhcpScopeOptionValue 'Set DHCP scope option - DNS Domain Name' {
            Ensure        = 'Present'
            AddressFamily = 'IPv4'
            ScopeId       = '192.168.0.0'
            OptionId      = 15  # DNS Domain Name
            Value         = $DomainName
            VendorClass   = ''
            UserClass     = ''
            DependsOn     = '[xDhcpServerScope]Create DHCP scope'
        }

        if ($environment -eq 'AD Domain') {
            DnsServerPrimaryZone 'Set reverse lookup zone' {
                Ensure    = 'Present'
                Name      = '0.168.192.in-addr.arpa'
                ZoneFile  = '0.168.192.in-addr.arpa.dns'
                DependsOn = @(
                    '[WindowsFeatureSet]Install roles and features',
                    '[WaitForADDomain]Wait for first boot completion of DC'
                )
            }

            xDhcpServerAuthorization 'Authorize DHCP server' {
                IsSingleInstance = 'Yes'
                Ensure           = 'Present'
                DnsName          = [System.Net.Dns]::GetHostByName($env:computerName).hostname
                IPAddress        = '192.168.0.1'
                DependsOn        = @(
                    '[WindowsFeatureSet]Install roles and features',
                    '[DnsServerPrimaryZone]Set reverse lookup zone'
                )
            }
        }
        elseif ($environment -eq 'Workgroup') {
            DnsServerPrimaryZone 'Set primary DNS zone' {
                Ensure        = 'Present'
                Name          = $DomainName
                ZoneFile      = $DomainName + '.dns'
                DynamicUpdate = 'NonSecureAndSecure'
                DependsOn     = '[Script]Create network NAT'
            }

            DnsServerPrimaryZone 'Set reverse lookup zone' {
                Ensure        = 'Present'
                Name          = '0.168.192.in-addr.arpa'
                ZoneFile      = '0.168.192.in-addr.arpa.dns'
                DynamicUpdate = 'NonSecureAndSecure'
                DependsOn     = '[DnsServerPrimaryZone]Set primary DNS zone'
            }
        }

        Script 'Set DHCP DNS Setting' {
            TestScript = {
                $false  # Applies every time.
            }
            SetScript = {
                Set-DhcpServerv4DnsSetting -DynamicUpdates Always -DeleteDnsRRonLeaseExpiry $true -UpdateDnsRRForOlderClients $true -DisableDnsPtrRRUpdate $false
            }
            GetScript = {
                @{ Result = 'Applies every time' }
            }
            DependsOn = @(
                '[DhcpScopeOptionValue]Set DHCP scope option - Router',
                '[DhcpScopeOptionValue]Set DHCP scope option - DNS Servers',
                '[DhcpScopeOptionValue]Set DHCP scope option - DNS Domain Name'
            )
        }

        if ($environment -eq 'Workgroup') {
            DnsConnectionSuffix 'Add specific suffix to host network interface' {
                InterfaceAlias           = $interfaceAlias
                ConnectionSpecificSuffix = $DomainName
                DependsOn                = '[DnsServerPrimaryZone]Set primary DNS zone'
            }

            DnsConnectionSuffix 'Add specific suffix to NAT network interface' {
                InterfaceAlias           = $natInterfaceName
                ConnectionSpecificSuffix = $DomainName
                DependsOn                = '[DnsServerPrimaryZone]Set primary DNS zone'
            }

            #### Configure CredSSP ####

            xCredSSP 'Set CredSSD Server settings' {
                Ensure         = 'Present'
                Role           = 'Server'
                SuppressReboot = $true
                DependsOn      = '[DnsConnectionSuffix]Add specific suffix to NAT network interface'
            }

            xCredSSP 'Set CredSSD Client settings' {
                Ensure            = 'Present'
                Role              = 'Client'
                DelegateComputers = '{0}.{1}' -f $env:ComputerName, $DomainName
                SuppressReboot    = $true
                DependsOn         = '[xCredSSP]Set CredSSD Server settings'
            }

            #### Configure WinRM ####

            $expectedTrustedHost = '*.{0}' -f $DomainName

            Script 'Configure WinRM' {
                TestScript = {
                    (Get-Item -LiteralPath 'WSMan:\localhost\Client\TrustedHosts').Value -contains $using:expectedTrustedHost
                }
                SetScript = {
                    Set-Item -LiteralPath 'WSMan:\localhost\Client\TrustedHosts' -Value $using:expectedTrustedHost -Force
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
                }
                DependsOn = '[xCredSSP]Set CredSSD Client settings'
            }
        }

        #### Download asset files for nested VM creation ####

        Script 'Download ISO file' {
            TestScript = {
                Test-Path -Path $using:LocalIsoFilePath
            }
            SetScript = {
                Start-BitsTransfer -Source $using:IsoFileUri -Destination $using:LocalIsoFilePath
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
            }
            DependsOn = '[File]Create Source folder'
        }

        if ($ApplyUpdatesToNestedVM) {
            # TODO: Not yet released SSU for WS2022.
            # https://msrc.microsoft.com/update-guide/vulnerability/ADV990001
            <#
            Script 'Download Servicing Stack Update' {
                TestScript = {
                    Test-Path -Path (Join-Path -Path $using:SsuFolderPath -ChildPath '*') -Include '*.msu'
                }
                SetScript = {
                    $ssuSearchString = 'Servicing Stack Update for Azure Stack HCI, version ' + $using:AzSHciVersion + ' for x64-based Systems'
                    $product = 'Azure Stack HCI'
                    $ssuUpdate = Get-MSCatalogUpdate -Search $ssuSearchString -SortBy LastUpdated -Descending |
                        Where-Object -Property 'Products' -eq $product |
                        Select-Object -First 1
                    $ssuUpdate | Save-MSCatalogUpdate -Destination $using:SsuFolderPath
                }
                GetScript = {
                    $result = [scriptblock]::Create($TestScript).Invoke()
                    @{
                        'Result' = if ($result) {
                            'The Servicing Stack Update has been downloaded to "{0}".' -f $using:SsuFolderPath
                        }
                        else {
                            'The Servicing Stack Update has not been downloaded.'
                        }
                    }
                }
                DependsOn = '[File]Create SSU folder'
            }
            #>

            Script 'Download Cumulative Update' {
                TestScript = {
                    Test-Path -Path (Join-Path -Path $using:CuFolderPath -ChildPath '*') -Include '*.msu'
                }
                SetScript = {
                    # For Azure Stack HCI 20H2
                    #$cuSearchString = 'Cumulative Update for Azure Stack HCI, version 20H2 for x64-based Systems'
                    #$product = 'Azure Stack HCI'

                    # For Windows Server 2022
                    $cuSearchString = 'Cumulative Update Microsoft server operating system version 21H2 for x64-based Systems'
                    $product = 'Microsoft Server operating system-21H2'

                    $cuUpdate = Get-MSCatalogUpdate -Search $cuSearchString -SortBy LastUpdated -Descending |
                        Where-Object -Property 'Title' -NotLike '*Preview*' |
                        Where-Object -Property 'Products' -eq $product |
                        Select-Object -First 1
                    Save-MSCatalogUpdate -Update $cuUpdate[0] -Destination $using:CuFolderPath
                }
                GetScript = {
                    $result = [scriptblock]::Create($TestScript).Invoke()
                    @{
                        'Result' = if ($result) {
                            'The Cumulative Update has been downloaded to "{0}".' -f $using:CuFolderPath
                        }
                        else {
                            'The Cumulative Update has not been downloaded.'
                        }
                    }
                }
                DependsOn = '[File]Create CU folder'
            }
        }

        #### Create nested VMs ####

        Script 'Create OS base VHDX file' {
            TestScript = {
                Test-Path -Path $using:NestedVMBaseOsDiskPath -PathType Leaf
            }
            SetScript = {
                # Create netsted VM image from ISO.
                $params = @{
                    SourcePath        = $using:LocalIsoFilePath
                    Edition           = $using:WimImageIndex
                    VHDPath           = $using:NestedVMBaseOsDiskPath
                    VHDFormat         = 'VHDX'
                    VHDType           = 'Dynamic'
                    VHDPartitionStyle = 'GPT'
                    SizeBytes         = 100GB
                    TempDirectory     = $using:VMFolderPath
                    Verbose           = $true
                }
                [string[]] $packageFolders = @()
                if (Test-Path -Path ([IO.Path]::Combine($using:SsuFolderPath, '*')) -Include '*.msu') { $packageFolders += $using:SsuFolderPath }
                if (Test-Path -Path ([IO.Path]::Combine($using:CuFolderPath, '*')) -Include '*.msu') { $packageFolders += $using:CuFolderPath }
                if ($packageFolders.Length -gt 0) { $params.Package = $packageFolders }
                Convert-WindowsImage @params

                # Need to wait for disk to fully unmount.
                while ((Get-Disk).Count -gt 2) { Start-Sleep -Seconds 5 }

                # Apply update packages to the VHDX.
                $updatePackageFilePaths = Get-ChildItem -Path $using:CuPath -Recurse |
                    Where-Object -FilterScript { ($_.Extension -eq '.msu') -or ($_.Extension -eq '.cab') } |
                    Select-Object -Property 'FullName'

                if ($updatePackageFilePaths) {
                    $mountResult = Mount-DiskImage -ImagePath $using:NestedVMBaseOsDiskPath -StorageType VHDX -Access ReadWrite -ErrorAction Stop
                    $vhdxWinPartition = Get-Partition -DiskNumber $mountResult.Number | Where-Object -Property 'Type' -EQ -Value 'Basic' | Select-Object -First 1
                    $updatePackageFilePaths | ForEach-Object -Process {
                        Write-Debug -Message $_.FullName
                        $command = 'dism.exe /Image:"{0}:\" /Add-Package /PackagePath:"{1}"' -f $vhdxWinPartition.DriveLetter, $_.FullName
                        Write-Debug -Message $command
                        Invoke-Expression -Command $command
                    }
                    Dismount-DiskImage -ImagePath $mountResult.ImagePath
                }

                # Enable Hyper-V role on the nested VM VHD.
                Install-WindowsFeature -Name 'Hyper-V' -Vhd $using:NestedVMBaseOsDiskPath
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
            }
            DependsOn = &{
                $dependencies = @(
                    '[File]Create Base VHD folder',
                    '[Script]Download ISO file'
                )
                if ($ApplyUpdatesToNestedVM) {
                    $dependencies += @(
                        #'[Script]Download Servicing Stack Update',
                        '[Script]Download Cumulative Update'
                    )
                }
                $dependencies
            }
        }

        $nestedVMNamePrefix = 'hcinode'

        1..$NumOfNestedVMs | ForEach-Object -Process {
            $nestedVMIndex = $_
            $nestedVMName = '{0}{1:D2}' -f $nestedVMNamePrefix, $nestedVMIndex
            $nestedVMStoreFolderPath = [IO.Path]::Combine($VMFolderPath, $nestedVMName)

            File "Create VM store folder for $nestedVMName" {
                Ensure          = 'Present'
                DestinationPath = $nestedVMStoreFolderPath
                Type            = 'Directory'
                DependsOn       = '[File]Create VM folder'
            }

            $osDiskFileName = '{0}-osdisk.vhdx' -f $nestedVMName
            $osDiskFilePath = [IO.Path]::Combine($nestedVMStoreFolderPath, $osDiskFileName)

            xVHD "Create OS disk for $nestedVMName" {
                Ensure     = 'Present'
                Name       = $osDiskFileName
                Path       = $nestedVMStoreFolderPath
                Generation = 'vhdx'
                Type       = 'Differencing'
                ParentPath = $NestedVMBaseOsDiskPath
                DependsOn  = @(
                    '[xVMSwitch]Create NAT vSwitch',
                    '[Script]Create OS base VHDX file',
                    "[File]Create VM store folder for $nestedVMName"
                )
            }

            xVMHyperV "Create VM $nestedVMName" {
                Ensure         = 'Present'
                Name           = $nestedVMName
                Path           = $VMFolderPath
                Generation     = 2
                ProcessorCount = 8
                StartupMemory  = 24GB
                VhdPath        = $osDiskFilePath
                DependsOn      = "[xVHD]Create OS disk for $nestedVMName"
            }

            xVMProcessor "Enable nested virtualization on $nestedVMName" {
                VMName                         = $nestedVMName
                ExposeVirtualizationExtensions = $true
                DependsOn                      = "[xVMHyperV]Create VM $nestedVMName"
            }

            # Add data disks.
            1..$NumOfNestedVMDataDisks | ForEach-Object -Process {
                $dataDiskIndex = $_
                $dataDiskFileName = '{0}-datadisk{1}.vhdx' -f $nestedVMName, $dataDiskIndex

                xVHD "Create data disk $dataDiskFileName" {
                    Ensure           = 'Present'
                    Name             = $dataDiskFileName
                    Path             = $nestedVMStoreFolderPath
                    Generation       = 'vhdx'
                    Type             = 'Dynamic'
                    MaximumSizeBytes = $NestedVMDataDiskSize
                    DependsOn        = "[xVMHyperV]Create VM $nestedVMName"
                }

                xVMHardDiskDrive "Add data disk $dataDiskFileName to $nestedVMName" {
                    Ensure             = 'Present'
                    VMName             = $nestedVMName
                    ControllerType     = 'SCSI'
                    ControllerLocation = $dataDiskIndex
                    Path               = [IO.Path]::Combine($nestedVMStoreFolderPath, $dataDiskFileName)
                    DependsOn          = "[xVMHyperV]Create VM $nestedVMName"
                }
            }

            Script "Remove default network adapter on $nestedVMName" {
                TestScript = {
                    if (Get-VMNetworkAdapter -VMName $using:nestedVMName -Name 'Network Adapter' -ErrorAction SilentlyContinue) { $false } else { $true }
                }
                SetScript = {
                    $networkAdapter = Get-VMNetworkAdapter -VMName $using:nestedVMName -Name 'Network Adapter'
                    Remove-VMNetworkAdapter -VMName $networkAdapter.VMName -Name $networkAdapter.Name
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Removed as expected' } else { 'Exists against expectation' } }
                }
                DependsOn = "[xVMHyperV]Create VM $nestedVMName"
            }

            # Add management network adapters.
            1 | ForEach-Object -Process {
                $mgmtNetAdapterIndex = $_
                $mgmtNetAdapterName = '{0}-Management{1}' -f $nestedVMName, $mgmtNetAdapterIndex

                xVMNetworkAdapter "Add network adapter $mgmtNetAdapterName to $nestedVMName" {
                    Ensure         = 'Present'
                    VMName         = $nestedVMName
                    SwitchName     = $VSwitchNameHost
                    Id             = $mgmtNetAdapterName
                    Name           = $mgmtNetAdapterName
                    NetworkSetting = xNetworkSettings {
                        IpAddress      = '192.168.0.{0}' -f ($nestedVMIndex + 1)
                        Subnet         = '255.255.0.0'
                        DefaultGateway = '192.168.0.1'
                        DnsServer      = '192.168.0.1'
                    }
                    DependsOn      = "[xVMHyperV]Create VM $nestedVMName"
                }

                cVMNetworkAdapterSettings "Enable MAC address spoofing and Teaming on $mgmtNetAdapterName of $nestedVMName" {
                    VMName             = $nestedVMName
                    SwitchName         = $VSwitchNameHost
                    Id                 = $mgmtNetAdapterName
                    Name               = $mgmtNetAdapterName
                    AllowTeaming       = 'on'
                    MacAddressSpoofing = 'on'
                    DependsOn          = "[xVMNetworkAdapter]Add network adapter $mgmtNetAdapterName to $nestedVMName"
                }
            }

            # Add converged network adapters.
            1..3 | ForEach-Object -Process {
                $convergedNetAdapterIndex = $_
                $convergedNetAdapterName = '{0}-Converged{1}' -f $nestedVMName, $convergedNetAdapterIndex

                xVMNetworkAdapter "Add network adapter $convergedNetAdapterName to $nestedVMName" {
                    Ensure         = 'Present'
                    VMName         = $nestedVMName
                    SwitchName     = $VSwitchNameHost
                    Id             = $convergedNetAdapterName
                    Name           = $convergedNetAdapterName
                    NetworkSetting = xNetworkSettings {
                        IpAddress = '10.10.1{0}.{1}' -f $convergedNetAdapterIndex, $nestedVMIndex
                        Subnet    = "255.255.255.0"
                    }
                    DependsOn      = "[xVMHyperV]Create VM $nestedVMName"
                }

                cVMNetworkAdapterSettings "Enable MAC address spoofing and Teaming on $convergedNetAdapterName of $nestedVMName" {
                    VMName             = $nestedVMName
                    SwitchName         = $VSwitchNameHost
                    Id                 = $convergedNetAdapterName
                    Name               = $convergedNetAdapterName
                    AllowTeaming       = 'on'
                    MacAddressSpoofing = 'on'
                    DependsOn          = "[xVMNetworkAdapter]Add network adapter $convergedNetAdapterName to $nestedVMName"
                }
            }

            # unattend.xml for nested VM.
            $unattendXmlFilePath = [IO.Path]::Combine($nestedVMStoreFolderPath, 'unattend.xml')

            Script "Inject unattend files to $nestedVMName" {
                TestScript = {
                    Test-Path -Path $using:unattendXmlFilePath -PathType Leaf
                }
                SetScript = {
                    # Mount the nested VM's VHDX.
                    $mountResult = Mount-DiskImage -ImagePath $using:osDiskFilePath -StorageType VHDX -Access ReadWrite -ErrorAction Stop
                    $vmWinPartition = Get-Partition -DiskNumber $mountResult.Number | Where-Object -Property 'Type' -EQ -Value 'Basic' | Select-Object -First 1

                    # Create a temp folder in the root of the mounted VHDX.
                    $tempFolderPath = [IO.Path]::Combine($vmWinPartition.DriveLetter + ':\', 'Temp')
                    New-Item -Path $tempFolderPath -ItemType Directory -Force -ErrorAction Stop

                    # Copy a DSC configuration script for nested VMs from the Azure PowerShell DSC extension working folder to the temp folder in the mounted VHDX.
                    $nestedVMDscScriptFilePath = (Get-ChildItem -Path 'C:\Packages\Plugins\Microsoft.Powershell.DSC\*' -Recurse -Filter 'dsc-config-for-nested-vm.ps1' |
                        Sort-Object -Property 'LastWriteTimeUtc' -Descending | Select-Object -First 1).FullName
                    Copy-Item -Path $nestedVMDscScriptFilePath -Destination $tempFolderPath -Force -ErrorAction Stop

                    # Create an unattend.xml in the VM's folder.
                    $params = @{
                        ComputerName               = $using:nestedVMName
                        LocalAdministratorPassword = $using:AdminCreds.Password
                        Domain                     = $using:DomainName
                        Username                   = $using:AdminCreds.UserName
                        Password                   = $using:AdminCreds.Password
                        JoinDomain                 = $using:DomainName
                        AutoLogonCount             = 1
                        PowerShellScriptFullPath   = 'C:\Temp\dsc-config-for-nested-vm.ps1'  # This path is the path of the DSC configuration script that recognized from within the VM.
                        OutputPath                 = $using:nestedVMStoreFolderPath
                        ErrorAction                = 'Stop'
                        Force                      = $true
                    }
                    New-BasicUnattendXML @params

                    # Copy the unattend.xml into the sysprep folder within the VHDX.
                    Copy-Item -Path $using:unattendXmlFilePath -Destination ([IO.Path]::Combine($vmWinPartition.DriveLetter + ':\', 'Windows\System32\Sysprep')) -Force -ErrorAction Stop

                    # Unmount the nested VM's VHDX.
                    Dismount-DiskImage -ImagePath $mountResult.ImagePath
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
                }
                DependsOn = @(
                    "[xVHD]Create OS disk for $nestedVMName"
                )
            }

            Script "Start VM $nestedVMName" {
                TestScript = {
                    (Get-VM -Name $using:nestedVMName -ErrorAction SilentlyContinue).State -eq 'Running'
                }
                SetScript = {
                    Start-VM -Name $using:nestedVMName -Verbose
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Running' } else { 'Not running' } }
                }
                DependsOn = @(
                    "[Script]Inject unattend files to $nestedVMName"
                )
            }
        }

        #### Update AD with cluster info ####

        if ($environment -eq 'AD Domain') {
            $wacComputerName = $env:ComputerName

            Script 'Create computer object for WAC' {
                TestScript = {
                    # NOTE: The WAC computer account is also the domain controller, so it is usually present.
                    $wac = Get-ADComputer -Filter ('Name -eq "{0}"' -f $using:wacComputerName)
                    if ($wac) { $true } else { $false }
                }
                SetScript = {
                    New-ADComputer -Name $using:wacComputerName -Enabled $false
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
                }
                DependsOn = '[WaitForADDomain]Wait for first boot completion of DC'
            }

            $clusterOuName = 'HciClusters'

            Script 'Create OU for cluster' {
                TestScript = {
                    $ou = Get-ADOrganizationalUnit -Filter ('Name -eq "{0}"' -f $using:clusterOuName)
                    if ($ou) { $true } else { $false }
                }
                SetScript = {
                    New-ADOrganizationalUnit -Name $using:clusterOuName
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
                }
                DependsOn = '[WaitForADDomain]Wait for first boot completion of DC'
            }

            Script 'Create computer object for cluster nodes' {
                TestScript = {
                    $nodeVMs = Get-VM -Name ('{0}*' -f $using:nestedVMNamePrefix)
                    foreach ($nodeVM in $nodeVMs) {
                        $node = Get-ADComputer -Filter ('Name -eq "{0}"' -f $nodeVM.Name)
                        if (-not ($node)) {
                            return $false  # The node object does not exist.
                        }

                        $ou = Get-ADOrganizationalUnit -Filter ('Name -eq "{0}"' -f $using:clusterOuName)
                        if (-not ($node.DistinguishedName.Contains($ou.DistinguishedName))) {
                            return $false  # The node object does not reside in the cluster OU.
                        }
                    }

                    $true  # The node object is in the expected state.
                }
                SetScript = {
                    $ou = Get-ADOrganizationalUnit -Filter ('Name -eq "{0}"' -f $using:clusterOuName)
                    $wac = Get-ADComputer -Filter ('Name -eq "{0}"' -f $using:wacComputerName)

                    $nodeVMs = Get-VM -Name ('{0}*' -f $using:nestedVMNamePrefix)
                    foreach ($nodeVM in $nodeVMs) {
                        $node = Get-ADComputer -Filter ('Name -eq "{0}"' -f $nodeVM.Name)
                        if ($node) {
                            # Set Kerberos constrained delegation to the node object.
                            $node | Set-ADComputer -PrincipalsAllowedToDelegateToAccount $wac

                            # Move node object to the cluster OU if it's not residence in the cluster OU.
                            if (-not ($node.DistinguishedName.Contains($ou.DistinguishedName))) {
                                $node | Move-AdObject -TargetPath $ou.DistinguishedName
                            }
                        }
                        else {
                            New-ADComputer -Name $nodeVM.Name -Path $ou.DistinguishedName -Enabled $false -PrincipalsAllowedToDelegateToAccount $wac
                        }
                    }
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
                }
                DependsOn = @(
                    '[Script]Create computer object for WAC',
                    '[Script]Create OU for cluster'
                )
            }

            $clusterName = 'hciclus'

            Script 'Create computer object for CNO' {
                TestScript = {
                    $cno = Get-ADComputer -Filter ('Name -eq "{0}"' -f $using:clusterName)
                    if (-not ($cno)) {
                        return $false  # The CNO does not exist.
                    }

                    $ou = Get-ADOrganizationalUnit -Filter ('Name -eq "{0}"' -f $using:clusterOuName)
                    if (-not ($cno.DistinguishedName.Contains($ou.DistinguishedName))) {
                        return $false  # The CNO does not reside in the cluster OU.
                    }

                    $true  # The CNO is in the expected state.
                }
                SetScript = {
                    $ou = Get-ADOrganizationalUnit -Filter ('Name -eq "{0}"' -f $using:clusterOuName)
                    $wac = Get-ADComputer -Filter ('Name -eq "{0}"' -f $using:wacComputerName)

                    $cno = Get-ADComputer -Filter ('Name -eq "{0}"' -f $using:clusterName)
                    if ($cno) {
                        # Set Kerberos constrained delegation to the CNO.
                        $cno | Set-ADComputer -PrincipalsAllowedToDelegateToAccount $wac

                        # Move CNO to the cluster OU if it's not residence in the cluster OU.
                        if (-not ($cno.DistinguishedName.Contains($ou.DistinguishedName))) {
                            $cno | Move-AdObject -TargetPath $ou.DistinguishedName
                        }
                    }
                    else {
                        New-ADComputer -Name $using:clusterName -Path $ou.DistinguishedName -Enabled $false -PrincipalsAllowedToDelegateToAccount $wac
                    }
                }
                GetScript = {
                    @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Present' } else { 'Absent' } }
                }
                DependsOn = @(
                    '[Script]Create computer object for WAC',
                    '[Script]Create OU for cluster'
                )
            }

            Script 'Change cluster OU DACL' {
                TestScript = {
                    $false  # Applies every time.
                }
                SetScript = {
                    $ou = Get-ADOrganizationalUnit -Filter ('Name -eq "{0}"' -f $using:clusterOuName)
                    $acl = Get-Acl -Path ('AD:\{0}' -f $ou.DistinguishedName)

                    # Set properties to allow the cluster CNO to Full Control on the cluster OU.
                    $cno = Get-ADComputer -Filter ('Name -eq "{0}"' -f $using:clusterName)
                    $principal = New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList $cno.SID
                    $ace = New-Object -TypeName 'System.DirectoryServices.ActiveDirectoryAccessRule' -ArgumentList @(
                        $principal,
                        [System.DirectoryServices.ActiveDirectoryRights]::GenericAll,
                        [System.Security.AccessControl.AccessControlType]::Allow,
                        [DirectoryServices.ActiveDirectorySecurityInheritance]::All
                    )

                    $acl.AddAccessRule($ace)
                    Set-ACL -Path ('AD:\{0}' -f $ou.DistinguishedName) -AclObject $acl
                }
                GetScript = {
                    @{ Result = 'Applies every time' }
                }
                DependsOn = @(
                    '[Script]Create OU for cluster',
                    '[Script]Create computer object for CNO'
                )
            }
        }

        #### Update WAC extensions ####

        $wacPSModulePath = [IO.Path]::Combine($env:ProgramFiles, 'Windows Admin Center\PowerShell\Modules\ExtensionTools\ExtensionTools.psm1')
        [Uri] $gatewayEndpointUri = ('https://{0}' -f $env:ComputerName)

        Script 'Update WAC extensions' {
            TestScript = {
                Import-Module -Name $using:wacPSModulePath -Force
                $numOfNonUpToDateExtensions = (Get-Extension -GatewayEndpoint $using:gatewayEndpointUri |
                    Where-Object -Property 'isLatestVersion' -EQ $false | Measure-Object).Count
                $numOfNonUpToDateExtensions -le 0
            }
            SetScript = {
                # Create a log file for WAC extension update.
                New-Item -Path $using:WacFolderPath -ItemType Directory -Force
                $wacExtensionUpdateLogFilePath = [IO.Path]::Combine($using:WacFolderPath, ('wac-extension-update-{0}.log' -f (Get-Date -Format 'yyyyMMddhhmmss')))
                New-Item -Path $wacExtensionUpdateLogFilePath -ItemType File -Force
                Write-Verbose -Message ('WAC extension update log: "{0}"' -f $wacExtensionUpdateLogFilePath)

                # Update each non-up-to-date WAC extension.
                Import-Module -Name $using:wacPSModulePath -Force
                Get-Extension -GatewayEndpoint $using:gatewayEndpointUri |
                    Where-Object -Property 'isLatestVersion' -EQ $false |
                    ForEach-Object -Process {
                        $wacExtension = $_
                        Update-Extension -GatewayEndpoint $using:gatewayEndpointUri -ExtensionId $wacExtension.id -Verbose |
                            Out-File -LiteralPath $wacExtensionUpdateLogFilePath -Append -Encoding utf8 -Force
                    }
            }
            GetScript = {
                @{ Result = if ([scriptblock]::Create($TestScript).Invoke()) { 'Up to date' } else { 'Not up to date' } }
            }
        }

        #### Create WAC shortcut ####

        cShortcut 'WAC Shortcut' {
            Path      = 'C:\Users\Public\Desktop\Windows Admin Center.lnk'
            Target    = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
            Arguments = 'https://{0}' -f $env:ComputerName
            Icon      = 'shell32.dll,34'
        }

        #### Create custom firewall for WAC ####

        Firewall 'WAC inbound firewall rule' {
            Ensure      = 'Present'
            Name        = 'WAC-HTTPS-In-TCP'
            DisplayName = 'Windows Admin Center (HTTPS-In)'
            Profile     = 'Any'
            Direction   = 'Inbound'
            LocalPort   = "443"
            Protocol    = 'TCP'
            Description = 'Inbound rule for Windows Admin Center'
            Enabled     = 'True'
        }

        Firewall 'WAC outbound firewall rule' {
            Ensure      = 'Present'
            Name        = 'WAC-HTTPS-Out-TCP'
            DisplayName = 'Windows Admin Center (HTTPS-Out)'
            Profile     = 'Any'
            Direction   = 'Outbound'
            LocalPort   = "443"
            Protocol    = 'TCP'
            Description = 'Outbound rule for Windows Admin Center'
            Enabled     = 'True'
        }

        #### Wait for ready to nested VMs ####

        Script 'Wait for nested VMs configuration completion' {
            TestScript = {
                $false  # Applies every time.
            }
            SetScript = {
                $timeoutTime = [DateTime]::Now.AddMinutes(15)  # Maximum waiting period.
                while (($remainingRunningVMs = (Get-VM | Where-Object -Property 'State' -EQ -Value ([Microsoft.HyperV.PowerShell.VMState]::Running) | Measure-Object).Count) -gt 0) {
                    Write-Verbose -Message ('Waiting for {0} VM(s) to complete configuration.' -f $remainingRunningVMs) -Verbose
                    Start-Sleep -Seconds 10
                    if ([DateTime]::Now -gt $timeoutTime) {
                        Write-Verbose -Message ('Still {0} nested VM(s) running, but wait timed-out.' -f $remainingRunningVMs) -Verbose
                        break
                    }
                }
            }
            GetScript = {
                @{ Result = 'Applies every time' }
            }
            DependsOn = &{
                1..$NumOfNestedVMs | ForEach-Object -Process {
                    $nestedVMIndex = $_
                    $nestedVMName = '{0}{1:D2}' -f $nestedVMNamePrefix, $nestedVMIndex
                    "[Script]Start VM $nestedVMName"
                }
            }
        }

        Script 'Start nested VMs' {
            TestScript = {
                $false  # Applies every time.
            }
            SetScript = {
                Get-VM | Start-VM -Verbose
            }
            GetScript = {
                @{ Result = 'Applies every time' }
            }
            DependsOn = @(
                '[Script]Wait for nested VMs configuration completion'
            )
        }
    }
}
