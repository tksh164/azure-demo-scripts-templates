[CmdletBinding()]
param ()

$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
$WarningPreference = [Management.Automation.ActionPreference]::Continue
$VerbosePreference = [Management.Automation.ActionPreference]::Continue
$ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

Import-Module -Name ([IO.Path]::Combine($PSScriptRoot, 'shared.psm1')) -Force

$labConfig = Get-LabDeploymentConfig
Start-ScriptLogging -OutputDirectory $labConfig.labHost.folderPath.log
$labConfig | ConvertTo-Json -Depth 16 | Write-Host

$nodes = @()
$nodes += for ($nodeIndex = 0; $nodeIndex -lt $labConfig.hciNode.nodeCount; $nodeIndex++) {
    GetHciNodeVMName -Format $labConfig.hciNode.vmName -Offset $labConfig.hciNode.vmNameOffset -Index $nodeIndex
}

$adminPassword = GetSecret -KeyVaultName $labConfig.keyVault.name -SecretName $labConfig.keyVault.secretName.adminPassword
$domainCredential = CreateDomainCredential -DomainFqdn $labConfig.addsDomain.fqdn -Password $adminPassword

'Preparing HCI node drives...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName     = $nodes
    Credential = $domainCredential
}
Invoke-Command @params -ScriptBlock {
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    # Updates the cache of the service for a particular provider and associated child objects.
    Update-StorageProviderCache

    # Disable read-only state of storage pools except the Primordial pool.
    Get-StoragePool | Where-Object -Property 'IsPrimordial' -EQ -Value $false | Set-StoragePool -IsReadOnly:$false

    # Delete virtual disks in storage pools except the Primordial pool.
    Get-StoragePool | Where-Object -Property 'IsPrimordial' -EQ -Value $false | Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false -ErrorAction Continue

    # Delete storage pools except the Primordial pool.
    Get-StoragePool | Where-Object -Property 'IsPrimordial' -EQ -Value $false | Remove-StoragePool -Confirm:$false

    # Reset the status of a physical disks. (Delete the storage pool's metadata from physical disks)
    Get-PhysicalDisk | Reset-PhysicalDisk

    # Cleans disks by removing all partition information and un-initializing it, erasing all data on the disks.
    Get-Disk |
        Where-Object -Property 'Number' -NE $null |
        Where-Object -Property 'IsBoot' -NE $true |
        Where-Object -Property 'IsSystem' -NE $true |
        Where-Object -Property 'PartitionStyle' -NE 'RAW' |
        ForEach-Object -Process {
            $_ | Set-Disk -IsOffline:$false
            $_ | Set-Disk -IsReadOnly:$false
            $_ | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false
            $_ | Set-Disk -IsReadOnly:$true
            $_ | Set-Disk -IsOffline:$true
        }

    Get-Disk |
        Where-Object -Property 'Number' -NE $null |
        Where-Object -Property 'IsBoot' -NE $true |
        Where-Object -Property 'IsSystem' -NE $true |
        Where-Object -Property 'PartitionStyle' -EQ 'RAW' |
        Group-Object -NoElement -Property 'FriendlyName' |
        Sort-Object -Property 'PSComputerName'
} | Select-Object -Property 'PSComputerName', 'Count', 'Name' |
    Sort-Object -Property 'PSComputerName' |
    Out-String |
    Write-ScriptLog -Context $env:ComputerName

'Getting the node''s UI culture...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName     = $nodes[0]
    Credential = $domainCredential
}
$langTag = Invoke-Command @params -ScriptBlock {
    (Get-UICulture).IetfLanguageTag
}
'The node''s UI culture is "{0}".' -f $langTag | Write-ScriptLog -Context $env:ComputerName

$localizedDataFileName = ('cluster-test-categories-{0}.psd1' -f $langTag).ToLower()
'Localized data file name: {0}' -f $localizedDataFileName | Write-ScriptLog -Context $env:ComputerName
Import-LocalizedData -FileName $localizedDataFileName -BindingVariable 'clusterTestCategories'

'Testing the HCI cluster nodes...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName      = $nodes[0]
    Credential  = $domainCredential
    InputObject = [PSCustomObject] @{
        Node         = $nodes
        TestCategory = ([array] $clusterTestCategories.Values)
    }
}
Invoke-Command @params -ScriptBlock {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Node,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]] $TestCategory
    )

    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $params = @{
        Node        = $Node
        Include     = $TestCategory
        Verbose     = $true
        ErrorAction = [Management.Automation.ActionPreference]::Stop
    }
    Test-Cluster @params
}

'Creating an HCI cluster...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName      = $nodes[0]
    Credential  = $domainCredential
    InputObject = [PSCustomObject] @{
        ClusterName      = $labConfig.hciCluster.name
        ClusterIpAddress = $labConfig.hciCluster.ipAddress
        Node             = $nodes
    }
}
Invoke-Command @params -ScriptBlock {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClusterName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClusterIpAddress,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Node
    )

    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $params = @{
        Name          = $ClusterName
        StaticAddress = $ClusterIpAddress
        Node          = $Node
        NoStorage     = $true
        Verbose       = $true
        ErrorAction   = [Management.Automation.ActionPreference]::Stop
    }
    New-Cluster @params
}

'Waiting for the cluster to be ready...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName      = $nodes[0]
    Credential  = $domainCredential
    InputObject = [PSCustomObject] @{
        ClusterName = $labConfig.hciCluster.name
    }
}
Invoke-Command @params -ScriptBlock {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClusterName,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3600)]
        [int] $RetryIntervalSeconds = 15,

        [Parameter(Mandatory = $false)]
        [TimeSpan] $RetyTimeout = (New-TimeSpan -Minutes 10)
    )

    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $startTime = Get-Date
    while ((Get-Date) -lt ($startTime + $RetyTimeout)) {
        try {
            Get-Cluster -Name $ClusterName -ErrorAction Stop
            return
        }
        catch {
            (
                'Probing the cluster ready state... ' +
                '(ExceptionMessage: {0} | Exception: {1} | FullyQualifiedErrorId: {2} | CategoryInfo: {3} | ErrorDetailsMessage: {4})'
            ) -f @(
                $_.Exception.Message, $_.Exception.GetType().FullName, $_.FullyQualifiedErrorId, $_.CategoryInfo.ToString(), $_.ErrorDetails.Message
            ) | Write-Host
        }
        Start-Sleep -Seconds $RetryIntervalSeconds
    }
    throw 'The cluster was not ready in the acceptable time ({0}).' -f $RetyTimeout.ToString()
}

'Configuring the cluster quorum...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName      = $nodes[0]
    Credential  = $domainCredential
    InputObject = [PSCustomObject] @{
        ClusterName             = $labConfig.hciCluster.name
        StorageAccountName      = GetSecret -KeyVaultName $labConfig.keyVault.name -SecretName $labConfig.keyVault.secretName.cloudWitnessStorageAccountName -AsPlainText
        StorageAccountAccessKey = GetSecret -KeyVaultName $labConfig.keyVault.name -SecretName $labConfig.keyVault.secretName.cloudWitnessStorageAccountKey -AsPlainText
    }
}
Invoke-Command @params -ScriptBlock {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClusterName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $StorageAccountAccessKey
    )

    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $params = @{
        Cluster      = $ClusterName
        CloudWitness = $true
        AccountName  = $StorageAccountName
        AccessKey    = $StorageAccountAccessKey
        Verbose      = $true
        ErrorAction  = [Management.Automation.ActionPreference]::Stop
    }
    Set-ClusterQuorum @params
}

'Enabling Storage Space Direct (S2D)...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName      = $nodes[0]
    Credential  = $domainCredential
    InputObject = [PSCustomObject] @{
        StoragePoolName = 'hcilab-s2d-storage-pool'
    }
}
Invoke-Command @params -ScriptBlock {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $StoragePoolName
    )

    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $params = @{
        PoolFriendlyName = $StoragePoolName
        Confirm          = $false
        Verbose          = $true
        ErrorAction      = [Management.Automation.ActionPreference]::Stop
    }
    Enable-ClusterStorageSpacesDirect @params
}

'Creating a volume on S2D...' | Write-ScriptLog -Context $env:ComputerName
$params = @{
    VMName      = $nodes[0]
    Credential  = $domainCredential
    InputObject = [PSCustomObject] @{
        VolumeName      = 'HciVol'
        StoragePoolName = 'hcilab-s2d-storage-pool'
    }
}
Invoke-Command @params -ScriptBlock {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $VolumeName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $StoragePoolName
    )

    $ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
    $WarningPreference = [Management.Automation.ActionPreference]::Continue
    $VerbosePreference = [Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [Management.Automation.ActionPreference]::SilentlyContinue

    $params = @{
        FriendlyName            = $VolumeName
        StoragePoolFriendlyName = $StoragePoolName
        FileSystem              = 'CSVFS_ReFS'
        UseMaximumSize          = $true
        ProvisioningType        = 'Fixed'
        ResiliencySettingName   = 'Mirror'
        Verbose                 = $true
        ErrorAction             = [Management.Automation.ActionPreference]::Stop
    }
    New-Volume @params
}

'The HCI cluster creation has been completed.' | Write-ScriptLog -Context $env:ComputerName

Stop-ScriptLogging