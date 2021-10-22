$metadata = Invoke-RestMethod -Method Get -Headers @{ 'Metadata' = 'true' } -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01'
if ($metadata.compute.platformFaultDomain -eq '0')
{
    $driveLetter = 'W'
    $volumeLabel = 'Witness'

    Get-Disk |
        Where-Object -FilterScript { ($_.PartitionStyle -eq 'RAW') -and ($_.AllocatedSize -eq 0) -and ($_.NumberOfPartitions -eq 0) } |
        Sort-Object -Property 'DiskNumber' |
        Select-Object -First 1 |
        Initialize-Disk -PartitionStyle GPT -PassThru |
        New-Volume -FileSystem NTFS -DriveLetter $driveLetter -FriendlyName $volumeLabel
}

Install-WindowsFeature -Name 'Failover-Clustering' -IncludeManagementTools -Restart
