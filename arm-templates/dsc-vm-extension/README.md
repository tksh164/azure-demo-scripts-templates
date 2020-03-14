# DSC VM extension

## Template overview

Virtual machine with DSC VM extension.

### Deployments

All the below names are the default value.

- Resource group: `lab-dscext`
- Virtual network: `dscext-vnet`
    - IPv4 address space: `10.0.0.0/16`
    - Subnet: `default`
        - Address prefix: `10.0.0.0/24`
        - Virtual machine: `dscext-vm1`
            - For RDP connection from Internet.
            - OS disk: `dscext-vm1-osdisk`
            - Network interface: `dscext-vm1-nic`
                - Private IP address: `10.0.0.5`, Static
            - Public IP address: `dscext-vm1-ip`
            - Network security group: `dscext-vm1-nsg`

### Non-deployments

- n/a

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
