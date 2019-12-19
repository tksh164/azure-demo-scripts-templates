# Role playing PoC

## Template overview

### Deployments

- Resource group: `demo-roleplaying-poc`
    - VNet: `poc-vnet`
        - Subnet: `adds-subnet`
            - Network security group: `adds-subnet-nsg`
            - Availability set: `dc-as`
                - Virtual Machine: `dc-vm1`
                    - OS disk: `dc-vm1-osdisk`
                    - Data disk: `dc-vm1-datadisk1`
                - Virtual Machine: `dc-vm2`
                    - OS disk: `dc-vm2-osdisk`
                    - Data disk: `dc-vm2-datadisk1`
        - Subnet: `database-subnet`
            - Network security group: `database-subnet-nsg`
            - Availability set: `db-as`
                - Virtual Machine: `db-vm1`
                    - OS disk: `db-vm1-osdisk`
                    - Data disk: `db-vm1-datadisk1`
                - Virtual Machine: `db-vm2`
                    - OS disk: `db-vm2-osdisk`
                    - Data disk: `db-vm2-datadisk1`
        - Subnet: `web-subnet`
            - Network security group: `web-subnet-nsg`
            - Availability set: `web-as`
                - Virtual Machine: `web-vm1`
                - Virtual Machine: `web-vm2`
                - Virtual Machine: `web-vm3`
        - Subnet: `appgateway-subnet`
            - Network security group: `appgateway-subnet-nsg`
            - Application gateway: `waf-ag`
                - Public IP address: `waf-ag-ip`
        - Subnet: `AzureFirewallSubnet`
            - Firewall: `firewall`
                - Public IP address: `firewall-ip`
        - Subnet: `AzureBastionSubnet`
            - Network security group: `bastion-subnet-nsg`
            - Bastion: `bastion`
                - Public IP address: `bastion-ip`
    - Route table: `firewall-route`
        - Associated subnets: `adds-subnet`, `database-subnet`
    - Storage account: `imagestore####`
    - Private endpoint: `imagestore-privateendpoint`
    - Private DNS zone: `privatelink.file.core.windows.net`
    - Log Analytics workspace: `monitor####-law`
    - Recovery Services vault: `backup####-rsv`

### Non-deployments

- The guest OS configurations.
- The Recovery Services vault is not configured.
- The Loa Analytics workspace is not configured.

## Notes

- The some resources (e.g. Recovery Services vault) are cannot deploy with same resource group name and same resource name within 24 hours even if it's deleted.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
