# Change the Windows language and regional settings using the DSC extension

## Template overview

This template demonstrates that change the Windows language and region settings using the DSC extension.

You can use non-English language and region settings since first login even if use the Azure Marketplace image because the DSC extension changes the Windows language and region settings for default account and system account. It's meaning the new user's language and welcome screen language are changed.

Simple PowerShell script version is [here](https://github.com/tksh164/change-windows-language-regional-settings).

### Deployments

- Resource group: `exptl-langregion`
- Virtual network: `langregion-vnet`
    - IPv4 address space: `10.0.0.0/16`
    - Subnet: `default`
        - Address prefix: `10.0.0.0/24`
        - Virtual machine: `langregion-vm1`
            - For RDP connection from Internet.
            - OS disk: `langregion-vm1-osdisk`
            - Network interface: `langregion-vm1-nic`
                - Private IP address: `10.0.0.5`, Static
            - Public IP address: `langregion-vm1-ip`
            - Network security group: `langregion-vm1-nsg`

All the above names are the default value.

### Non-deployments

- n/a

### Diagram

- n/a

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
