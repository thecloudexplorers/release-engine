# Usage Guide

This guide provides comprehensive instructions on how to use the Release Engine for various deployment scenarios.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Pipeline Integration](#pipeline-integration)
- [Configuration Management](#configuration-management)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Application Deployment](#application-deployment)
- [Multi-Environment Workflows](#multi-environment-workflows)
- [Advanced Scenarios](#advanced-scenarios)
- [Best Practices](#best-practices)

## Basic Usage

### Using Pipeline Templates

The Release Engine provides several levels of pipeline templates:

#### 1. Orchestrator Level (Recommended)
Use for complete workflow orchestration:

```yaml
# azure-pipelines.yml
resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- group: 'release-engine-$(Build.SourceBranchName)'

stages:
- template: common/pipelines/01-orchestrators/alz.devops.workload.orchestrator.yml@releaseEngine
  parameters:
    workload: 'my-application'
    environments:
    - name: 'dev'
      serviceConnection: 'azure-connection-dev'
    - name: 'prod'
      serviceConnection: 'azure-connection-prod'
      requiresApproval: true
```

#### 2. Stage Level
Use for specific deployment stages:

```yaml
stages:
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: 'my-infrastructure'
    environment: 'dev'

- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: 'my-infrastructure'
    environment: 'dev'
    serviceConnection: 'azure-connection-dev'
    dependsOn: 'Build'
```

#### 3. Job Level
Use for specific job implementations:

```yaml
jobs:
- template: common/pipelines/03-jobs/iac.build.job.yml@releaseEngine
  parameters:
    workload: 'my-workload'
    configurationPath: 'config/dev'
```

## Pipeline Integration

### Project Structure Setup

Organize your project to work effectively with Release Engine:

```
my-project/
├── azure-pipelines.yml          # Main pipeline definition
├── config/                      # Environment configurations
│   ├── dev/
│   │   ├── metadata.jsonc      # Environment-specific metadata
│   │   └── parameters.json     # Bicep parameters
│   ├── test/
│   └── prod/
├── infrastructure/              # Infrastructure as Code
│   ├── main.bicep              # Main Bicep template
│   ├── modules/                # Bicep modules
│   └── scripts/                # Deployment scripts
└── src/                        # Application source code
```

### Basic Pipeline Configuration

```yaml
# azure-pipelines.yml
name: $(BuildDefinitionName)-$(Date:yyyyMMdd)-$(Rev:r)

trigger:
  branches:
    include:
    - main
    - develop
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
  value: 'my-application'
- group: 'release-engine-common'

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

## Configuration Management

### Metadata Files

Create environment-specific metadata files:

```jsonc
// config/dev/metadata.jsonc
{
  // Environment identification
  "environment": "dev",
  "location": "East US 2",
  "locationShort": "eus2",
  
  // Resource naming
  "resourceGroupPrefix": "rg-myapp-dev",
  "storageAccountPrefix": "stmyappdev",
  "keyVaultPrefix": "kv-myapp-dev",
  
  // Networking
  "vnetAddressSpace": "10.0.0.0/16",
  "subnetAddressSpace": "10.0.1.0/24",
  
  // Tagging
  "tags": {
    "Environment": "Development",
    "Project": "MyApplication",
    "Owner": "DevTeam",
    "CostCenter": "IT",
    "CreatedBy": "ReleaseEngine"
  },
  
  // Feature flags
  "enableDiagnostics": true,
  "enableBackup": false,
  "enableMonitoring": true
}
```

### Token Replacement

The Release Engine uses a token replacement system for dynamic configuration:

#### Template File Example
```json
// config/template/app-settings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=#{serverName}#;Database=#{databaseName}#;"
  },
  "AppSettings": {
    "Environment": "#{environment}#",
    "ApiUrl": "https://#{apiDomain}#/api",
    "EnableFeatureX": #{enableFeatureX}#
  }
}
```

#### Using Token Replacement in Pipeline
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
```

## Infrastructure Deployment

### Basic Infrastructure Pipeline

```yaml
# For infrastructure-only deployments
stages:
- stage: ValidateInfrastructure
  jobs:
  - template: common/pipelines/03-jobs/iac.build.job.yml@releaseEngine
    parameters:
      workload: 'infrastructure'
      validateOnly: true

- stage: DeployDev
  dependsOn: ValidateInfrastructure
  condition: succeeded()
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'infrastructure'
      environment: 'dev'
      serviceConnection: 'azure-connection-dev'

- stage: DeployProd
  dependsOn: DeployDev
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'infrastructure'
      environment: 'prod'
      serviceConnection: 'azure-connection-prod'
      requireApproval: true
```

### Using Bicep Templates

Integrate your Bicep templates with the deployment scripts:

```bicep
// infrastructure/main.bicep
@description('Environment name')
param environment string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Application name')
param applicationName string

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'st${applicationName}${environment}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}
```

### Custom Deployment Scripts

Create custom deployment scripts when needed:

```powershell
# infrastructure/scripts/deploy-custom.ps1
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory)]
    [string]$Environment,
    
    [Parameter(Mandatory)]
    [string]$Location
)

# Use Release Engine utilities
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$deployBicepScript = Join-Path $scriptRoot "../../common/scripts/functions/deployBicep.ps1"
. $deployBicepScript

# Custom deployment logic
$bicepParams = @{
    BicepTemplateFilePath = "infrastructure/main.bicep"
    AzureLocation = $Location
    DeploymentKey = "custom-$(Get-Date -Format 'yyyyMMddHHmm')"
    CustomBicepParameters = @{
        environment = $Environment
        applicationName = "myapp"
    }
}

Deploy-BicepTemplate @bicepParams
```

## Application Deployment

### Application + Infrastructure Pipeline

```yaml
stages:
# Build application
- stage: BuildApplication
  jobs:
  - job: BuildApp
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Build Application'
      inputs:
        command: 'build'
        projects: 'src/**/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish Application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--output $(Build.ArtifactStagingDirectory)/app'
    
    - publish: '$(Build.ArtifactStagingDirectory)/app'
      artifact: 'application'

# Build infrastructure
- stage: BuildInfrastructure
  jobs:
  - template: common/pipelines/03-jobs/iac.build.job.yml@releaseEngine
    parameters:
      workload: 'application-infrastructure'

# Deploy to dev
- stage: DeployDev
  dependsOn: 
  - BuildApplication
  - BuildInfrastructure
  jobs:
  # Deploy infrastructure first
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'application-infrastructure'
      environment: 'dev'
      serviceConnection: 'azure-connection-dev'
  
  # Deploy application
  - job: DeployApplication
    dependsOn: DeployInfrastructure
    steps:
    - download: current
      artifact: 'application'
    
    - task: AzureWebApp@1
      inputs:
        azureSubscription: 'azure-connection-dev'
        appType: 'webApp'
        appName: 'app-myapp-dev'
        package: '$(Pipeline.Workspace)/application/**/*.zip'
```

## Multi-Environment Workflows

### Environment Promotion Pipeline

```yaml
# Multi-environment deployment with approvals
variables:
- group: 'release-engine-common'

stages:
- stage: Build
  jobs:
  - template: common/pipelines/03-jobs/iac.build.job.yml@releaseEngine
    parameters:
      workload: 'multi-env-app'

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'multi-env-app'
      environment: 'dev'
      serviceConnection: 'azure-connection-dev'

- stage: DeployTest
  displayName: 'Deploy to Test'
  dependsOn: DeployDev
  condition: succeeded()
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'multi-env-app'
      environment: 'test'
      serviceConnection: 'azure-connection-test'

- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: DeployTest
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployProduction
    environment: 'production'  # Requires manual approval
    strategy:
      runOnce:
        deploy:
          steps:
          - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
            parameters:
              workload: 'multi-env-app'
              environment: 'prod'
              serviceConnection: 'azure-connection-prod'
```

### Environment-Specific Configuration

Organize configurations by environment:

```yaml
# Pipeline parameter for environment selection
parameters:
- name: targetEnvironment
  displayName: 'Target Environment'
  type: string
  default: 'dev'
  values:
  - 'dev'
  - 'test'
  - 'prod'

variables:
- group: 'release-engine-${{ parameters.targetEnvironment }}'
- name: configPath
  value: 'config/${{ parameters.targetEnvironment }}'

stages:
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: 'configurable-app'
    environment: '${{ parameters.targetEnvironment }}'
    configurationPath: '$(configPath)'
```

## Advanced Scenarios

### Custom Validation Steps

Add custom validation to the pipeline:

```yaml
stages:
- stage: CustomValidation
  jobs:
  - job: ValidateConfiguration
    steps:
    - task: PowerShell@2
      displayName: 'Validate Bicep Templates'
      inputs:
        targetType: 'inline'
        script: |
          # Custom validation logic
          $bicepFiles = Get-ChildItem -Path "infrastructure" -Filter "*.bicep" -Recurse
          
          foreach ($file in $bicepFiles) {
              Write-Host "Validating $($file.Name)"
              az bicep build --file $file.FullName --validate-only
              if ($LASTEXITCODE -ne 0) {
                  throw "Validation failed for $($file.Name)"
              }
          }

- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: 'validated-app'
    environment: 'dev'
    dependsOn: 'CustomValidation'
```

### Integration with External Systems

```yaml
stages:
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: 'integrated-app'
    environment: 'prod'

- stage: PostDeployment
  dependsOn: Deploy
  jobs:
  - job: NotifyTeams
    steps:
    - task: PowerShell@2
      displayName: 'Notify Teams'
      inputs:
        targetType: 'inline'
        script: |
          # Send notification to Teams
          $webhookUrl = "$(teamsWebhookUrl)"
          $message = @{
              text = "Deployment completed for $(workloadName) in production"
          } | ConvertTo-Json
          
          Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $message -ContentType "application/json"
```

## Best Practices

### 1. Repository Organization

- Keep configuration files separate from source code
- Use consistent naming conventions
- Organize by environment and workload
- Version control all configuration

### 2. Pipeline Design

- Use orchestrator templates for complex workflows
- Implement proper error handling
- Add meaningful display names and descriptions
- Use conditions to control deployment flow

### 3. Configuration Management

- Use variable groups for environment-specific settings
- Implement token replacement for dynamic values
- Validate configurations before deployment
- Use secure variables for sensitive data

### 4. Security

- Use service connections for Azure authentication
- Implement approval gates for production
- Store secrets in Azure Key Vault
- Follow principle of least privilege

### 5. Monitoring and Logging

- Enable detailed logging in pipelines
- Implement health checks post-deployment
- Set up alerts for deployment failures
- Monitor resource usage and costs

### 6. Testing

- Validate templates before deployment
- Test in non-production environments first
- Implement automated testing where possible
- Use feature flags for controlled rollouts

## Common Patterns

### Pattern 1: Blue-Green Deployment

```yaml
# Implement blue-green deployment pattern
stages:
- stage: DeployBlue
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'blue-green-app'
      environment: 'blue'
      
- stage: ValidateBlue
  dependsOn: DeployBlue
  jobs:
  - job: RunTests
    # Validation steps

- stage: SwitchTraffic
  dependsOn: ValidateBlue
  condition: succeeded()
  jobs:
  - job: UpdateTrafficManager
    # Switch traffic from green to blue
```

### Pattern 2: Canary Deployment

```yaml
# Implement canary deployment pattern
stages:
- stage: DeployCanary
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'canary-app'
      environment: 'canary'
      trafficPercentage: 10

- stage: MonitorCanary
  dependsOn: DeployCanary
  jobs:
  - job: MonitorMetrics
    # Monitor application metrics

- stage: PromoteCanary
  dependsOn: MonitorCanary
  condition: succeeded()
  jobs:
  - template: common/pipelines/03-jobs/iac.deploy.job.yml@releaseEngine
    parameters:
      workload: 'canary-app'
      environment: 'production'
      trafficPercentage: 100
```

For more detailed examples, see the [Examples Guide](EXAMPLES.md).