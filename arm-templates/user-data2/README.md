# User data

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fuser-data2%2Ftemplate.json)

## Template overview

This template deploys a VM with user data. The user data is defined in the ARM template and it can be retrieved from within the VM.

## Use user data

Retrieve the user data from within the VM.

```powershell
$encodedUserData = Invoke-RestMethod -UseBasicParsing -Method Get -Headers @{ Metadata = 'true' } -Uri 'http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-12-13&format=text'
$userData = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedUserData)) -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/' | ConvertFrom-Json
```
