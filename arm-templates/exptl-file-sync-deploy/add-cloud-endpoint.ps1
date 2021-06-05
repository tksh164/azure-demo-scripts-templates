[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string] $StorageAccountPrefix = 'fsync',

    [Parameter(Mandatory = $false)]
    [string] $SyncGroupPrefix = 'syncgroup-'
)

$ErrorActionPreference = [Management.Automation.ActionPreference]::Continue

Measure-Command -Expression {

    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Verbose

    Get-AzStorageSyncService -ResourceGroupname $ResourceGroupName -Verbose |
        ForEach-Object -Process {
            $storageSyncService = $_

            Get-AzStorageSyncGroup -ParentObject $storageSyncService -Verbose |
                Sort-Object -Property 'SyncGroupName' |
                ForEach-Object -Process {
                    $syncGroup = $_

                    $cloudEndpointCount = (Get-AzStorageSyncCloudEndpoint -ParentObject $syncGroup -Verbose | Measure-Object).Count

                    if ($cloudEndpointCount -eq 0)
                    {
                        Write-Verbose -Message ('Sync Group {0}.' -f $syncGroup.SyncGroupName) -Verbose

                        $num = $syncGroup.SyncGroupName.Replace($SyncGroupPrefix, '')
                        $storageAccount = $storageAccounts |
                            Where-Object -Property 'StorageAccountName' -Like -Value ('{0}{1}*' -f $StorageAccountPrefix, $num) |
                            Select-Object -First 1
                        $share = (Get-AzStorageShare -Context $storageAccount.Context -Verbose) | Select-Object -First 1
    
                        $params = @{
                            ParentObject             = $syncGroup
                            Name                     = (New-Guid).Guid.ToString()
                            StorageAccountResourceId = $storageAccount.Id
                            AzureFileShareName       = $share.Name
                            Verbose                  = $true
                        }
                        New-AzStorageSyncCloudEndpoint @params
                    }
                    else
                    {
                        Write-Verbose -Message ('Sync Group {0} has a cloud endpoint already.' -f $syncGroup.SyncGroupName) -Verbose
                    }
                }
        }
}
