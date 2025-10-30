metadata resources = {
  version: '0.1.0'
  author: 'Wesley Camargo'
  company: 'The Cloud Explorers'
  description: 'Deploys a resource group and a storage account.'
}

targetScope = 'subscription'

@allowed([
  'westeurope'
  'uksouth'
])
@description('Region in which the resources should be deployed')
param resourceLocation string

param tags object

@description('Name of the target resource group')
param resourceGroupName string = 'example-storage-rg'

@description('Name of the storage account')
param storageAccountName string

// Creates unique deployment names to avoid conflicts
var deploymentNames = {
  resourceGroup: 'resourceGroupName${uniqueString(resourceGroupName, deployment().name)}'
  storageAccount: 'storageAccountName${uniqueString(storageAccountName, deployment().name)}'
}

// Check for Azure Verified Modules (AVM) availability
module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: deploymentNames.resourceGroup
  params: {
    name: resourceGroupName
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.27.1' = {
  name: deploymentNames.storageAccount
  scope: az.resourceGroup(resourceGroupName)
  dependsOn: [
    resourceGroup
  ]
  params: {
    name: storageAccountName
    location: resourceLocation
  }
}

output resourceGroupId string = resourceGroup.outputs.resourceId
output storageAccountId string = storageAccount.outputs.resourceId
