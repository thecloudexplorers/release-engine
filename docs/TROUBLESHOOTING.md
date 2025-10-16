# Troubleshooting Guide

This guide provides solutions to common issues encountered when using the Release Engine.

## Table of Contents

- [Pipeline Issues](#pipeline-issues)
- [Azure Authentication](#azure-authentication)
- [Configuration Problems](#configuration-problems)
- [PowerShell Script Errors](#powershell-script-errors)
- [Bicep Deployment Issues](#bicep-deployment-issues)
- [Token Replacement Problems](#token-replacement-problems)
- [Agent and Environment Issues](#agent-and-environment-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)

## Pipeline Issues

### Issue: Pipeline template not found

**Error Message:**
```
Template reference 'common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine' could not be resolved
```

**Possible Causes:**
- Incorrect repository resource configuration
- Wrong template path
- Repository access permissions

**Solutions:**

1. **Verify repository resource configuration:**
   ```yaml
   resources:
     repositories:
     - repository: releaseEngine  # This name must match the @reference
       type: git
       name: thecloudexplorers/release-engine  # Correct organization/project
       ref: refs/heads/main  # Ensure branch exists
   ```

2. **Check template path:**
   ```bash
   # Verify the template exists in the repository
   ls -la common/pipelines/02-stages/iac.deploy.stage.yml
   ```

3. **Verify permissions:**
   - Ensure your project has access to the Release Engine repository
   - Check if the repository is public or if you have appropriate permissions

### Issue: Pipeline fails with "No agent could be found"

**Error Message:**
```
No agent found in pool 'Azure Pipelines' which satisfies the specified demands
```

**Solutions:**

1. **For Microsoft-hosted agents:**
   ```yaml
   pool:
     vmImage: 'ubuntu-latest'  # Use a valid VM image
   ```

2. **For self-hosted agents:**
   ```yaml
   pool:
     name: 'Default'  # Use your agent pool name
     demands:
     - agent.os -equals Windows_NT  # Or Linux based on your agents
   ```

3. **Check agent capabilities:**
   - Ensure agents have required capabilities (PowerShell, Azure CLI)
   - Verify agents are online and available

### Issue: Pipeline timeout

**Error Message:**
```
The job running on agent 'Hosted Agent' ran longer than the maximum time of 60 minutes
```

**Solutions:**

1. **Increase timeout:**
   ```yaml
   jobs:
   - job: MyJob
     timeoutInMinutes: 120  # Increase as needed
   ```

2. **Optimize deployment scripts:**
   - Use parallel deployments where possible
   - Optimize Bicep templates
   - Reduce unnecessary steps

## Azure Authentication

### Issue: Service connection authentication fails

**Error Message:**
```
Failed to obtain the JWT token. Ensure that the Service Principal is valid
```

**Solutions:**

1. **Verify service connection:**
   - Go to Project Settings > Service connections
   - Test the connection
   - Recreate if necessary

2. **Check service principal permissions:**
   ```bash
   # Verify service principal has required roles
   az role assignment list --assignee <service-principal-id> --subscription <subscription-id>
   ```

3. **Update service principal credentials:**
   - Service principal secret may have expired
   - Generate new secret and update service connection

### Issue: Insufficient permissions

**Error Message:**
```
The client does not have authorization to perform action 'Microsoft.Resources/deployments/write'
```

**Solutions:**

1. **Grant appropriate roles:**
   ```bash
   # Grant Contributor role at subscription level
   az role assignment create \
     --assignee <service-principal-id> \
     --role "Contributor" \
     --scope "/subscriptions/<subscription-id>"
   
   # For resource group level
   az role assignment create \
     --assignee <service-principal-id> \
     --role "Contributor" \
     --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>"
   ```

2. **For custom roles, ensure required permissions:**
   ```json
   {
     "actions": [
       "Microsoft.Resources/deployments/*",
       "Microsoft.Resources/subscriptions/resourceGroups/*"
     ]
   }
   ```

### Issue: Multi-factor authentication required

**Error Message:**
```
AADSTS50076: Due to a configuration change made by your administrator, or because you moved to a new location, you must use multi-factor authentication
```

**Solutions:**

1. **Use service principal authentication:**
   - Avoid user-based authentication in pipelines
   - Configure service connections with service principals

2. **Configure conditional access policies:**
   - Exclude service principals from MFA requirements
   - Use location-based policies appropriately

## Configuration Problems

### Issue: Variable group not found

**Error Message:**
```
Variable group 'release-engine-dev' could not be found
```

**Solutions:**

1. **Create the variable group:**
   - Go to Pipelines > Library
   - Create variable group with exact name
   - Add required variables

2. **Check variable group permissions:**
   - Ensure pipeline has access to variable group
   - Grant appropriate permissions

3. **Use conditional variable groups:**
   ```yaml
   variables:
   - ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/main') }}:
     - group: 'release-engine-prod'
   - ${{ else }}:
     - group: 'release-engine-dev'
   ```

### Issue: Configuration file not found

**Error Message:**
```
Cannot find path 'config/dev/metadata.jsonc' because it does not exist
```

**Solutions:**

1. **Verify file structure:**
   ```bash
   # Check if file exists
   ls -la config/dev/metadata.jsonc
   ```

2. **Use correct paths in pipeline:**
   ```yaml
   parameters:
     configurationPath: '$(System.DefaultWorkingDirectory)/config/dev'
   ```

3. **Check file naming:**
   - Ensure exact filename match (case-sensitive on Linux)
   - Verify file extension (.jsonc vs .json)

## PowerShell Script Errors

### Issue: PowerShell execution policy

**Error Message:**
```
Execution of scripts is disabled on this system
```

**Solutions:**

1. **Set execution policy in pipeline:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
         # Your script here
   ```

2. **Use PowerShell Core:**
   ```yaml
   - task: PowerShell@2
     inputs:
       pwsh: true  # Use PowerShell Core
   ```

### Issue: Module not found

**Error Message:**
```
The term 'Connect-AzAccount' is not recognized as the name of a cmdlet
```

**Solutions:**

1. **Install required modules:**
   ```yaml
   - task: PowerShell@2
     displayName: 'Install Required Modules'
     inputs:
       targetType: 'inline'
       script: |
         Install-Module -Name Az -Force -Scope CurrentUser -AllowClobber
         Import-Module Az
   ```

2. **Use pre-installed modules on hosted agents:**
   ```yaml
   - task: AzurePowerShell@5
     inputs:
       azureSubscription: 'your-service-connection'
       ScriptType: 'InlineScript'
       Inline: |
         # Azure PowerShell modules are pre-loaded
         Get-AzResourceGroup
   ```

### Issue: Script parameter binding

**Error Message:**
```
Cannot bind parameter 'CustomBicepParameters'. Cannot convert the "System.String" value to type "System.Collections.Hashtable"
```

**Solutions:**

1. **Proper parameter passing:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'filePath'
       filePath: 'scripts/deploy.ps1'
       arguments: >
         -BicepTemplateFilePath "$(templatePath)"
         -CustomBicepParameters @{
           environment='dev';
           location='East US 2'
         }
   ```

2. **Use splatting for complex parameters:**
   ```powershell
   $deployParams = @{
     BicepTemplateFilePath = $BicepTemplateFilePath
     CustomBicepParameters = @{
       environment = 'dev'
       location = 'East US 2'
     }
   }
   
   & .\Deploy-BicepTemplate.ps1 @deployParams
   ```

## Bicep Deployment Issues

### Issue: Bicep template validation fails

**Error Message:**
```
The template is not valid. Template validation failed: The parameter 'storageAccountName' is not allowed
```

**Solutions:**

1. **Validate Bicep syntax:**
   ```bash
   # Validate locally
   az bicep build --file main.bicep --validate-only
   ```

2. **Check parameter names and types:**
   ```bicep
   @description('Storage account name')
   @minLength(3)
   @maxLength(24)
   param storageAccountName string
   ```

3. **Verify parameter file:**
   ```json
   {
     "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
     "contentVersion": "1.0.0.0",
     "parameters": {
       "storageAccountName": {
         "value": "mystorageaccount"
       }
     }
   }
   ```

### Issue: Resource naming conflicts

**Error Message:**
```
The storage account name 'mystorageaccount' is already taken
```

**Solutions:**

1. **Use unique naming:**
   ```bicep
   var storageAccountName = 'st${applicationName}${environment}${uniqueString(resourceGroup().id)}'
   
   resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
     name: storageAccountName
     // ...
   }
   ```

2. **Check for existing resources:**
   ```bash
   # Check if resource name is available
   az storage account check-name --name mystorageaccount
   ```

### Issue: Deployment quota exceeded

**Error Message:**
```
Creating the deployment 'deploy-20231201120000' would exceed the quota of '800'
```

**Solutions:**

1. **Clean up old deployments:**
   ```bash
   # List deployments
   az deployment group list --resource-group myResourceGroup --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" --output table
   
   # Delete old deployments
   az deployment group delete --resource-group myResourceGroup --name old-deployment-name
   ```

2. **Use unique deployment names:**
   ```powershell
   $deploymentName = "deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"
   ```

## Token Replacement Problems

### Issue: Tokens not replaced

**Error Message:**
```
Unreplaced tokens detected: #{environment}#, #{location}#
```

**Solutions:**

1. **Verify metadata file:**
   ```jsonc
   // config/dev/metadata.jsonc
   {
     "environment": "dev",
     "location": "East US 2"
   }
   ```

2. **Check token patterns:**
   ```yaml
   - task: PowerShell@2
     inputs:
       filePath: 'common/scripts/Replace-ConfigurationFilesTokens.ps1'
       arguments: >
         -StartTokenPattern "#{" 
         -EndTokenPattern "}#"
   ```

3. **Verify file permissions:**
   ```bash
   # Ensure files are readable
   chmod +r config/dev/metadata.jsonc
   ```

### Issue: Invalid JSON after token replacement

**Error Message:**
```
Unexpected character encountered while parsing value
```

**Solutions:**

1. **Escape special characters:**
   ```jsonc
   {
     "connectionString": "Server=#{serverName}#;Database=#{databaseName}#;",
     "enableFeature": #{enableFeature}#  // Boolean, no quotes
   }
   ```

2. **Validate JSON structure:**
   ```bash
   # Validate JSON after processing
   jq . processed-config.json
   ```

3. **Use proper data types:**
   ```jsonc
   // metadata.jsonc
   {
     "enableFeature": true,  // Boolean
     "maxRetries": 5,        // Number
     "serverName": "myserver" // String
   }
   ```

## Agent and Environment Issues

### Issue: Path not found on different OS

**Error Message:**
```
Cannot find path 'config\dev\metadata.jsonc' because it does not exist
```

**Solutions:**

1. **Use cross-platform paths:**
   ```yaml
   variables:
     configPath: '$(System.DefaultWorkingDirectory)/config/dev'  # Use forward slashes
   ```

2. **Use PowerShell Join-Path:**
   ```powershell
   $configFile = Join-Path $configPath "metadata.jsonc"
   ```

3. **Check agent OS compatibility:**
   ```yaml
   pool:
     vmImage: 'ubuntu-latest'  # Specify compatible OS
   ```

### Issue: Tool version mismatch

**Error Message:**
```
The current .NET SDK does not support targeting .NET 6.0
```

**Solutions:**

1. **Use UseDotNet task:**
   ```yaml
   - task: UseDotNet@2
     inputs:
       packageType: 'sdk'
       version: '6.0.x'
   ```

2. **Specify tool versions:**
   ```yaml
   - task: AzureCLI@2
     inputs:
       azureSubscription: 'service-connection'
       scriptType: 'bash'
       scriptLocation: 'inlineScript'
       inlineScript: |
         az --version
         az bicep version
   ```

## Performance Issues

### Issue: Slow pipeline execution

**Symptoms:**
- Pipelines taking longer than expected
- Frequent timeouts
- High resource usage

**Solutions:**

1. **Use parallel jobs:**
   ```yaml
   jobs:
   - job: BuildInfrastructure
   - job: BuildApplication
     dependsOn: [] # Run in parallel
   ```

2. **Optimize Bicep templates:**
   - Use modules for reusability
   - Minimize template complexity
   - Use conditions to skip unnecessary resources

3. **Use artifact caching:**
   ```yaml
   - task: Cache@2
     inputs:
       key: 'bicep | "$(Agent.OS)" | infrastructure/*.bicep'
       path: '$(System.DefaultWorkingDirectory)/bicep-cache'
   ```

4. **Choose appropriate agent pool:**
   ```yaml
   pool:
     vmImage: 'ubuntu-latest'  # Often faster than Windows
   ```

### Issue: Large artifact sizes

**Solutions:**

1. **Exclude unnecessary files:**
   ```yaml
   - publish: '$(Build.ArtifactStagingDirectory)/app'
     artifact: 'application'
     condition: succeeded()
   ```

2. **Use .artifactignore:**
   ```
   # .artifactignore
   node_modules/
   *.log
   .git/
   ```

## Getting Help

### Debug Information Collection

When reporting issues, include:

1. **Pipeline logs:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         Write-Host "Pipeline Information:"
         Write-Host "Build ID: $(Build.BuildId)"
         Write-Host "Source Branch: $(Build.SourceBranch)"
         Write-Host "Agent OS: $(Agent.OS)"
         Write-Host "Working Directory: $(System.DefaultWorkingDirectory)"
   ```

2. **Environment information:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         $PSVersionTable
         az --version
         Get-Module -ListAvailable Az*
   ```

3. **Configuration details:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         Write-Host "Variables:"
         Get-ChildItem Env: | Where-Object { $_.Name -like "*BUILD*" -or $_.Name -like "*AGENT*" }
   ```

### Enable Detailed Logging

1. **Enable system diagnostics:**
   ```yaml
   variables:
     system.debug: true
   ```

2. **Add verbose PowerShell:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         $VerbosePreference = 'Continue'
         # Your script here
   ```

### Common Debug Steps

1. **Test locally:**
   ```bash
   # Test scripts locally before running in pipeline
   pwsh -File ./scripts/deploy.ps1 -Verbose
   ```

2. **Use incremental testing:**
   ```yaml
   # Comment out complex steps and test incrementally
   # - template: complex-template.yml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: Write-Host "Testing basic functionality"
   ```

3. **Check file contents:**
   ```yaml
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         Write-Host "Current directory contents:"
         Get-ChildItem -Recurse | Select-Object FullName
   ```

### Resources for Additional Help

- **GitHub Issues**: [Report bugs and request features](https://github.com/thecloudexplorers/release-engine/issues)
- **GitHub Discussions**: [Community support and questions](https://github.com/thecloudexplorers/release-engine/discussions)
- **Azure DevOps Documentation**: [Official Azure DevOps docs](https://docs.microsoft.com/en-us/azure/devops/)
- **Azure CLI Documentation**: [Azure CLI reference](https://docs.microsoft.com/en-us/cli/azure/)
- **PowerShell Documentation**: [PowerShell reference](https://docs.microsoft.com/en-us/powershell/)

### Creating Effective Issue Reports

When reporting issues, include:

1. **Clear description** of the problem
2. **Steps to reproduce** the issue
3. **Expected vs actual behavior**
4. **Pipeline logs** (relevant sections)
5. **Configuration files** (sanitized)
6. **Environment details** (agent type, OS, tool versions)

**Template for issue reports:**

```markdown
## Problem Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Agent: Microsoft-hosted / Self-hosted
- OS: Ubuntu 20.04 / Windows Server 2019
- PowerShell Version: 7.2.x
- Azure CLI Version: 2.x.x

## Additional Context
Any additional information, configuration files, or logs
```

This troubleshooting guide should help resolve most common issues. If you encounter problems not covered here, please create an issue on GitHub with detailed information about your scenario.