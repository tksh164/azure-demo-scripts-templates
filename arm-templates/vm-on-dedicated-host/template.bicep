param hostId string

param location string

param virtualMachineSize string

param subnetId string

param vmNamePrefix string

@minValue(1)
param vmCount int

param adminUsername string

// $env:SSH_PUB_KEY = Get-Content -Raw -LiteralPath 'path-to-ssh-public-key-file'
@secure()
param adminPublicKey string

var vmNames = [for index in range(0, vmCount): '${vmNamePrefix}${index + 1}']

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2023-06-01' = [for index in range(0, vmCount): {
  name: '${vmNames[index]}-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = [for index in range(0, vmCount): {
  name: '${vmNames[index]}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress[index].id
            properties: {
              deleteOption: 'Delete'
            }
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2025-11-01' = [for index in range(0, vmCount): {
  name: vmNames[index]
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface[index].id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      securityType: 'Standard'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    host: {
      id: hostId
    }
    osProfile: {
      computerName: vmNames[index]
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
        patchSettings: {
          assessmentMode: 'ImageDefault'
          patchMode: 'ImageDefault'
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

output adminUsername string = adminUsername
