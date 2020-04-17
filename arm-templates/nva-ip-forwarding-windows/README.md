# Deploy Windows-based NVA into existing vNet

## Template overview

Deploy a Windows-based network virtual appliance virtual machine into an existing virtual network.

### Deployments

All the below names are the default value.

- Resource group: Specified existing resource group through the parameter.
- Virtual network: Specified existing virtual network through the parameter.
    - Subnet: Specified through the parameter.
        - Availability set: `nva-as`
            - NVA virtual machine: `nva-vm1`
                - OS disk: `nva-vm1-osdisk`
                - Network interface: `nva-vm1-nic`
                    - Private IP address: Dynamic
                    - IP forwarding: Enable
                - Public IP address: `nva-vm1-ip`
                    - DNS name label: `nva-vm1-****`
                - Network security group: `nva-vm1-nsg`
- Route table: `nva-rt`
    - Route: `example`

### Non-deployments

- n/a

### Diagram

- n/a

## Notes

- The private IP address assignment of the NVA virtual machine has set as **Dynamic**. Change to **Static** if you needed.
- The route table for NVA has not associated with any subnets.
- The route table for NVA has an example route.
- You may need to change the firewall in the NVA guest OS based on your desired.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
