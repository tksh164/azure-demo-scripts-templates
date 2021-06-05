[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $RegisteredServerName,

    [Parameter(Mandatory = $true)]
    $DriveLetter,  # K:

    [Parameter(Mandatory = $false)]
    $LocalPathPrefix = 'afs',

    [Parameter(Mandatory = $false)]
    [string] $SyncGroupPrefix = 'syncgroup-'
)

$ErrorActionPreference = [Management.Automation.ActionPreference]::Continue

Measure-Command -Expression {

    Get-AzStorageSyncService -ResourceGroupname $ResourceGroupName -Verbose |
        ForEach-Object -Process {
            $storageSyncService = $_

            $server = Get-AzStorageSyncServer -ParentObject $storageSyncService -Verbose |
                Where-Object -Property 'FriendlyName' -EQ -Value $RegisteredServerName |
                Select-Object -First 1
    
            if ($server -ne $null)
            {
                Get-AzStorageSyncGroup -ParentObject $storageSyncService -Verbose |
                    Sort-Object -Property 'SyncGroupName' |
                    ForEach-Object -Process {
                        $syncGroup = $_

                        $serverEndpointCount = (Get-AzStorageSyncServerEndpoint -ParentObject $syncGroup -Verbose |
                            Where-Object -Property 'FriendlyName' -EQ -Value $server.FriendlyName |
                            Select-Object -First 1 |
                            Measure-Object).Count
            
                        if ($serverEndpointCount -eq 0)
                        {
                            Write-Verbose -Message ('Sync Group {0}.' -f $syncGroup.SyncGroupName) -Verbose
                            $num = $syncGroup.SyncGroupName.Replace($SyncGroupPrefix, '')
                            $params = @{
                                ParentObject                 = $syncGroup
                                Name                         = (New-Guid).Guid.ToString()
                                ServerResourceId             = $server.ResourceId
                                ServerLocalPath              = [IO.Path]::Combine($DriveLetter, ('{0}{1}' -f $LocalPathPrefix, $num))
                                #CloudTiering                 = $false
                                #VolumeFreeSpacePercent       = 20
                                #TierFilesOlderThanDays       = 
                                OfflineDataTransfer          = $false
                                #OfflineDataTransferShareName = ''
                                #InitialDownloadPolicy        = 'NamespaceOnly'
                                #LocalCacheMode               = 'UpdateLocallyCachedFiles'
                                Verbose                      = $true
                                #ErrorAction                  = [System.Management.Automation.ActionPreference]::Continue
                            }
                            New-AzStorageSyncServerEndpoint @params
                        }
                        else
                        {
                            Write-Verbose -Message ('Sync Group {0} has the server endpoint {1} already.' -f $syncGroup.SyncGroupName, $server.FriendlyName) -Verbose
                        }
                    }
            }
            else
            {
                Write-Verbose -Message ('{0} was not registered.' -f $RegisteredServerName) -Verbose
            }
        }

}
