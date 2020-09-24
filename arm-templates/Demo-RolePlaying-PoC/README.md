# Role playing PoC

You can deploy this template by the `deploy.ps1` script. Also can specify the resource group via `-ResourceGroupName` parameter.

```
PS > .\deploy.ps1
```

## Template overview

![Template overview](./template.drawio.svg)

### Deployments

- Resource group: `demo-roleplaying-poc`
    - VNet: `poc-vnet`
        - Subnet: `adds-subnet`
            - Network security group: `adds-subnet-nsg`
            - Virtual Machine: `adds-dc-vm1`
                - OS disk: `adds-dc-vm1-osdisk`
                - Data disk: `adds-dc-vm1-datadisk1`
            - Virtual Machine: `adds-dc-vm2`
                - OS disk: `adds-dc-vm2-osdisk`
                - Data disk: `adds-dc-vm2-datadisk1`
        - Subnet: `database-subnet`
            - Network security group: `database-subnet-nsg`
            - Internal load balancer: `database-lbi`
                - Virtual Machine: `database-vm1`
                    - OS disk: `database-vm1-osdisk`
                    - Data disk: `database-vm1-datadisk1`
                - Virtual Machine: `database-vm2`
                    - OS disk: `database-vm2-osdisk`
                    - Data disk: `database-vm2-datadisk1`
        - Subnet: `web-subnet`
            - Network security group: `web-subnet-nsg`
            - Virtual Machine: `web-vm1`
                - OS disk: `web-vm1-osdisk`
                - Data disk: `web-vm1-datadisk1`
            - Virtual Machine: `web-vm2`
                - OS disk: `web-vm1-osdisk`
                - Data disk: `web-vm1-datadisk1`
            - Virtual Machine: `web-vm3`
                - OS disk: `web-vm1-osdisk`
                - Data disk: `web-vm1-datadisk1`
        - Subnet: `appgateway-subnet`
            - Network security group: `appgateway-subnet-nsg`
            - Application gateway: `web-waf-agw`
                - Public IP address: `web-waf-agw-ip`
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
- The internal load balancer is not configured.
- The application gateway is not configured.
- The Recovery Services vault is not configured.
- The Log Analytics workspace is not configured.

## Notes

- The some resources (e.g. Recovery Services vault) are cannot deploy with same resource group name and same resource name within 24 hours even if it's deleted.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
