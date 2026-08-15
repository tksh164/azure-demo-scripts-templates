# VMs on Dedicated Host

## Deploy VMs onto a dedicated host

```powershell
$env:SSH_PUB_KEY = Get-Content -Raw -LiteralPath 'path-to-ssh-pub-key-file'

$resourceGroupName = 'resource-group-name-to-deploy-vms'
$templateFilePath = '.\template.bicep'
$templateParameterFilePath = '.\template.bicepparam'

New-AzResourceGroupDeployment -Name ([guid]::NewGuid()) -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $templateParameterFilePath -Verbose
```

```powershell
$env:SSH_PUB_KEY = Get-Content -Raw -LiteralPath 'path-to-ssh-pub-key-file'

$resourceGroupName = 'resource-group-name-to-deploy-vms'
$templateFilePath = '.\template.bicep'
$templateParameterFilePath = '.\template.bicepparam'

az deployment group create --name ([guid]::NewGuid()) --resource-group $resourceGroupName --template-file $templateFilePath --parameters $templateParameterFilePath
```

## Remove VMs on a dedicated host

```powershell
Remove-VMOnDedicatedHost.ps1 -HostId '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/RG1/providers/Microsoft.Compute/hostGroups/hostgroup1/hosts/host1'
```
