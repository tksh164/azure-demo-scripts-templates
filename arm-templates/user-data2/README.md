# User data

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fuser-data2%2Ftemplate.json)

## Template overview

This template deploys a VM with user data. The user data is defined in the ARM template and it can be retrieved from within the VM.

## Use user data

Retrieve the user data from inside of the VM.

```powershell
$encodedUserData = Invoke-RestMethod -UseBasicParsing -Method Get -Headers @{ Metadata = 'true' } -Uri 'http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-12-13&format=text'
$userData = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUserData)) | ConvertFrom-Json
```

Retrieve the user data from outside of the VM.

```powershell
$restResult = Invoke-AzRestMethod -Method GET -Uri 'https://management.azure.com/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupNmae}/providers/Microsoft.Compute/virtualMachines/{VMName}?api-version=2022-08-01&$expand=userData'
$vmData = $restResult.Content | ConvertFrom-Json
$userData = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($vmData.properties.userData)) | ConvertFrom-Json
$userData
```

Update the user data from outside of the VM.

```powershell
$restResult = Invoke-AzRestMethod -Method GET -Uri 'https://management.azure.com/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupNmae}/providers/Microsoft.Compute/virtualMachines/{VMName}?api-version=2022-08-01&$expand=userData'
$vmData = $restResult.Content | ConvertFrom-Json
$userData = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($vmData.properties.userData)) | ConvertFrom-Json

# Update the user data.
$userData.number = 456
$vmData.properties.userData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($userData | ConvertTo-Json -Depth 32)))
Invoke-AzRestMethod -Method PATCH -Uri 'https://management.azure.com/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupNmae}/providers/Microsoft.Compute/virtualMachines/{VMName}?api-version=2022-08-01' -Payload ($vmData | ConvertTo-Json -Depth 32)
```

## Reference

- [User Data for Azure Virtual Machine](https://learn.microsoft.com/en-us/azure/virtual-machines/user-data)
