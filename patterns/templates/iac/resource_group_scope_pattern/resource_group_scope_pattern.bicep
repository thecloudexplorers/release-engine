metadata resources = {
  version: '0.1.0'
  author: 'Wesley Camargo'
  company: 'The Cloud Explorers'
  description: 'Deploys a storage account.'
}

@allowed([
  'westeurope'
  'uksouth'
])
@description('Region in which the resources should be deployed')
param resourceLocation string

@description('Name of the storage account')
param storageAccountName string

// Creates unique deployment names to avoid conflicts
var deploymentNames = {
  storageAccount: 'storageAccountName${uniqueString(storageAccountName, deployment().name)}'
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.27.1' = {
  name: deploymentNames.storageAccount
  params: {
    name: storageAccountName
    location: resourceLocation
  }
}

output storageAccountId string = storageAccount.outputs.resourceId
