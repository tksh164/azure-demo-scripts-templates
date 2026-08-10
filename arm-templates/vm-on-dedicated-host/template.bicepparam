using './template.bicep'

param hostId = 'resource-id-of-dedicated-host'
param location = 'japaneast'
param virtualMachineSize = 'Standard_D8ds_v5'
param subnetId = 'resource-id-of-subnet-to-deploy-vms'
param vmNamePrefix = 'dhvm1'
param vmCount = 2
param adminUsername = 'vmadmin'
param adminPublicKey = readEnvironmentVariable('SSH_PUB_KEY')
