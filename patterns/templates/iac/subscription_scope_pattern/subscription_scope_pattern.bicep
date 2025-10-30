metadata resources = {
  version: '0.1.0'
  author: 'Wesley Camargo'
  company: 'The Cloud Explorers'
  description: 'Creates a resource group.'
}

// scope must be set to subscription to allow for the creation of a resource group
targetScope = 'subscription'

param tags object

@description('Name of the target resource group ')
param resourceGroupName string = 'example-avm-rg'

// Creates unique deployment names to avoid conflicts
var deploymentNames = {
  resourceGroup: 'resourceGroupName${uniqueString(resourceGroupName, deployment().name)}'
}

module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: deploymentNames.resourceGroup
  params: {
    name: resourceGroupName
    tags: tags
  }
}

output resourceGroupId string = resourceGroup.outputs.resourceId
