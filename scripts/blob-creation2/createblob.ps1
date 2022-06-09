$resourceGroupName = 'simu-databox-transfer'
$storageAccountName = 'simudatabox1510'
$filePath = '.\blob-128kb.dat'
[uint64] $numOfBlobCreating = 100 #00000

$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

$containerName = [datetime]::Now.ToString('MMdd-hhmmss')
$container = New-AzStorageContainer -Context $storageAccount.Context -Name $containerName -Permission Off

# [UInt64]::MaxValue = 18446744073709551615
[uint64] $numOfBlobCreated = 0
$timeStarted = [datetime]::Now

for ($numOfBlobCreated = 0; $numOfBlobCreated -lt $numOfBlobCreating; $numOfBlobCreated++)
{
    $blobName = (New-Guid).Guid
    [void] (Set-AzStorageBlobContent -Context $storageAccount.Context -Container $container.Name -Blob $blobName -BlobType Block -File $filepath)
    Write-Progress -Activity 'Creating blobs...' -Status ('Created: {0}/{1}, Elapsed: {2}' -f $numOfBlobCreated, $numOfBlobCreating, ([datetime]::Now - $timeStarted))
}

Write-Host ('Created: {0}/{1}' -f $numOfBlobCreated, $numOfBlobCreating)
[datetime]::Now - $timeStarted
