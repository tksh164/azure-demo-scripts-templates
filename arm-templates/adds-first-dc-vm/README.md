# Deploy first domain controller into existing vNet

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fadds-first-dc-vm%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fadds-first-dc-vm%2Fuiform.json)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fadds-first-dc-vm%2Ftemplate.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Ftksh164%2Fazure-demo-scripts-templates%2Fmaster%2Farm-templates%2Fadds-first-dc-vm%2Fuiform2.json)


## Template overview

Deploy a first domain controller virtual machine of Active Directory domain service into an existing virtual network.

### Deployment

All the below names are the default value.

- Resource group: Specified existing resource group through the parameter.
- Virtual network: Specified existing virtual network through the parameter.
    - Subnet: Specified existing subnet through the parameter.
        - Availability set: `dc-as`
            - NVA virtual machine: `dc-vm1`
                - OS disk: `dc-vm1-osdisk`
                - Data disk: `dc-vm1-datadisk1`
                - Network interface: `dc-vm1-nic`
                    - Private IP address: Dynamic
                - Network security group: `dc-vm1-nsg`
- Load balancer: `dc-lb`
    - For the inbound NAT of RDP to the domain controller.
    - Public IP address: `dc-lb-ip`
        - DNS name label: `dc-lb-****`

## Notes

- The domain controller virtual machine is configured as domain controller through template deployment.
- The private IP address assignment of the DC virtual machine has set as **Dynamic**. Change to **Static** if you needed.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
