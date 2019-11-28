# On-premises to VNet for demo

The on-premises network is simulated by VNet.

## Template overview

### Deployments

- Resource group: `Demo-VPN-OnPrem-VNet`
- VNet: `onprem-vnet`
    - Subnet: `default`
        - Virtual machine: `onprem-vm1`
            - Disk: `onprem-vm1-osdisk`
            - Network interface: `onprem-vm1-nic`
            - Public IP address: `onprem-vm1-ip`
            - Network security group: `onprem-vm1-nsg`
    - Subnet: `GatewaySubnet`
        - VPN gateway: `onprem-vpngw`
            - Public IP address: `onprem-vpngw-ip` - For VPN gateway.
- VNet: `azure-vnet`
    - Subnet: `default`
        - Virtual machine: `azure-vm1`
            - Disk: `azure-vm1-osdisk`
            - Network interface: `azure-vm1-nic`
            - Public IP address: `azure-vm1-ip`
            - Network security group: `azure-vm1-nsg`
    - Subnet: `GatewaySubnet`
        - VPN gateway: `azure-vpngw`
            - Public IP address: `azure-vpngw-ip` - For VPN gateway.

### No deployments

- Create no connections inter VPN gateways.

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
