# User data

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fuser-data%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fuser-data%2Fuiform.json)

## Template overview

This template deploys a VM with user data. The user data can be retrieve from within the VM.

## Use user data

Sample user data.

```jsonc
/*
Sample user data
*/
{
    "id": "Value",
    "switch": true,
    "number": 123,
    "items": [
        {
            "id": 0,
            "value": "C:\\temp"
        },
        {
            "id": 1,
            "value": "V:\\data\\file"
        },
        {
            "id": 2,
            "value": ""  // Can be set empty string
        }//,
        // {
        //     "id": 3,
        //     "value": "C:\\work"
        // }
    ]
}
```

Retrieve the user data from inside of the VM.

```powershell
$encodedUserData = Invoke-RestMethod -UseBasicParsing -Method Get -Headers @{ Metadata = 'true' } -Uri 'http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-12-13&format=text'
$userData = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUserData)) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/' | ConvertFrom-Json
$userData
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
