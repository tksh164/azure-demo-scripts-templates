# Deploy a first domain controller VM (AD DS) into a VNet

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fpreconfigured%2Fadds-first-dc-vm%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fpreconfigured%2Fadds-first-dc-vm%2Fuiform.json)

## Template overview

Deploy a first domain controller virtual machine of Active Directory domain service into an existing virtual network or a new virtual network.

## Notes

- The domain controller virtual machine is configured as domain controller through template deployment.
- The private IP address assignment of the DC virtual machine has set as **Dynamic**. Change to **Static** if you needed.

## TODO

- [ ] Add Public IP address option
- [ ] Add NSG resource assosiation
- [ ] Add Availability Set / Availability Zone option
