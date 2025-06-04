// Parameters

@description('The virtual network name.')
param virtualNetworkName string

@description('The firewall name.')
param firewallName string

@description('Location for resources.')
param location string = resourceGroup().location

// Variables

var firewallSubnetName = 'AzureFirewallSubnet'

// Resource declarations

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${firewallName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [ '1', '2', '3' ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: firewallName
  location: location
  zones: [ '1', '2', '3' ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfiguration'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${firewallSubnetName}'
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
}
