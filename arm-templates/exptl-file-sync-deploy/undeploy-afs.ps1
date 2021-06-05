[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName
)

$ErrorActionPreference = [Management.Automation.ActionPreference]::Continue

Measure-Command -Expression {

    Get-AzStorageSyncService -ResourceGroupname $ResourceGroupName -Verbose |
        ForEach-Object -Process {
            $storageSyncService = $_

            Get-AzStorageSyncGroup -ParentObject $storageSyncService -Verbose |
                Sort-Object -Property 'SyncGroupName' |
                ForEach-Object -Process {
                    $syncGroup = $_

                    # Server Endpoint
                    Get-AzStorageSyncServerEndpoint -ParentObject $syncGroup -Verbose |
                        ForEach-Object -Process {
                            Write-Progress -Activity 'Sync Group' -Status 'Deleting...' -CurrentOperation 'Server Endpoint'
                            $_ | Remove-AzStorageSyncServerEndpoint -Force -Verbose
                        }

                    # Cloud Endpoint
                    Get-AzStorageSyncCloudEndpoint -ParentObject $syncGroup -Verbose |
                        ForEach-Object -Process {
                            Write-Progress -Activity 'Sync Group' -Status 'Deleting...' -CurrentOperation 'Cloud Endpoint'
                            $_ | Remove-AzStorageSyncCloudEndpoint -Force -Verbose
                        }

                    # Sync Group
                    Write-Progress -Activity 'Sync Group' -Status 'Deleting...' -CurrentOperation 'Sync Group'
                    Remove-AzStorageSyncGroup -InputObject $syncGroup -Force -Verbose
                }

            # Server
            Write-Progress -Activity 'Server' -Status 'Unregister...'
            Get-AzStorageSyncServer -ParentObject $storageSyncService -Verbose | Unregister-AzStorageSyncServer -Force -Verbose

            # Storage Sync Service
            Write-Progress -Activity 'Storage Sync Service' -Status 'Deleting...'
            $storageSyncService | Remove-AzStorageSyncService -Force -Verbose
        }

    # Storage Account
    Write-Progress -Activity 'Storage Account' -Status 'Deleting...'
    Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Verbose |
        ForEach-Object -Process {
            Remove-AzStorageAccount -ResourceGroupName $_.ResourceGroupName -Name $_.StorageAccountName -Force -Verbose
        }

    Write-Progress -Activity 'Done' -Completed
}
