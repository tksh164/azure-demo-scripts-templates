# Deploy a proxy server using Squid

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fpreconfigured%2Fsquid-proxy%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fpreconfigured%2Fsquid-proxy%2Fuiform.json)

## Template overview

Deploy a proxy server virtual machine using Squid into an existing virtual network.

### Deployment

To be updated.

## Notes

- Squid is installed through the template deployment.
- The private IP address assignment of the proxy server virtual machine has set as **Dynamic**. Change to **Static** if you needed.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).

## TODO

- [ ] Update README
- [ ] Add Public IP address option
- [ ] Add NSG resource assosiation
- [ ] Add Availability Set / Availability Zone option
