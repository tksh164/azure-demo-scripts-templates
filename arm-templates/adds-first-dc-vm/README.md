# Deploy a first domain controller VM (AD DS) into a VNet

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fadds-first-dc-vm%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fadds-first-dc-vm%2Fuiform.json)

## Template overview

Deploy a first domain controller virtual machine of Active Directory domain service into an existing virtual network.

### Deployment

All the below names are the default value.

- Resource group: Specified existing resource group through the parameter.
- Virtual network: Specified existing virtual network through the parameter.
    - Subnet: Specified existing subnet through the parameter.
        - Availability set: `dc-as`
            - Virtual machine: `dc-vm1`
                - OS disk: `dc-vm1-osdisk`
                - Data disk: `dc-vm1-datadisk1`
                - Network interface: `dc-vm1-nic`
                    - Private IP address: Dynamic

## Notes

- The domain controller virtual machine is configured as domain controller through template deployment.
- The private IP address assignment of the DC virtual machine has set as **Dynamic**. Change to **Static** if you needed.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).


## TODO

- [ ] Update README
- [ ] Add Public IP address option
- [ ] Add NSG resource assosiation
- [ ] Add Availability Set / Availability Zone option
