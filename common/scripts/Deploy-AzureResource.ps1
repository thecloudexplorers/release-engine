#Requires -PSEdition Core

<#
.SYNOPSIS
    Deploys an Azure resource using a specified Bicep or ARM template.

.DESCRIPTION
    This script deploys an Azure resource using the provided parameters. 
    It supports deployments at tenant, subscription, or resource group scope.
    It converts custom parameters into an object and executes the deployment, with error handling
    to ensure any issues are reported clearly.

.PARAMETER ResourceLocation
    The Azure location where the resources will be deployed.

.PARAMETER TemplateFilePath
    The file path to the template (Bicep or ARM) to be deployed.

.PARAMETER ParameterFilePath
    The path to the parameter file.

.PARAMETER DeploymentScope
    The scope for the deployment (Tenant, Subscription, ResourceGroup).

.PARAMETER DeploymentKey
    A unique key to identify the deployment.

.PARAMETER CustomParameters
    A hashtable of custom parameters to be passed to the template.

.NOTES
    Author      : Wesley Camargo
    Source      : https://github.com/thecloudexplorers/ReleaseEngine

.EXAMPLE
    $customParams = @{
        ResourceGroupName = "dev-rg001"    
        LogAnalyticsWorkspaceName = "dev-law001"    
        RootRepoLocation = "C:\dev\script\path"    
    }
    .\Deploy-AzureResource.ps1 -TemplateFilePath "path\to\template.bicep" `
                               -ResourceLocation "EastUS" `
                               -DeploymentScope "Subscription" `
                               -DeploymentKey "unique-key" `
                               -CustomParameters $customParams
#>

# =====================================================================================
# Script Name:    Deploy-AzureResource.ps1
# =====================================================================================

[CmdletBinding()]
param(
    [string]$ResourceLocation,
    [string]$TemplateFilePath,
    [string]$ParameterFilePath,
    [ValidateSet('Tenant', 'ManagementGroup', 'Subscription', 'ResourceGroup')]
    [string]$DeploymentScope,
    [string]$DeploymentKey,
    [System.Collections.Hashtable]$CustomParameters
)

# Set error action preference to stop on errors
$ErrorActionPreference = 'Stop'

# Initialize an empty hashtable for template parameters
$templateParameterObject = @{}

# Convert custom parameters into an object
foreach ($key in $CustomParameters.Keys) {
    $templateParameterObject.Add($key, $CustomParameters[$key])
}

# Generate a unique deployment name using the deployment key
$deploymentName = "deploy-$DeploymentKey"

# Define deployment arguments
$deploymentParams = @{
    Location                = $ResourceLocation
    TemplateFile            = $TemplateFilePath
    TemplateParameterObject = $templateParameterObject
    Name                    = $deploymentName
}

# Execute the deployment based on the specified scope
try {
    Write-Output "##vso[task.logissue type=info]Starting deployment..."

    switch ($DeploymentScope) {
        'Tenant' {
            Write-Output "##vso[task.logissue type=info]Deploying at tenant scope..."
            $deploymentResult = New-AzTenantDeployment @deploymentParams
        }
        'Subscription' {
            Write-Output "##vso[task.logissue type=info]Deploying at subscription scope..."
            $deploymentResult = New-AzSubscriptionDeployment @deploymentParams
        }
        'ResourceGroup' {
            [string]$ResourceGroupName = Read-Host "Enter the Resource Group Name"
            Write-Output "##vso[task.logissue type=info]Deploying at resource group scope: $ResourceGroupName..."
            $deploymentParams['ResourceGroupName'] = $ResourceGroupName
            $deploymentResult = New-AzResourceGroupDeployment @deploymentParams
        }
    }
    
    if ($deploymentResult.ProvisioningState -eq 'Succeeded') {
        Write-Output "##vso[task.logissue type=info]Deployment succeeded."
    }
    else {
        Write-Output "##vso[task.logissue type=warning]Deployment completed with provisioning state: $($deploymentResult.ProvisioningState)"
    }
    
    Write-Output "##vso[task.logissue type=info]Timestamp: $($deploymentResult.Timestamp)"
    Write-Output "##vso[task.logissue type=info]Mode: $($deploymentResult.Mode)"
}
catch {
    Write-Output "##vso[task.logissue type=error]An error occurred during deployment: $_"
}
finally {
    Write-Output "##vso[task.logissue type=info]Deployment process finished."
}
