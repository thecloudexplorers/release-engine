# Instructions for Creating New Patterns

## Overview

This document provides step-by-step instructions for creating new patterns based on the `example_pattern` structure.

## Steps

1. **Folder Structure**
   - Create a new folder under `release-engine-pattern-template/patterns/` with the name of your new pattern.
   - Example: `release-engine-pattern-template/patterns/<new_pattern_name>/`.

2. **Required Files**
   - Each pattern must include the following files:
     - `workload.bicep`: Defines the infrastructure and resources for the pattern.
     - `deployment-pattern.yml`: Configures the pipeline and deployment settings.

3. **Creating `workload.bicep`**

   Use the following template as a starting point:

   ```bicep
   metadata resources = {
     version: '0.1.0'
     author: '<Author Name>'
     description: '<Description>'
   }

   targetScope = 'subscription'

   @allowed([
     'westeurope'
     'uksouth'
   ])
   @description('Region in which the workload should be deployed')
   param resourceLocation string

   param tags object

   @description('Name of the target resource group')
   param resourceGroupName string = '<default-resource-group-name>'

   // Check for Azure Verified Modules (AVM) availability
   module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
     name: 'resourceGroupDeployment'
     params: {
       name: resourceGroupName
     }
   }

   output resourceGroupId string = resourceGroup.outputs.resourceId
   ```

   - **Important**: Always check if Azure Verified Modules (AVM) are available for the required resource. If AVM is not available, you may use the resource directly, but document the reason for not using AVM.
   - Update the `metadata` section with the version, author, and description.
   - Define parameters and modules specific to your workload.

4. **Creating `deployment-pattern.yml`**

   Use the following template as a starting point:

   ```yaml
   parameters:
     - name: deploymentSettings
       type: object

   variables:
     - name: serviceConnection
       value: <default-service-connection>

   stages:
     - template: /pipelines/01-orchestrators/pattern.orchestrator.yml@release-engine-core
       parameters:
         patternSettings:
           name: <new_pattern_name>
           configurationFilePath: ${{ parameters.deploymentSettings.configurationFilePath }}
           workloadDefinitionRepositoryName: release-engine-pattern-template
           environments: ${{ parameters.deploymentSettings.environments }}
           workloadArtifactsPath: /patterns/<new_pattern_name>
           stages:
             - infrastructure:
                 iac:
                   name: <new_pattern_name>
                   deploymentScope: Subscription
                   serviceConnection: $(serviceConnection)
                   iacMainFileName: workload.bicep
                   iacParameterFileName: ${{ parameters.deploymentSettings.iacParameterFileName }}
                   iacParameterFilesDirectory: /iac/
   ```

   - Replace `<new_pattern_name>` with the name of your pattern.
   - Update the `serviceConnection` variable with the appropriate service connection for your environment.
   - Save this file as `deployment-pattern.yml` inside your pattern folder.
   - When referencing this pattern from a pipeline, extend it like:
     
     ```yaml
     extends:
       template: /patterns/<new_pattern_name>/deployment-pattern.yml@workload
       parameters:
         deploymentSettings:
           configurationFilePath: /_config
           environments: [development, test, production]
     ```

   - New: You can optionally pass `configurationPipelineContext` in `deploymentSettings` to indicate where the extending pipeline runs from:
     
     ```yaml
     parameters:
       deploymentSettings:
         configurationPipelineContext: "internal"  # options: "internal" | "external" (default: external)
     ```

5. **Testing the Pattern**

- Validate the `workload.bicep` file using Azure Bicep tools.
- Test the pipeline configuration in a development environment.
- If testing inside the `release-engine-core` repository, set `configurationPipelineContext: "internal"` in your test pipeline. For external repositories, omit it or set to `"external"`.

1. **Documentation**
   - Document the purpose and usage of the pattern in a `README.md` file within the pattern folder.
   - Include details about required parameters, deployment steps, and any dependencies.

---

By following these steps, you can create new patterns that align with the existing structure and best practices.