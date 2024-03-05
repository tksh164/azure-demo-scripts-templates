# Create a new resource group to store the storage account.
$resourceGroupName = 'managed-app-artifacts'
$location = 'japaneast'
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# Create a new storage account.
$storageAccountName = 'managedapp{0}' -f [DateTime]::Now.ToString('HHmm')

'Storage account: {0}' -f $storageAccountName

$params = @{
    ResourceGroupName     = $resourceGroupName
    Name                  = $storageAccountName
    Location              = $location
    SkuName               = 'Standard_LRS'
    Kind                  = 'StorageV2'
    MinimumTlsVersion     = 'TLS1_2'
    AllowBlobPublicAccess = $true  # NOTE: Not secure this
}
$storageAccount = New-AzStorageAccount @params
$context = $storageAccount.Context

# Create a new container in the storage account.
$containerName = 'managedapp'
New-AzStorageContainer -Context $context -Name $containerName -Permission Blob

# Upload the app.zip file to the container.
$params = @{
    File      = '.\app.zip'
    Container = $containerName
    Blob      = 'app.zip'
    Context   = $context
}
Set-AzStorageBlobContent @params
