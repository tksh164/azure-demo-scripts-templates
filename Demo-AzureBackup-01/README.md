# For Azure Backup demo

## Template overview

### Deployments

All the below names are the default value.

- Resource group: `Dmeo-AzureBackup`
- Recovery Services vault: `azbackup########-rsv`
- Storage account: `azbackupdiag########`
    - Diagnostics storage account for the Recovery Services vault.
- Virtual network: `azbackup-vnet`
    - Subnet: `default`
        - Address prefix: `10.0.0.0/24`
        - Virtual machine: `dc-vm1`
            - Domain Controller for the Azure Backup Server. You need to setup Domain Controoler manually.
            - OS disk: `dc-vm1-osdisk`
            - Data disk: `dc-vm1-datadisk1`
            - Network interface: `dc-vm1-nic`
                - Private IP address: `10.0.0.4` - Static
            - Public IP address: `dc-vm1-ip`
            - Network security group: `dc-vm1-nsg`
        - Virtual machine: `abs-vm1`
            - For Azure Backup Server. You need to setup Azure Backup Server manually.
            - OS disk: `abs-vm1-osdisk`
            - Data disk: `abs-vm1-datadisk1`
            - Network interface: `abs-vm1-nic`
                - Private IP address: `10.0.0.5` - Static
                - DNS servers: `10.0.0.4`
            - Public IP address: `abs-vm1-ip`
            - Network security group: `abs-vm1-nsg`
        - Virtual machine: `vmbackup-vm1`
            - For pre-configured VM backup. You need to configure the VM backup manually.
            - OS disk: `vmbackup-vm1-osdisk`
            - Network interface: `vmbackup-vm1-nic`
                - Private IP address: `10.0.0.6` - Static
            - Public IP address: `vmbackup-vm1-ip`
            - Network security group: `vmbackup-vm1-nsg`
        - Virtual machine: `vmbackup-vm2`
            - For configuration demo of VM backup.
            - OS disk: `vmbackup-vm2-osdisk`
            - Network interface: `vmbackup-vm2-nic`
                - Private IP address: `10.0.0.7` - Static
            - Public IP address: `vmbackup-vm2-ip`
            - Network security group: `vmbackup-vm2-nsg`

### No deployments

- The Recovery Services vault's diagnostics settings are not configured.
- Domain Controller is not configured.
- Azure Backup Server is not configured.
- VM Backup is not configured to both VMs.

## Notes

- First, you do make the domain controller. Next, join the Azure Backup Server to the AD domain. Those steps are needed before the setup Azure Backup Server because of the effect of DNS settings.
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
