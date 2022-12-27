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

Retrieve the user data from within the VM.

```powershell
$encodedUserData = Invoke-RestMethod -UseBasicParsing -Method Get -Headers @{ Metadata = 'true' } -Uri 'http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-12-13&format=text'
$userData = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUserData)) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/' | ConvertFrom-Json
```
