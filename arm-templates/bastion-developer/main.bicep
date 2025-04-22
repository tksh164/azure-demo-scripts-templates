// Parameters

@description('Location for resources.')
param location string = resourceGroup().location

@description('User name for the admin user.')
param adminUsername string = 'vmadmin'

@description('Password for the admin user.')
@secure()
@minLength(12)
param adminPassword string

// Variables

var prefix = 'bastiondev'

var subnetName = 'default' // Name of the subnet.

var vmName = '${prefix}-vm1' // Name of the virtual machine.
var vmSize = 'Standard_B2ms' // Virtual machine size.

// Resource declarations

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${prefix}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionRDPInbound'
        properties: {
          direction: 'Inbound'
          priority: 3000
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '168.63.129.16'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3389'
          description: 'Allow Bastion Developer RDP inbound.'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${vmName}-nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2025-datacenter-azure-edition-smalldisk'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: '${prefix}-bastiondev'
  location: location
  sku: {
    name: 'Developer'
  }
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    // networkAcls: {
    //   ipRules: [
    //     {
    //       addressPrefix: ''
    //     }
    //   ]
    // }
  }
}
