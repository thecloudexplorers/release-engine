# AI Agent Instructions for Release Engine

## 🏗️ Project Structure & Key Files

### Pipeline Structure

- `/pipelines/` - Core reusable pipeline components
  - `01-orchestrators/` - High-level pipeline orchestration templates
  - `02-stages/` - Reusable deployment stages (build, deploy)
  - `03-jobs/` - Individual job definitions
  - `04-steps/` - Atomic pipeline steps

### Template System

- `/templates/workloads/` - Project templates for different workload types
  - Platform templates use pattern: `/platform/{design-area}/{workload-name}/`
  - Each template contains:
    - `examples/azure-pipelines.yml` - Reference pipeline configuration
    - `_config/` - Environment-specific variables

## Development Patterns

### Pipeline Configuration

1. Workloads extend base templates from `/pipelines/01-workloads/`
2. Configuration follows this structure:

```yaml
workloadSettings:
  configurationFilePath: /path/to/config
  environments: [env-names]
  deploymentScript:
    - name: ScriptName
      scriptExtension: ps1
      arguments: # optional
```

### PowerShell Scripts

- Common deployment scripts in `/common/scripts/`
- Workload-specific scripts in `{workload}/scripts/`
- Functions library in `/common/scripts/functions/`

#### PowerShell Standards

1. Function Structure:

   ```powershell
   [CmdletBinding()]
   function Verb-Noun {
       [CmdletBinding()]
       param(
           [Parameter(Mandatory=$true)]
           [ValidateNotNullOrEmpty()]
           [string]$RequiredParam
       )

       begin {
           # Module imports and static defaults here
           Import-Module Az.KeyVault -ErrorAction Stop
       }

       process {
           # Main logic here
       }

       end {
           # Cleanup here
       }
   }
   ```

2. Code Quality:

   - Run `Invoke-ScriptAnalyzer` with `.vscode/PSScriptAnalyzerSettings.psd1` before commits
   - Use approved verbs and PascalCase for functions and parameters
   - One attribute per line in parameter blocks
   - Use splatting for 3+ parameters

3. Security:

   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   ```

   - Prefer Azure Key Vault for secrets management
   - Use `-ErrorAction Stop` for safe module imports

4. Logging in Azure DevOps:
   ```powershell
   Write-Host "##[group]Deployment Phase"
   # ... deployment steps ...
   Write-Host "##[endgroup]"
   ```

### Testing

- Pipeline tests in `/tests/pipelines/`
- Use Pester framework for PowerShell testing
- Scripts for local testing setup in `/tests/scripts/`

## Common Tasks

### Adding a New Workload

1. Copy template from `_TEMPLATE-COPY-ME-design-area/`
2. Place in appropriate design area folder
3. Customize `azure-pipelines.yml` and configs in `_config/`
4. Add workload-specific deployment scripts

### Debugging Pipelines

- Use `Agent_ListDirectoryItems.ps1` and `Agent_ListEnvironmentVariables.ps1` for debugging
- Check pipeline artifacts in `$(Pipeline.Workspace)`
- Test locally using `/tests/scripts/setup.localTests.ps1`

## Best Practices

1. Use standardized stage templates from `/pipelines/02-stages/`
2. Follow the environment configuration pattern in `_config/` (dev-vars.yml, prd-vars.yml)
3. Implement PowerShell scripts following patterns in `/common/scripts/functions/`
4. Document architectural decisions in `/docs/adrs/`

## Development Environment Setup

1. Git Configuration:
   ```powershell
   git config core.autocrlf input  # For cross-platform compatibility
   ```
2. VS Code Settings:
   - Use provided workspace settings for formatting
   - Enable code actions on save
   - Install recommended extensions

## Documentation Standards

1. Comment-Based Help (Required for all functions):
   ```powershell
   <#
   .SYNOPSIS
       Brief description
   .DESCRIPTION
       Detailed description
   .PARAMETER ParamName
       Parameter description
   .EXAMPLE
       Usage example
   .NOTES
       Additional information
   #>
   ```
2. Pipeline Documentation:
   - Document environment variables
   - Include usage examples
   - Explain configuration options

## Integration Points

- Azure DevOps Pipeline Integration:
  ```yaml
  resources:
    repositories:
      - repository: ReleaseEngine
        type: github
        endpoint: thecloudexplorers
        name: thecloudexplorers/ReleaseEngine
  ```
- PowerShell Azure Resource Deployment:
  - Token replacement via `/common/scripts/Replace-ConfigurationFilesTokens.ps1`
