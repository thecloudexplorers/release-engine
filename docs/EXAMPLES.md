# Examples Guide

This guide provides practical, real-world examples of using the Release Engine for various deployment scenarios.

## Table of Contents

- [Basic Examples](#basic-examples)
- [Infrastructure-Only Deployments](#infrastructure-only-deployments)
- [Application Deployments](#application-deployments)
- [Multi-Environment Scenarios](#multi-environment-scenarios)
- [Advanced Patterns](#advanced-patterns)
- [Real-World Use Cases](#real-world-use-cases)
- [Configuration Examples](#configuration-examples)

## Basic Examples

### Example 1: Simple Infrastructure Deployment

Deploy a basic Azure resource group with storage account:

**Project Structure:**
```
my-simple-project/
├── azure-pipelines.yml
├── config/
│   └── dev/
│       ├── metadata.jsonc
│       └── parameters.json
└── infrastructure/
    └── main.bicep
```

**azure-pipelines.yml:**
```yaml
name: Simple Infrastructure Deployment

trigger:
  branches:
    include:
    - main
  paths:
    include:
    - infrastructure/*
    - config/*

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'simple-storage'
- group: 'release-engine-dev'

stages:
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)

- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)
    environment: 'dev'
    serviceConnection: 'azure-connection-dev'
    dependsOn: 'Build'
```

**config/dev/metadata.jsonc:**
```jsonc
{
  "environment": "dev",
  "location": "East US 2",
  "resourceGroupName": "rg-simple-storage-dev",
  "storageAccountName": "stsimplestoragedev",
  "tags": {
    "Environment": "Development",
    "Project": "SimpleStorage",
    "Owner": "DevTeam"
  }
}
```

**infrastructure/main.bicep:**
```bicep
@description('Environment name')
param environment string

@description('Resource group name')
param resourceGroupName string

@description('Storage account name')
param storageAccountName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
```

### Example 2: Multi-Stage Pipeline with Approvals

Deploy to multiple environments with approval gates:

**azure-pipelines.yml:**
```yaml
name: Multi-Stage Deployment

trigger:
- main

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'web-application'

stages:
# Build stage
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)

# Deploy to Development
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)
    environment: 'dev'
    serviceConnection: 'azure-connection-dev'
    dependsOn: 'Build'

# Deploy to Test (automatic after dev success)
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)
    environment: 'test'
    serviceConnection: 'azure-connection-test'
    dependsOn: 'DeployDev'

# Deploy to Production (requires approval)
- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: 'DeployTest'
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: ProductionDeployment
    environment: 'production'  # This environment has approval requirements
    strategy:
      runOnce:
        deploy:
          steps:
          - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
            parameters:
              workload: $(workloadName)
              environment: 'prod'
              serviceConnection: 'azure-connection-prod'
```

## Infrastructure-Only Deployments

### Example 3: Azure Landing Zone Components

Deploy Azure Landing Zone infrastructure components:

**Project Structure:**
```
azure-landing-zone/
├── azure-pipelines.yml
├── config/
│   ├── dev/
│   ├── test/
│   └── prod/
├── infrastructure/
│   ├── main.bicep
│   ├── modules/
│   │   ├── networking.bicep
│   │   ├── security.bicep
│   │   └── monitoring.bicep
│   └── scripts/
│       └── post-deployment.ps1
└── tests/
    └── infrastructure.tests.ps1
```

**azure-pipelines.yml:**
```yaml
name: Azure Landing Zone Deployment

parameters:
- name: environment
  displayName: 'Target Environment'
  type: string
  default: 'dev'
  values:
  - 'dev'
  - 'test'
  - 'prod'

- name: deployComponents
  displayName: 'Components to Deploy'
  type: object
  default:
    networking: true
    security: true
    monitoring: true
    governance: false

trigger: none  # Manual deployment only

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'azure-landing-zone'
- group: 'release-engine-${{ parameters.environment }}'

stages:
# Validation stage
- stage: Validate
  displayName: 'Validate Infrastructure'
  jobs:
  - job: ValidateBicep
    displayName: 'Validate Bicep Templates'
    steps:
    - task: AzureCLI@2
      displayName: 'Validate Main Template'
      inputs:
        azureSubscription: 'azure-connection-${{ parameters.environment }}'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az bicep build --file infrastructure/main.bicep --validate-only
          
  - job: RunTests
    displayName: 'Run Infrastructure Tests'
    steps:
    - task: PowerShell@2
      displayName: 'Run Pester Tests'
      inputs:
        targetType: 'inline'
        script: |
          Install-Module -Name Pester -Force -Scope CurrentUser
          Invoke-Pester tests/infrastructure.tests.ps1 -Output Detailed

# Build stage
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)
    dependsOn: 'Validate'

# Deploy stage
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)
    environment: '${{ parameters.environment }}'
    serviceConnection: 'azure-connection-${{ parameters.environment }}'
    customParameters:
      deployNetworking: ${{ parameters.deployComponents.networking }}
      deploySecurity: ${{ parameters.deployComponents.security }}
      deployMonitoring: ${{ parameters.deployComponents.monitoring }}
    dependsOn: 'Build'
```

**config/prod/metadata.jsonc:**
```jsonc
{
  "environment": "prod",
  "location": "East US 2",
  "locationShort": "eus2",
  "subscriptionId": "12345678-1234-1234-1234-123456789012",
  
  // Networking Configuration
  "hubVnetName": "vnet-hub-prod-eus2",
  "hubVnetAddressSpace": "10.0.0.0/16",
  "spokeVnetAddressSpaces": [
    "10.1.0.0/16",
    "10.2.0.0/16"
  ],
  
  // Security Configuration
  "keyVaultName": "kv-alz-prod-eus2",
  "logAnalyticsWorkspaceName": "law-alz-prod-eus2",
  
  // Governance
  "policyDefinitions": [
    "require-tags",
    "allowed-locations",
    "require-encryption"
  ],
  
  // Tags
  "tags": {
    "Environment": "Production",
    "Project": "AzureLandingZone",
    "CostCenter": "IT-Infrastructure",
    "BusinessUnit": "Corporate",
    "Owner": "CloudTeam"
  }
}
```

### Example 4: Database Infrastructure with Backup

Deploy SQL Database with automated backup configuration:

**infrastructure/database.bicep:**
```bicep
@description('Environment name')
param environment string

@description('SQL Server administrator login')
@secure()
param sqlAdminUsername string

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

@description('Database name')
param databaseName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: 'sql-${databaseName}-${environment}'
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'S2' : 'S1'
    tier: 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: environment == 'prod' ? 268435456000 : 53687091200 // 250GB prod, 50GB non-prod
    readScale: environment == 'prod' ? 'Enabled' : 'Disabled'
  }
}

// Backup configuration
resource backupPolicy 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2021-11-01' = if (environment == 'prod') {
  parent: sqlDatabase
  name: 'default'
  properties: {
    weeklyRetention: 'P12W'
    monthlyRetention: 'P12M'
    yearlyRetention: 'P5Y'
    weekOfYear: 1
  }
}

output sqlServerName string = sqlServer.name
output databaseName string = sqlDatabase.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
```

## Application Deployments

### Example 5: .NET Web Application with Infrastructure

Deploy a complete .NET application with supporting infrastructure:

**Project Structure:**
```
dotnet-web-app/
├── azure-pipelines.yml
├── src/
│   ├── WebApp/
│   │   ├── WebApp.csproj
│   │   └── Program.cs
│   └── WebApp.Tests/
├── infrastructure/
│   ├── main.bicep
│   └── modules/
│       ├── app-service.bicep
│       └── application-insights.bicep
└── config/
    ├── dev/
    ├── test/
    └── prod/
```

**azure-pipelines.yml:**
```yaml
name: .NET Web Application Deployment

trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - src/*
    - infrastructure/*
    - config/*

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'dotnet-webapp'
- name: buildConfiguration
  value: 'Release'

stages:
# Build Application
- stage: BuildApplication
  displayName: 'Build .NET Application'
  jobs:
  - job: BuildApp
    displayName: 'Build and Test Application'
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: UseDotNet@2
      displayName: 'Use .NET 6.0'
      inputs:
        packageType: 'sdk'
        version: '6.0.x'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore packages'
      inputs:
        command: 'restore'
        projects: 'src/**/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build application'
      inputs:
        command: 'build'
        projects: 'src/**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run unit tests'
      inputs:
        command: 'test'
        projects: 'src/**/*Tests*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-build --logger trx --collect:"XPlat Code Coverage"'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)/app'
    
    - publish: '$(Build.ArtifactStagingDirectory)/app'
      artifact: 'webapp'
      displayName: 'Publish web app artifact'

# Build Infrastructure
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)

# Deploy to Development
- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: 
  - BuildApplication
  - Build
  condition: succeeded()
  variables:
  - group: 'release-engine-dev'
  jobs:
  # Deploy infrastructure
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: $(workloadName)
      environment: 'dev'
      serviceConnection: 'azure-connection-dev'
  
  # Deploy application
  - deployment: DeployWebApp
    displayName: 'Deploy Web Application'
    dependsOn: DeployInfrastructure
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: 'webapp'
          
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure Web App'
            inputs:
              azureSubscription: 'azure-connection-dev'
              appType: 'webApp'
              appName: 'app-$(workloadName)-dev'
              package: '$(Pipeline.Workspace)/webapp/**/*.zip'
              deploymentMethod: 'auto'

# Deploy to Production
- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: DeployDev
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  variables:
  - group: 'release-engine-prod'
  jobs:
  # Deploy infrastructure
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: $(workloadName)
      environment: 'prod'
      serviceConnection: 'azure-connection-prod'
  
  # Deploy application with approval
  - deployment: DeployWebAppProd
    displayName: 'Deploy Web Application to Production'
    dependsOn: DeployInfrastructure
    environment: 'production'  # Requires manual approval
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: 'webapp'
          
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure Web App'
            inputs:
              azureSubscription: 'azure-connection-prod'
              appType: 'webApp'
              appName: 'app-$(workloadName)-prod'
              package: '$(Pipeline.Workspace)/webapp/**/*.zip'
              deploymentMethod: 'auto'
          
          - task: PowerShell@2
            displayName: 'Run Health Check'
            inputs:
              targetType: 'inline'
              script: |
                $appUrl = "https://app-$(workloadName)-prod.azurewebsites.net/health"
                $response = Invoke-WebRequest -Uri $appUrl -UseBasicParsing
                if ($response.StatusCode -ne 200) {
                    throw "Health check failed with status code: $($response.StatusCode)"
                }
                Write-Host "Health check passed successfully"
```

## Multi-Environment Scenarios

### Example 6: Environment-Specific Configuration

Handle different configurations across environments:

**config/dev/metadata.jsonc:**
```jsonc
{
  "environment": "dev",
  "location": "East US 2",
  "appServicePlan": {
    "sku": "B1",
    "instanceCount": 1
  },
  "database": {
    "sku": "Basic",
    "maxSizeGB": 2
  },
  "monitoring": {
    "enabled": true,
    "logRetentionDays": 30
  },
  "features": {
    "enableAuth": false,
    "enableCache": false,
    "debugMode": true
  }
}
```

**config/prod/metadata.jsonc:**
```jsonc
{
  "environment": "prod",
  "location": "East US 2",
  "appServicePlan": {
    "sku": "P2v2",
    "instanceCount": 3
  },
  "database": {
    "sku": "S2",
    "maxSizeGB": 250
  },
  "monitoring": {
    "enabled": true,
    "logRetentionDays": 365
  },
  "features": {
    "enableAuth": true,
    "enableCache": true,
    "debugMode": false
  }
}
```

### Example 7: Blue-Green Deployment Pattern

Implement blue-green deployment for zero-downtime updates:

**azure-pipelines-bluegreen.yml:**
```yaml
name: Blue-Green Deployment

parameters:
- name: targetSlot
  displayName: 'Target Deployment Slot'
  type: string
  default: 'blue'
  values:
  - 'blue'
  - 'green'

- name: swapSlots
  displayName: 'Swap slots after deployment'
  type: boolean
  default: false

trigger: none  # Manual deployment

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'bluegreen-app'
- group: 'release-engine-prod'

stages:
# Build Application
- stage: Build
  jobs:
  - job: BuildApp
    steps:
    # Build steps here
    - script: echo "Building application..."

# Deploy to Target Slot
- stage: DeployToSlot
  displayName: 'Deploy to ${{ parameters.targetSlot }} Slot'
  dependsOn: Build
  jobs:
  - job: DeployApplication
    steps:
    - task: AzureWebApp@1
      displayName: 'Deploy to ${{ parameters.targetSlot }} slot'
      inputs:
        azureSubscription: 'azure-connection-prod'
        appType: 'webApp'
        appName: 'app-$(workloadName)-prod'
        package: '$(Pipeline.Workspace)/drop/**/*.zip'
        deployToSlotOrASE: true
        slotName: '${{ parameters.targetSlot }}'

# Validation
- stage: ValidateSlot
  displayName: 'Validate ${{ parameters.targetSlot }} Slot'
  dependsOn: DeployToSlot
  jobs:
  - job: RunHealthChecks
    steps:
    - task: PowerShell@2
      displayName: 'Health Check'
      inputs:
        targetType: 'inline'
        script: |
          $slotUrl = "https://app-$(workloadName)-prod-${{ parameters.targetSlot }}.azurewebsites.net"
          Write-Host "Testing $slotUrl"
          
          # Run health checks
          $healthCheck = Invoke-WebRequest -Uri "$slotUrl/health" -UseBasicParsing
          if ($healthCheck.StatusCode -ne 200) {
              throw "Health check failed"
          }
          
          # Run performance tests
          for ($i = 1; $i -le 10; $i++) {
              $response = Invoke-WebRequest -Uri $slotUrl -UseBasicParsing
              Write-Host "Request $i: $($response.StatusCode) - $($response.ResponseTime)ms"
          }

# Swap Slots (Conditional)
- stage: SwapSlots
  displayName: 'Swap Production Slots'
  dependsOn: ValidateSlot
  condition: and(succeeded(), eq('${{ parameters.swapSlots }}', 'true'))
  jobs:
  - deployment: SwapToProduction
    environment: 'production-swap'  # Requires approval
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureAppServiceManage@0
            displayName: 'Swap Slots'
            inputs:
              azureSubscription: 'azure-connection-prod'
              action: 'Swap Slots'
              webAppName: 'app-$(workloadName)-prod'
              sourceSlot: '${{ parameters.targetSlot }}'
              targetSlot: 'production'
          
          - task: PowerShell@2
            displayName: 'Post-Swap Validation'
            inputs:
              targetType: 'inline'
              script: |
                Start-Sleep -Seconds 30  # Wait for swap to complete
                $prodUrl = "https://app-$(workloadName)-prod.azurewebsites.net"
                $response = Invoke-WebRequest -Uri "$prodUrl/health" -UseBasicParsing
                if ($response.StatusCode -ne 200) {
                    throw "Post-swap health check failed"
                }
                Write-Host "Swap completed successfully"
```

## Advanced Patterns

### Example 8: Multi-Region Deployment

Deploy to multiple Azure regions for high availability:

**azure-pipelines-multiregion.yml:**
```yaml
name: Multi-Region Deployment

parameters:
- name: regions
  displayName: 'Target Regions'
  type: object
  default:
  - name: 'primary'
    location: 'East US 2'
    locationShort: 'eus2'
  - name: 'secondary'
    location: 'West US 2'
    locationShort: 'wus2'

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'multiregion-app'

stages:
# Build once
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: $(workloadName)

# Deploy to each region
- ${{ each region in parameters.regions }}:
  - stage: Deploy${{ region.name }}
    displayName: 'Deploy to ${{ region.location }}'
    dependsOn: Build
    variables:
    - group: 'release-engine-prod-${{ region.locationShort }}'
    - name: currentRegion
      value: '${{ region.name }}'
    jobs:
    - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
      parameters:
        workload: $(workloadName)
        environment: 'prod'
        region: '${{ region.name }}'
        serviceConnection: 'azure-connection-prod-${{ region.locationShort }}'
        customParameters:
          location: '${{ region.location }}'
          regionCode: '${{ region.locationShort }}'
          isPrimary: ${{ eq(region.name, 'primary') }}

# Configure Traffic Manager
- stage: ConfigureTrafficManager
  displayName: 'Configure Traffic Manager'
  dependsOn: 
  - DeployPrimary
  - DeploySecondary
  jobs:
  - job: SetupTrafficManager
    steps:
    - task: AzureCLI@2
      displayName: 'Configure Traffic Manager'
      inputs:
        azureSubscription: 'azure-connection-prod'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Create Traffic Manager profile
          az network traffic-manager profile create \
            --name "tm-$(workloadName)-prod" \
            --resource-group "rg-$(workloadName)-prod-eus2" \
            --routing-method Priority \
            --unique-dns-name "$(workloadName)-prod"
          
          # Add primary endpoint
          az network traffic-manager endpoint create \
            --name "primary-endpoint" \
            --profile-name "tm-$(workloadName)-prod" \
            --resource-group "rg-$(workloadName)-prod-eus2" \
            --type azureEndpoints \
            --target-resource-id "/subscriptions/$(subscriptionId)/resourceGroups/rg-$(workloadName)-prod-eus2/providers/Microsoft.Web/sites/app-$(workloadName)-prod-eus2" \
            --priority 1
          
          # Add secondary endpoint
          az network traffic-manager endpoint create \
            --name "secondary-endpoint" \
            --profile-name "tm-$(workloadName)-prod" \
            --resource-group "rg-$(workloadName)-prod-eus2" \
            --type azureEndpoints \
            --target-resource-id "/subscriptions/$(subscriptionId)/resourceGroups/rg-$(workloadName)-prod-wus2/providers/Microsoft.Web/sites/app-$(workloadName)-prod-wus2" \
            --priority 2
```

### Example 9: Microservices Deployment

Deploy multiple microservices with dependencies:

**microservices-pipeline.yml:**
```yaml
name: Microservices Deployment

trigger:
  branches:
    include:
    - main
  paths:
    include:
    - services/*/
    - infrastructure/
    - config/

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: servicesChanged
  value: $[countChanged('services/')]
- group: 'release-engine-dev'

stages:
# Build all services
- stage: BuildServices
  displayName: 'Build Microservices'
  jobs:
  - job: DetectChanges
    displayName: 'Detect Changed Services'
    steps:
    - task: PowerShell@2
      displayName: 'Detect changes'
      inputs:
        targetType: 'inline'
        script: |
          $changedFiles = git diff --name-only HEAD~1 HEAD
          $changedServices = @()
          
          foreach ($file in $changedFiles) {
              if ($file -match '^services/([^/]+)/') {
                  $service = $matches[1]
                  if ($changedServices -notcontains $service) {
                      $changedServices += $service
                  }
              }
          }
          
          Write-Host "Changed services: $($changedServices -join ', ')"
          Write-Host "##vso[task.setvariable variable=changedServices;isOutput=true]$($changedServices -join ',')"
    name: 'detectChanges'
  
  - job: BuildUserService
    condition: or(contains(dependencies.DetectChanges.outputs['detectChanges.changedServices'], 'user-service'), eq(variables['Build.Reason'], 'Manual'))
    dependsOn: DetectChanges
    steps:
    - template: build-service-template.yml
      parameters:
        serviceName: 'user-service'
        servicePort: 3001
  
  - job: BuildOrderService
    condition: or(contains(dependencies.DetectChanges.outputs['detectChanges.changedServices'], 'order-service'), eq(variables['Build.Reason'], 'Manual'))
    dependsOn: DetectChanges
    steps:
    - template: build-service-template.yml
      parameters:
        serviceName: 'order-service'
        servicePort: 3002
  
  - job: BuildNotificationService
    condition: or(contains(dependencies.DetectChanges.outputs['detectChanges.changedServices'], 'notification-service'), eq(variables['Build.Reason'], 'Manual'))
    dependsOn: DetectChanges
    steps:
    - template: build-service-template.yml
      parameters:
        serviceName: 'notification-service'
        servicePort: 3003

# Build shared infrastructure
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: 'microservices-platform'

# Deploy infrastructure first
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: 'microservices-platform'
    environment: 'dev'
    serviceConnection: 'azure-connection-dev'
    dependsOn: 
    - BuildServices
    - Build

# Deploy services in dependency order
- stage: DeployCoreServices
  displayName: 'Deploy Core Services'
  dependsOn: DeployInfrastructure
  jobs:
  # Deploy user service first (no dependencies)
  - deployment: DeployUserService
    environment: 'microservices-dev'
    strategy:
      runOnce:
        deploy:
          steps:
          - template: deploy-service-template.yml
            parameters:
              serviceName: 'user-service'
              environment: 'dev'

- stage: DeployDependentServices
  displayName: 'Deploy Dependent Services'
  dependsOn: DeployCoreServices
  jobs:
  # Deploy order service (depends on user service)
  - deployment: DeployOrderService
    environment: 'microservices-dev'
    strategy:
      runOnce:
        deploy:
          steps:
          - template: deploy-service-template.yml
            parameters:
              serviceName: 'order-service'
              environment: 'dev'
              dependencies:
              - 'user-service'
  
  # Deploy notification service (depends on order service)
  - deployment: DeployNotificationService
    environment: 'microservices-dev'
    dependsOn: DeployOrderService
    strategy:
      runOnce:
        deploy:
          steps:
          - template: deploy-service-template.yml
            parameters:
              serviceName: 'notification-service'
              environment: 'dev'
              dependencies:
              - 'order-service'
              - 'user-service'

# Integration tests
- stage: IntegrationTests
  displayName: 'Run Integration Tests'
  dependsOn: DeployDependentServices
  jobs:
  - job: RunTests
    steps:
    - task: PowerShell@2
      displayName: 'Run API Tests'
      inputs:
        targetType: 'filePath'
        filePath: 'tests/integration/run-tests.ps1'
        arguments: '-Environment dev -BaseUrl "https://api-microservices-dev.azurewebsites.net"'
```

## Real-World Use Cases

### Example 10: Enterprise Data Platform

Deploy a complete data platform with multiple components:

**data-platform-pipeline.yml:**
```yaml
name: Enterprise Data Platform

parameters:
- name: deploymentScope
  displayName: 'Deployment Scope'
  type: string
  default: 'full'
  values:
  - 'infrastructure'
  - 'data-factory'
  - 'databricks'
  - 'full'

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- name: workloadName
  value: 'enterprise-data-platform'
- group: 'release-engine-prod'

stages:
# Build all components
- stage: BuildPlatform
  displayName: 'Build Data Platform'
  jobs:
  - template: common/pipelines/03-jobs/iac.build.job.yml@releaseEngine
    parameters:
      workload: $(workloadName)

# Deploy core infrastructure
- stage: DeployInfrastructure
  displayName: 'Deploy Core Infrastructure'
  condition: or(eq('${{ parameters.deploymentScope }}', 'infrastructure'), eq('${{ parameters.deploymentScope }}', 'full'))
  dependsOn: BuildPlatform
  jobs:
  - job: DeployDataLake
    displayName: 'Deploy Data Lake'
    steps:
    - task: AzureCLI@2
      displayName: 'Deploy Storage Account'
      inputs:
        azureSubscription: 'azure-connection-prod'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az deployment group create \
            --resource-group "rg-$(workloadName)-prod" \
            --template-file infrastructure/data-lake.bicep \
            --parameters @config/prod/data-lake.parameters.json
  
  - job: DeploySQLDatabase
    displayName: 'Deploy SQL Database'
    steps:
    - task: AzureCLI@2
      displayName: 'Deploy SQL Server and Database'
      inputs:
        azureSubscription: 'azure-connection-prod'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az deployment group create \
            --resource-group "rg-$(workloadName)-prod" \
            --template-file infrastructure/sql-database.bicep \
            --parameters @config/prod/sql-database.parameters.json

# Deploy Data Factory
- stage: DeployDataFactory
  displayName: 'Deploy Azure Data Factory'
  condition: or(eq('${{ parameters.deploymentScope }}', 'data-factory'), eq('${{ parameters.deploymentScope }}', 'full'))
  dependsOn: DeployInfrastructure
  jobs:
  - job: DeployADF
    displayName: 'Deploy Data Factory'
    steps:
    - task: AzureCLI@2
      displayName: 'Deploy Data Factory'
      inputs:
        azureSubscription: 'azure-connection-prod'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az deployment group create \
            --resource-group "rg-$(workloadName)-prod" \
            --template-file infrastructure/data-factory.bicep \
            --parameters @config/prod/data-factory.parameters.json
    
    - task: PowerShell@2
      displayName: 'Deploy Data Factory Pipelines'
      inputs:
        targetType: 'filePath'
        filePath: 'scripts/deploy-adf-pipelines.ps1'
        arguments: >
          -ResourceGroupName "rg-$(workloadName)-prod"
          -DataFactoryName "adf-$(workloadName)-prod"
          -PipelinesPath "data-factory/pipelines"

# Deploy Databricks
- stage: DeployDatabricks
  displayName: 'Deploy Azure Databricks'
  condition: or(eq('${{ parameters.deploymentScope }}', 'databricks'), eq('${{ parameters.deploymentScope }}', 'full'))
  dependsOn: DeployInfrastructure
  jobs:
  - job: DeployDatabricksWorkspace
    displayName: 'Deploy Databricks Workspace'
    steps:
    - task: AzureCLI@2
      displayName: 'Deploy Databricks'
      inputs:
        azureSubscription: 'azure-connection-prod'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az deployment group create \
            --resource-group "rg-$(workloadName)-prod" \
            --template-file infrastructure/databricks.bicep \
            --parameters @config/prod/databricks.parameters.json
    
    - task: PowerShell@2
      displayName: 'Configure Databricks Notebooks'
      inputs:
        targetType: 'filePath'
        filePath: 'scripts/deploy-databricks-notebooks.ps1'
        arguments: >
          -WorkspaceUrl "https://adb-$(workloadId).$(databricksRegionId).azuredatabricks.net"
          -NotebooksPath "databricks/notebooks"

# Data Quality Tests
- stage: DataQualityTests
  displayName: 'Run Data Quality Tests'
  dependsOn: 
  - DeployDataFactory
  - DeployDatabricks
  condition: eq('${{ parameters.deploymentScope }}', 'full')
  jobs:
  - job: RunDataTests
    displayName: 'Execute Data Quality Tests'
    steps:
    - task: PowerShell@2
      displayName: 'Run Data Validation'
      inputs:
        targetType: 'filePath'
        filePath: 'tests/data-quality/run-validation.ps1'
        arguments: >
          -Environment "prod"
          -DataLakeConnection "$(dataLakeConnectionString)"
          -SqlConnection "$(sqlConnectionString)"
```

## Configuration Examples

### Example 11: Complex Configuration with Token Replacement

Handle complex configurations with nested structures and environment-specific values:

**config/template/app-config.json:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "#{sqlConnectionString}#",
    "RedisConnection": "#{redisConnectionString}#",
    "StorageConnection": "#{storageConnectionString}#"
  },
  "AppSettings": {
    "Environment": "#{environment}#",
    "ApiBaseUrl": "https://#{apiDomain}#/api/v1",
    "Features": {
      "EnableAuth": #{enableAuthentication}#,
      "EnableCache": #{enableCaching}#,
      "EnableLogging": #{enableDetailedLogging}#,
      "MaxRetries": #{maxRetryAttempts}#
    },
    "ExternalServices": {
      "PaymentGateway": {
        "Url": "#{paymentGatewayUrl}#",
        "ApiKey": "#{paymentGatewayApiKey}#",
        "TimeoutSeconds": #{paymentTimeoutSeconds}#
      },
      "EmailService": {
        "SmtpServer": "#{smtpServer}#",
        "SmtpPort": #{smtpPort}#,
        "Username": "#{smtpUsername}#",
        "EnableSsl": #{enableSmtpSsl}#
      }
    },
    "Monitoring": {
      "ApplicationInsights": {
        "InstrumentationKey": "#{appInsightsKey}#",
        "EnableTelemetry": #{enableTelemetry}#
      },
      "HealthChecks": {
        "Enabled": #{enableHealthChecks}#,
        "Endpoints": [
          "#{healthCheckEndpoint1}#",
          "#{healthCheckEndpoint2}#"
        ]
      }
    }
  }
}
```

**config/dev/metadata.jsonc:**
```jsonc
{
  // Environment
  "environment": "dev",
  "apiDomain": "api-myapp-dev.azurewebsites.net",
  
  // Connection Strings
  "sqlConnectionString": "Server=sql-myapp-dev.database.windows.net;Database=myapp-dev;Authentication=Active Directory Default;",
  "redisConnectionString": "redis-myapp-dev.redis.cache.windows.net:6380,password=dev-password,ssl=True,abortConnect=False",
  "storageConnectionString": "DefaultEndpointsProtocol=https;AccountName=stmyappdev;AccountKey=dev-key;EndpointSuffix=core.windows.net",
  
  // Feature Flags
  "enableAuthentication": false,
  "enableCaching": true,
  "enableDetailedLogging": true,
  "maxRetryAttempts": 3,
  
  // External Services
  "paymentGatewayUrl": "https://sandbox.payment.com",
  "paymentGatewayApiKey": "sandbox-key-123",
  "paymentTimeoutSeconds": 30,
  
  // Email Configuration
  "smtpServer": "smtp.office365.com",
  "smtpPort": 587,
  "smtpUsername": "noreply-dev@company.com",
  "enableSmtpSsl": true,
  
  // Monitoring
  "appInsightsKey": "dev-app-insights-key",
  "enableTelemetry": true,
  "enableHealthChecks": true,
  "healthCheckEndpoint1": "/health/database",
  "healthCheckEndpoint2": "/health/cache"
}
```

**Pipeline configuration replacement:**
```yaml
- task: PowerShell@2
  displayName: 'Replace Configuration Tokens'
  inputs:
    targetType: 'filePath'
    filePath: '$(System.DefaultWorkingDirectory)/common/scripts/Replace-ConfigurationFilesTokens.ps1'
    arguments: >
      -ConfigFilesRootFolder "$(System.DefaultWorkingDirectory)/config"
      -CustomOutputFolderPath "$(Build.ArtifactStagingDirectory)/config"
      -StartTokenPattern "#{" 
      -EndTokenPattern "}#"
      -ExtractTokenValueFromConfigFileName
      -PrefixForConfigFileNameWithTokenValue "env-"
      -TargetTokenNameForTokenValueFromConfigFileName "environment"
```

These examples demonstrate the flexibility and power of the Release Engine for various deployment scenarios. Each example can be adapted and combined to meet specific requirements in your organization.

For more detailed information about implementing these patterns, refer to:
- [Setup Guide](SETUP.md) for initial configuration
- [Usage Guide](USAGE.md) for detailed pipeline documentation
- [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues
- [Contributing Guide](CONTRIBUTING.md) for extending these examples