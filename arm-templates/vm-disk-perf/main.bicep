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

var prefix = 'diskbench'

var subnetName = 'default'  // Name of the subnet.

var vmName = '${prefix}-vm1'     // Name of the virtual machine.
var vmSize = 'Standard_E16s_v5'  // Virtual machine size.
var zone = '1'                   // Availability zone for resources.

var diskConfig = {
  // SKU for the data disks.
  dataDiskSku: 'StandardSSD_LRS'

  // Caching type for the data disks.
  hostCaching: 'ReadWrite'

  // Size of the data disks in GB.
  dataDiskSizeGB: 64

  // Number of data disks to attach to the VM.
  dataDiskCount: 1

  // The performancePlus flag can only be set on disks at least 512 GB in size.
  isEnablePerformancePlus: false

  // Bursting is supported only for 'Premium_LRS, Premium_ZRS' SKUs
  isEnabledBursting: false
}

var diskSuffixRange = range(0, diskConfig.dataDiskCount)

// Resource declarations

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${prefix}-nsg'
  location: location
  properties: {
    securityRules: []
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

resource dataDisk 'Microsoft.Compute/disks@2024-03-02' = [for i in diskSuffixRange: {
  name: '${vmName}-datadisk${padLeft(i + 1, 2, '0')}'
  location: location
  zones: [ zone ]
  sku: {
    name: diskConfig.dataDiskSku
  }
  properties: {
    diskSizeGB: diskConfig.dataDiskSizeGB
    creationData: {
      createOption: 'Empty'
      performancePlus: diskConfig.isEnablePerformancePlus
    }
    osType: 'Windows'
    burstingEnabled: diskConfig.isEnabledBursting
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  zones: [ zone ]
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
      dataDisks: [for i in diskSuffixRange: {
        lun: i
        createOption: 'Attach'
        caching: diskConfig.hostCaching
        managedDisk: {
          id: dataDisk[i].id
        }
      }]
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
