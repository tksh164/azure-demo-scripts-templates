# VNet to VNet for demo

## Template overview

### Deployments

- Resource group: `Demo-VPN-VNet-VNet`
- VNet: `vnet1`
    - Subnet: `default`
    - Subnet: `GatewaySubnet`
        - VPN Gateway: `vnet1-vpngw`
- VNet: `vnet2`
    - Subnet: `default`
    - Subnet: `GatewaySubnet`
        - VPN Gateway: `vnet2-vpngw`
- Public IP Address: `vnet1-vpngw-ip` - For VPN gateway.
- Public IP Address: `vnet2-vpngw-ip` - For VPN gateway.

### No deployments

- Deploy no virtual machines.
- Create no connections inter VPN gateways.

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
