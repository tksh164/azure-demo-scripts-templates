$driveLetter = 'N'
$volumeLabel = 'ADDS Data'

Get-Disk |
    Where-Object -FilterScript { ($_.PartitionStyle -eq 'RAW') -and ($_.AllocatedSize -eq 0) -and ($_.NumberOfPartitions -eq 0) } |
    Sort-Object -Property 'DiskNumber' |
    Select-Object -First 1 |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Volume -FileSystem NTFS -DriveLetter $driveLetter -FriendlyName $volumeLabel

# Note: DNS and DNS management tools are automatically installed by the domain controller promotion.
Install-WindowsFeature -Name 'AD-Domain-Services','RSAT-ADDS','RSAT-AD-PowerShell','GPMC' -IncludeManagementTools -Restart
