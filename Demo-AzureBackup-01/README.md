# For Azure Backup demo

## Template overview

### Deployments

- Resource group: `Dmeo-AzureBackup`
- Recovery Services vault: `azbackup-rsv`
- VNet: `azbackup-vnet`
    - Subnet: `default`
        - Virtual machine: `abs-vm1`
            - For Azure Backup Server. You need to setup Azure Backup Server manually.
            - Disk: `abs-vm1-osdisk`
            - Network interface: `abs-vm1-nic`
            - Public IP address: `abs-vm1-ip`
            - Network security group: `abs-vm1-nsg`
        - Virtual machine: `vmbakup-vm1`
            - For pre-configured VM backup. You need to configure the VM backup manually.
            - Disk: `vmbakup-vm1-osdisk`
            - Network interface: `vmbakup-vm1-nic`
            - Public IP address: `vmbakup-vm1-ip`
            - Network security group: `vmbakup-vm1-nsg`
        - Virtual machine: `vmbakup-vm2`
            - For configuration demo of VM backup.
            - Disk: `vmbakup-vm2-osdisk`
            - Network interface: `vmbakup-vm2-nic`
            - Public IP address: `vmbakup-vm2-ip`
            - Network security group: `vmbakup-vm2-nsg`

All the above names are the default value.

### No deployments

- Azure Backup Server is not configured.
- VM Backup is not configured to both VMs.

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
