<#
.SYNOPSIS
    Deploys an Azure Bicep template to a specified Azure location.

.DESCRIPTION
    This script deploys an Azure Bicep template using the provided parameters. 
    It converts custom parameters into an object and executes the deployment.

.PARAMETER BicepTemplateFilePath
    The file path to the Bicep template to be deployed.

.PARAMETER AzureLocation
    The Azure location where the resources will be deployed.

.PARAMETER DeploymentKey
    A unique key to identify the deployment.

.PARAMETER CustomBicepParameters
    A hashtable of custom parameters to be passed to the Bicep template.

.NOTES
    Author      : Wesley Camargo
    Source      : https://github.com/thecloudexplorers/ReleaseEngine

.EXAMPLE
    $customParams = @{
        ResourceGroupName = "dev-rg001"    
        LogAnalyticsWorkspaceName = "dev-law001"    
        RootRepoLocation = "C:\dev\script\path"    
    }
    .\Deploy-BicepTemplate.ps1 -BicepTemplateFilePath "path\to\template.bicep" `
                               -AzureLocation "EastUS" `
                               -DeploymentKey "unique-key" `
                               -CustomBicepParameters $customParams

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [System.String]$BicepTemplateFilePath,

    [Parameter(Mandatory)]
    [System.String]$AzureLocation,

    [Parameter(Mandatory)]
    [System.String]$DeploymentKey,

    [Parameter(Mandatory)]
    [System.Collections.Hashtable]$CustomBicepParameters
)

# Set error action preference to stop on errors
$ErrorActionPreference = 'Stop'

# Import the Az.Resources module
Import-Module Az.Resources

# Initialize an empty hashtable for template parameters
$templateParameterObject = @{}

# Convert custom parameters into an object
foreach ($key in $CustomBicepParameters.Keys) {
    $templateParameterObject.Add($key, $CustomBicepParameters[$key])
}

# Debug output for Bicep parameters
Write-Debug "Bicep Parameters:"
Write-Debug $templateParameterObject

# Generate a unique deployment name using the deployment key
$deploymentName = "deploy-$DeploymentKey"
Write-Host "Executing Bicep deployment"

# Define deployment arguments
$deploySubscriptionArgs = @{
    Location                = $AzureLocation
    TemplateFile            = $BicepTemplateFilePath
    TemplateParameterObject = $templateParameterObject
    Name                    = $deploymentName
}

# Execute the Bicep deployment
$azDeploymentResults = New-AzDeployment @deploySubscriptionArgs

# Output deployment results
Write-Host "Deployment completed"
Write-Host "  ProvisioningState [$($azDeploymentResults.ProvisioningState)]"
Write-Host "  Timestamp [$($azDeploymentResults.Timestamp)]"
Write-Host "  Mode [$($azDeploymentResults.Mode)]"

Write-Host "All done!!!"
