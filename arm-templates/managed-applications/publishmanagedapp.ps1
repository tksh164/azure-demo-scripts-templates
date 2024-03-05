# Create a new resource group to store the managed application.
$resourceGroupName = 'managed-app-artifacts'
$location = 'japaneast'
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# Get the storage account's context.
$storageAccountName = 'managedapp1408'
$params = @{
    ResourceGroupName = $resourceGroupName
    Name              = $storageAccountName
}
$storageAccount = Get-AzStorageAccount @params
$context = $storageAccount.Context

# Get the blob.
$containerName = 'managedapp'
$blobName = 'app.zip'
$blob = Get-AzStorageBlob -Context $context -Container $containerName -Blob $blobName 

# The principal ID and role ID.
$principalId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$roleId = 'yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'

# Create a new managed application definition.
$params = @{
    Name              = 'sample-managed-application'
    Location          = $location
    ResourceGroupName = $resourceGroupName
    LockLevel         = 'ReadOnly'
    DisplayName       = 'Sample managed application'
    Description       = 'Sample managed application that deploys web resources'
    Authorization     = '{0}:{1}' -f $principalId, $roleId
    PackageFileUri    = $blob.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri
}
New-AzManagedApplicationDefinition @params
