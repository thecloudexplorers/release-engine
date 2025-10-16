# Setup Guide

This guide provides detailed instructions for setting up and configuring the Release Engine in your environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Azure DevOps Setup](#azure-devops-setup)
- [Service Connection Configuration](#service-connection-configuration)
- [Repository Integration](#repository-integration)
- [Agent Configuration](#agent-configuration)
- [Initial Configuration](#initial-configuration)
- [Verification](#verification)
- [Next Steps](#next-steps)

## Prerequisites

### Required Software

- **Azure CLI** (version 2.30.0 or later)
  ```bash
  # Install Azure CLI
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  
  # Verify installation
  az --version
  ```

- **PowerShell 7.0+**
  ```bash
  # Install PowerShell on Linux/macOS
  # Visit: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell
  
  # Verify installation
  pwsh --version
  ```

- **Git** (latest version)
  ```bash
  # Verify installation
  git --version
  ```

### Azure Requirements

- **Azure Subscription** with appropriate permissions:
  - Contributor role or higher on target resource groups
  - User Access Administrator role for role assignments (if deploying IAM)
  - Subscription-level permissions for policy and blueprint deployments

- **Azure DevOps Organization** with:
  - Project Administrator permissions
  - Pipeline creation permissions
  - Service connection management permissions

### PowerShell Modules

Install required PowerShell modules:

```powershell
# Azure PowerShell modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name Az.Resources -Force
Install-Module -Name Az.Storage -Force
Install-Module -Name Az.KeyVault -Force

# Verify installation
Get-Module -ListAvailable Az*
```

## Azure DevOps Setup

### 1. Create or Access Azure DevOps Project

1. Navigate to your Azure DevOps organization
2. Create a new project or select an existing one
3. Ensure you have the necessary permissions

### 2. Configure Project Settings

#### Agent Pools
Ensure your agent pools have the following capabilities:
- PowerShell Core
- Azure CLI
- Git
- Bicep CLI (optional, but recommended)

#### Extensions
Install the following extensions if not already available:
- Azure DevOps Extension for Azure CLI
- Azure Pipelines Agent

### 3. Repository Setup

#### Option A: Reference as External Repository
```yaml
# In your pipeline YAML
resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main
```

#### Option B: Fork or Import
1. Fork the repository to your organization
2. Import the repository into your Azure DevOps project
3. Configure branch policies as needed

## Service Connection Configuration

### 1. Create Azure Service Connection

1. Go to **Project Settings** > **Service connections**
2. Click **New service connection**
3. Select **Azure Resource Manager**
4. Choose **Service principal (automatic)**
5. Configure the connection:
   - **Subscription**: Select your Azure subscription
   - **Resource Group**: Leave empty for subscription-level access
   - **Service connection name**: `azure-connection-{environment}` (e.g., `azure-connection-dev`)
6. Click **Save**

### 2. Service Principal Permissions

Ensure the service principal has appropriate permissions:

```bash
# Get service principal object ID from Azure DevOps service connection
# Then assign roles in Azure

# Example: Assign Contributor role at subscription level
az role assignment create \
  --assignee {service-principal-object-id} \
  --role "Contributor" \
  --scope "/subscriptions/{subscription-id}"

# Example: Assign User Access Administrator for IAM deployments
az role assignment create \
  --assignee {service-principal-object-id} \
  --role "User Access Administrator" \
  --scope "/subscriptions/{subscription-id}"
```

### 3. Variable Groups

Create variable groups for environment-specific configurations:

1. Go to **Pipelines** > **Library**
2. Click **+ Variable group**
3. Create groups for each environment (dev, test, prod)
4. Add common variables:
   - `azureSubscriptionId`
   - `azureServiceConnection`
   - `resourceGroupPrefix`
   - `location`

## Repository Integration

### 1. Pipeline Configuration

Create a basic pipeline to test integration:

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop

resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine
    ref: refs/heads/main

variables:
- group: 'release-engine-dev'

stages:
- template: common/pipelines/02-stages/iac.build.stage.yml@releaseEngine
  parameters:
    workload: 'test-workload'
    environment: 'dev'
```

### 2. Workload Configuration

1. Copy a template from `templates/workloads/platform/_TEMPLATE-COPY-ME-design-area/`
2. Rename and customize for your workload:
   ```bash
   cp -r templates/workloads/platform/_TEMPLATE-COPY-ME-design-area/CHANGE-ME-workload \
         templates/workloads/platform/my-design-area/my-workload
   ```
3. Update configuration files in the new directory

## Agent Configuration

### Self-Hosted Agents (Recommended)

If using self-hosted agents, ensure they have:

```bash
# Install required tools on agent machine
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# PowerShell 7
# Download and install from GitHub releases

# Bicep CLI
az bicep install

# Verify installations
az --version
pwsh --version
az bicep version
```

### Hosted Agents

Microsoft-hosted agents include most required tools, but may need additional configuration:

```yaml
# Pipeline step to ensure tools are available
- task: PowerShell@2
  displayName: 'Verify Prerequisites'
  inputs:
    targetType: 'inline'
    script: |
      # Verify PowerShell version
      $PSVersionTable.PSVersion
      
      # Verify Azure CLI
      az --version
      
      # Install additional modules if needed
      Install-Module -Name Az.Resources -Force -Scope CurrentUser
```

## Initial Configuration

### 1. Environment Configuration

Create environment-specific configuration:

```json
// config/dev/metadata.jsonc
{
  "environment": "dev",
  "location": "East US 2",
  "resourceGroupPrefix": "rg-myproject-dev",
  "subscriptionId": "your-subscription-id",
  "tags": {
    "Environment": "Development",
    "Project": "MyProject",
    "Owner": "TeamName"
  }
}
```

### 2. Variable Group Setup

Configure variable groups with environment-specific values:

**release-engine-dev**:
- `environment`: dev
- `location`: East US 2
- `subscriptionId`: your-dev-subscription-id
- `azureServiceConnection`: azure-connection-dev

**release-engine-prod**:
- `environment`: prod
- `location`: East US 2
- `subscriptionId`: your-prod-subscription-id
- `azureServiceConnection`: azure-connection-prod

### 3. Pipeline Permissions

Configure pipeline permissions:

1. Go to **Pipelines** > **Environments**
2. Create environments (dev, test, prod)
3. Configure approval requirements for production
4. Set up deployment gates as needed

## Verification

### 1. Test Pipeline Execution

1. Run your first pipeline
2. Verify that it can:
   - Access the Release Engine repository
   - Connect to Azure
   - Execute PowerShell scripts
   - Process configuration files

### 2. Validate Permissions

Test Azure permissions:

```powershell
# Connect using service principal
Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $credential

# Test resource group operations
New-AzResourceGroup -Name "rg-test-permissions" -Location "East US 2"
Remove-AzResourceGroup -Name "rg-test-permissions" -Force
```

### 3. Configuration Validation

Verify token replacement functionality:

```powershell
# Test the Convert-TokensToValues function
$metadata = @{
    "environment" = "dev"
    "location" = "East US 2"
}

# This should successfully replace tokens in your configuration files
```

## Next Steps

After successful setup:

1. **Review the [Usage Guide](USAGE.md)** for detailed usage instructions
2. **Explore [Examples](EXAMPLES.md)** for common implementation patterns
3. **Check [Troubleshooting](TROUBLESHOOTING.md)** if you encounter issues
4. **Review [Architecture](ARCHITECTURE.md)** to understand the system design

## Common Issues

### Issue: Pipeline cannot access Release Engine repository

**Solution**: Verify repository resource configuration and permissions:

```yaml
resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: thecloudexplorers/release-engine  # Ensure correct organization/project name
    ref: refs/heads/main
```

### Issue: Azure authentication fails

**Solution**: Check service connection configuration and permissions:

1. Verify service connection is active
2. Test connection in Azure DevOps
3. Confirm service principal permissions in Azure

### Issue: PowerShell module import errors

**Solution**: Install required modules on agent:

```yaml
- task: PowerShell@2
  displayName: 'Install Required Modules'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module -Name Az.Resources -Force -Scope CurrentUser
      Import-Module Az.Resources
```

For more issues and solutions, see the [Troubleshooting Guide](TROUBLESHOOTING.md).