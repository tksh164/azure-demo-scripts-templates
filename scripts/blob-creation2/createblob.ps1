param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string] $UploadFilePath,

    [Parameter(Mandatory = $true)]
    [string] $NumOfBlobCreating
)

$storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$containerName = ('{0}-x{1}' -f [datetime]::Now.ToString('MMddhhmmss'), $NumOfBlobCreating)
$container = New-AzStorageContainer -Context $storageAccount.Context -Name $containerName -Permission Off

$timeStarted = [datetime]::Now
for ([uint64] $numOfBlobCreated = 0; $numOfBlobCreated -lt $NumOfBlobCreating; $numOfBlobCreated++)
{
    $blobName = (New-Guid).Guid
    [void] (Set-AzStorageBlobContent -Context $storageAccount.Context -Container $container.Name -Blob $blobName -BlobType Block -File $UploadFilePath)
    Write-Progress -Activity 'Creating blobs...' -Status ('Created: {0}/{1}, Elapsed: {2}' -f $numOfBlobCreated, $NumOfBlobCreating, ([datetime]::Now - $timeStarted))
}

Write-Host ('Created: {0}/{1}' -f $numOfBlobCreated, $NumOfBlobCreating)
[datetime]::Now - $timeStarted
