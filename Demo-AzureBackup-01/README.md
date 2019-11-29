# For Azure Backup demo

## Template overview

### Deployments

All the below names are the default value.

- Resource group: `Dmeo-AzureBackup`
- Recovery Services vault: `azbackup-rsv`
- Virtual network: `azbackup-vnet`
    - Subnet: `default`
        - Virtual machine: `dc-vm1`
            - Domain Controller for Azure Backup Server. You need to setup Domain Controoler manually.
            - OS disk: `dc-vm1-osdisk`
            - Data disk: `dc-vm1-datadisk1`
            - Network interface: `dc-vm1-nic`
            - Public IP address: `dc-vm1-ip`
            - Network security group: `dc-vm1-nsg`
        - Virtual machine: `abs-vm1`
            - For Azure Backup Server. You need to setup Azure Backup Server manually.
            - OS disk: `abs-vm1-osdisk`
            - Data disk: `abs-vm1-datadisk1`
            - Network interface: `abs-vm1-nic`
            - Public IP address: `abs-vm1-ip`
            - Network security group: `abs-vm1-nsg`
        - Virtual machine: `vmbackup-vm1`
            - For pre-configured VM backup. You need to configure the VM backup manually.
            - OS disk: `vmbackup-vm1-osdisk`
            - Network interface: `vmbackup-vm1-nic`
            - Public IP address: `vmbackup-vm1-ip`
            - Network security group: `vmbackup-vm1-nsg`
        - Virtual machine: `vmbackup-vm2`
            - For configuration demo of VM backup.
            - OS disk: `vmbackup-vm2-osdisk`
            - Network interface: `vmbackup-vm2-nic`
            - Public IP address: `vmbackup-vm2-ip`
            - Network security group: `vmbackup-vm2-nsg`

### No deployments

- Domain Controller is not configured.
- Azure Backup Server is not configured.
- VM Backup is not configured to both VMs.

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
