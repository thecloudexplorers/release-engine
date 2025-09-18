# Release Engine - GitHub Copilot Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Overview

Release Engine is a collection of reusable Azure DevOps deployment pipelines and PowerShell scripts developed by The Cloud Explorers. The repository contains infrastructure-as-code (IaC) deployment workflows, PowerShell scripts for Azure resource management, and Azure DevOps pipeline templates for CI/CD operations.

## Working Effectively

### Prerequisites and Environment Setup
Install required tools before working with the codebase:
- PowerShell Core is REQUIRED: `sudo apt-get install powershell` (if not already available)
- Azure CLI is available: `az --version` (should show version 2.77.0+)
- Bicep CLI is available: `bicep --version` (should show version 0.37.4+)

### Core Development Commands
Bootstrap and validate the repository:
- `cd /home/runner/work/release-engine/release-engine`
- `pwsh -Command "Get-ChildItem -Recurse common/scripts/ -Include '*.ps1'"` -- Lists all PowerShell scripts (completes in <1 second)
- `pwsh -Command "Test-Path common/scripts/Deploy-AzureResource.ps1"` -- Validates core scripts exist (returns True)

### PowerShell Script Validation
Test PowerShell scripts and functions:
- `pwsh -Command "Get-Help common/scripts/Deploy-AzureResource.ps1 -Examples"` -- Shows usage examples (<1 second)
- `pwsh -Command "Get-Help common/scripts/deployBicep.ps1 -Examples"` -- Shows Bicep deployment examples (<1 second)

### Configuration Token Replacement Testing
Test the token replacement functionality (core feature):
- Create test directories: `mkdir -p /tmp/test-config/_config /tmp/test-output`
- Create test metadata file with JSON format including comments (metadata.jsonc)
- Run token replacement: `pwsh -Command "& './common/scripts/Replace-ConfigurationFilesTokens.ps1' -ConfigFilesRootFolder '/tmp/test-config' -CustomOutputFolderPath '/tmp/test-output'"` -- Completes in <2 seconds
- Verify output: `find /tmp/test-output -name "*.yml" -exec cat {} \;`

### Azure DevOps Pipeline Validation
The repository contains Azure DevOps pipeline templates that:
- Build infrastructure artifacts from `/common`, `/pipelines`, and `/templates` directories
- Deploy Azure resources using Bicep templates via ARM deployment tasks
- Execute pre/post deployment PowerShell scripts
- Support multiple environments (dev/prd) with configuration-driven deployments

## Critical Timing and Execution Guidelines

### NEVER CANCEL WARNINGS
- **NEVER CANCEL**: PowerShell script enumeration and validation completes in <1 second
- **NEVER CANCEL**: Token replacement scripts complete in <2 seconds  
- **NEVER CANCEL**: Help and documentation commands complete in <1 second
- All commands in this repository are lightweight and complete quickly (<5 seconds)

### Timeout Settings
Use standard timeouts for all commands:
- PowerShell script execution: 60 seconds (actual completion <2 seconds)
- File operations and validation: 30 seconds (actual completion <1 second)
- Azure CLI validation: 30 seconds (actual completion <1 second)

## Repository Structure and Navigation

### Key Directories
```
.
├── common/
│   ├── pipelines/          # Reusable Azure DevOps pipeline templates
│   └── scripts/            # PowerShell scripts for deployment and configuration
├── docs/
│   └── adrs/              # Architectural Decision Records
├── pipelines/             # Pipeline orchestration templates
└── templates/
    ├── utilities/         # Utility scripts and tools
    └── workloads/         # Workload-specific deployment templates
```

### Critical Files to Know
- `common/scripts/Deploy-AzureResource.ps1` -- Main Azure deployment script
- `common/scripts/Replace-ConfigurationFilesTokens.ps1` -- Configuration token replacement
- `common/scripts/deployBicep.ps1` -- Bicep template deployment 
- `common/scripts/functions/Convert-TokensToValues.ps1` -- Token conversion functions
- `common/pipelines/_config/release-engine.config.yml` -- Pipeline configuration variables
- `common/pipelines/01-orchestrators/alz.devops.workload.orchestrator.yml` -- Main pipeline orchestrator

### PowerShell Script Functions
Core PowerShell functions available:
- **Deploy-AzureResource.ps1**: Deploys Bicep/ARM templates at Tenant, Subscription, or ResourceGroup scope
- **Replace-ConfigurationFilesTokens.ps1**: Processes configuration directories and replaces tokens in files
- **Convert-TokensToValues.ps1**: Core token replacement function with start/end pattern matching
- **deployBicep.ps1**: Simplified Bicep template deployment wrapper

## Validation Scenarios

### Always Test After Making Changes
1. **Script Syntax Validation**: `pwsh -Command "Get-ChildItem -Recurse common/scripts/ -Include '*.ps1' | ForEach-Object { Write-Host 'Testing:' \$_.Name; \$null = \$_ }"`
2. **Token Replacement Validation**: Create test configuration with metadata.jsonc and verify token replacement works
3. **Pipeline Template Validation**: Ensure YAML templates have valid syntax and proper parameter references
4. **Azure CLI Integration**: Verify Azure CLI and Bicep CLI are accessible for deployment scenarios

### Manual Testing Requirements
Since this is an infrastructure and pipeline repository, manual validation involves:
- **Token Processing**: Create test configuration files and verify tokens are properly replaced
- **Script Execution**: Verify PowerShell scripts can be executed and show proper help documentation
- **Pipeline Structure**: Validate Azure DevOps YAML templates maintain proper structure and references

## Common Tasks and Solutions

### Working with Configuration Files
Configuration files use token replacement patterns:
- Default tokens: `#{tokenName}#` (start: `#{`, end: `}#`)  
- Metadata stored in `metadata.jsonc` files (JSON with comments)
- Token replacement processes entire directory structures
- Always test token replacement after modifying configuration templates

### PowerShell Script Development
When modifying PowerShell scripts:
- All scripts require PowerShell Core (`#Requires -PSEdition Core`)
- Use proper error handling: `$ErrorActionPreference = 'Stop'`
- Include proper help documentation with `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
- Test script help: `Get-Help scriptname.ps1 -Examples`
- Always validate script syntax before committing

### Azure DevOps Pipeline Development
Pipeline templates follow this structure:
- **01-orchestrators**: Main workflow orchestration
- **02-stages**: Pipeline stage definitions  
- **03-jobs**: Individual job definitions
- **04-steps**: Reusable step templates
- Use template parameters extensively for reusability
- Always reference templates using `@release-engine` syntax

### Common Validation Commands
```bash
# Repository structure validation
ls -la
find . -name "*.ps1" | head -10
find . -name "*.yml" | head -10

# PowerShell validation
pwsh -Command "Get-ChildItem -Recurse common/scripts/ -Include '*.ps1'"
pwsh -Command "Test-Path common/scripts/Deploy-AzureResource.ps1"

# Token replacement testing
mkdir -p /tmp/test-config/_config
# Create metadata.jsonc and test configuration files
pwsh -Command "& './common/scripts/Replace-ConfigurationFilesTokens.ps1' -ConfigFilesRootFolder '/tmp/test-config' -CustomOutputFolderPath '/tmp/test-output'"
```

## Troubleshooting and Best Practices

### Common Issues
1. **Missing metadata.jsonc**: Token replacement requires `metadata.jsonc` in configuration directories
2. **PowerShell execution policy**: Use `pwsh` command for cross-platform PowerShell Core
3. **Azure module dependencies**: Scripts expect Az PowerShell modules (not available in this environment, but documented in script requirements)
4. **Path references**: Always use absolute paths when referencing templates and scripts

### Best Practices
- Always validate PowerShell scripts using `Get-Help` before committing
- Test token replacement functionality with sample data before production use
- Use proper Azure DevOps template parameterization for reusability
- Follow the established directory structure for new components
- Include comprehensive help documentation in all PowerShell scripts

### File Extensions and Formats
- PowerShell scripts: `.ps1`
- Azure DevOps pipelines: `.yml` 
- Configuration metadata: `.jsonc` (JSON with comments)
- Parameter files: `.yml` for Azure DevOps variables

## Repository Statistics
- Repository size: ~664KB
- Total YAML files: 21
- Main PowerShell scripts: 5 in common/scripts/
- All operations complete in <5 seconds