# Virtual network peering

## Template overview

Full-mesh virtual network peering with three virtual networks.

### Deployment

All the below names are the default value.

- Resource group: `demo-vnet-peering`
- Virtual network: `peering-vnet1`
    - IPv4 address space: `10.0.0.0/16`
    - Subnet: `subnet1`
        - Address prefix: `10.0.0.0/24`
    - Subnet: `subnet2`
        - Address prefix: `10.0.1.0/24`
- Virtual network: `peering-vnet2`
    - IPv4 address space: `172.16.0.0/16`
    - Subnet: `subnet1`
        - Address prefix: `172.16.0.0/24`
- Virtual network: `peering-vnet3`
    - IPv4 address space: `192.168.0.0/16`
    - Subnet: `subnet1`
        - Address prefix: `192.168.0.0/24`
    - Subnet: `subnet2`
        - Address prefix: `192.168.1.0/24`
    - Subnet: `subnet3`
        - Address prefix: `192.168.2.0/24`

### Not deployment

- n/a

### Diagram

![Diagram](./diagram.drawio.svg)

## Notes

- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
