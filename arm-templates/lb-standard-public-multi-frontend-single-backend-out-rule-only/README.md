# Enable only outbound connection in Public Standard load balancer

## Template overview

Enable only outbound connection in Public Standard load balancer.

### Deployments

All the below names are the default value.

- Resource group: `demo-lb-std-pub-outbound-only`
- Public Standard load balancer: `lboutonly-lb`
    - Public IP address: `lboutonly-lb-out-ip1`, `lboutonly-lb-out-ip2`
- Virtual network: `lboutonly-vnet`
    - IPv4 address space: `10.0.0.0/16`
    - Subnet: `default`
        - Address prefix: `10.0.0.0/24`
        - Virtual machine: `lboutonly-backend-vm1`
            - Virtual machine in the backend of the load balancer.
            - OS disk: `lboutonly-backend-vm1-osdisk`
            - Network interface: `lboutonly-backend-vm1-nic`
                - Private IP address: `10.0.0.10`, Static
            - Network security group: `lboutonly-backend-vm1-nsg`
        - Virtual machine: `lboutonly-backend-vm2`
            - Virtual machine in the backend of the load balancer.
            - OS disk: `lboutonly-backend-vm2-osdisk`
            - Network interface: `lboutonly-backend-vm2-nic`
                - Private IP address: `10.0.0.11`, Static
            - Network security group: `lboutonly-backend-vm2-nsg`
        - Virtual machine: `lboutonly-jump-vm1`
            - For RDP connection from Internet.
            - OS disk: `lboutonly-jump-vm1-osdisk`
            - Network interface: `lboutonly-jump-vm1-nic`
                - Private IP address: `10.0.0.5` - Static
            - Public IP address: `lboutonly-jump-vm1-ip`
            - Network security group: `lboutonly-jump-vm1-nsg`

### Non-deployments

- n/a

## Notes

- The backend virtual machines have Web Server role (IIS) installed.
- The jump virtual machine has Wireshark and Chromium Edge installer under "C:\\work".
- The deploy.ps1 script needs [Az module](https://www.powershellgallery.com/packages/Az/).
