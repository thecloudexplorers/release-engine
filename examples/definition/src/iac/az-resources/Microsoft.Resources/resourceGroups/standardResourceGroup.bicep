// scope must be set to subscription to allow for the creation of a resource group
targetScope = 'subscription'

@description('Name of the target resource group ')
param resourceGroupName string

@allowed([
  'westeurope'
])
@description('Region in which the workload should be deployed')
param resourceLocation string

param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceLocation
  tags: tags
}
