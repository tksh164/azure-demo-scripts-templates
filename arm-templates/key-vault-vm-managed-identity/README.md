# Get a secret from a Key Vault from inside an Azure VM with managed identity via Instance Metadata Service

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fkeyvault-vm-managed-identity%2Ftemplate.json)

## Template overview

This template deploys a VM and a Key Vault. Also, store to Key Vault the VM's admin password as a secret.

## Use the secret

Retrieve the secret from inside the virtual machine via Instance Metadata Service.

```powershell
$imdsResponse = Invoke-RestMethod -Method Get -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-12-13&resource=https%3A%2F%2Fvault.azure.net' -Headers @{ Metadata = 'true' }
$secret = Invoke-RestMethod -Method Get -Uri 'https://{KeyVaultName}.vault.azure.net/secrets/{SecretName}?api-version=7.3' -Headers @{ Authorization = ('Bearer {0}' -f $imdsResponse.access_token) }
$secret
```

## Reference

- [Tutorial: Use a Windows VM system-assigned managed identity to access Azure Key Vault](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-windows-vm-access-nonaad)
