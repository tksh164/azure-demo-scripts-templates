# Azure VM for Azure Arc-enabled servers evaluation

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Farc-server-eval-vm%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Farc-server-eval-vm%2Fuiform.json)

Run the following commands as an administrator before installing the Azure Connected Machine agent.

```powershell
[System.Environment]::SetEnvironmentVariable('MSFT_ARC_TEST', 'true', [System.EnvironmentVariableTarget]::Machine)
New-NetFirewallRule -Name 'BlockAzureIMDS' -DisplayName 'Block access to Azure IMDS' -Profile Any -Direction Outbound -RemoteAddress '169.254.169.254' -Action Block -Enabled True
```

## Reference

- [Evaluate Azure Arc-enabled servers on an Azure virtual machine](https://learn.microsoft.com/en-us/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine)
