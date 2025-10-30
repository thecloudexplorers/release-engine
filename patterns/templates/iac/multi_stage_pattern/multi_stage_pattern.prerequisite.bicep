metadata resources = {
  version: '0.1.0'
  author: 'Wesley Camargo'
  company: 'The Cloud Explorers'
  description: 'Deploys a resource group and a storage account.'
}

targetScope = 'subscription'

param tags object

@description('Name of the target resource group')
param resourceGroupName string = 'example-storage-rg'

@description('Name of the storage account')
// Creates unique deployment names to avoid conflicts
var deploymentNames = {
  resourceGroup: 'resourceGroupName${uniqueString(resourceGroupName, deployment().name)}'
}

// Check for Azure Verified Modules (AVM) availability
module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: deploymentNames.resourceGroup
  params: {
    name: resourceGroupName
    tags: tags
  }
}

output resourceGroupId string = resourceGroup.outputs.resourceId
