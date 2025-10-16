# Contributing Guide

Thank you for your interest in contributing to the Release Engine! This guide outlines how to contribute effectively to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Contribution Types](#contribution-types)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)
- [Community and Support](#community-and-support)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please review and follow our Code of Conduct:

### Our Pledge

- **Be Respectful**: Treat everyone with respect and kindness
- **Be Inclusive**: Welcome contributors from all backgrounds and experience levels
- **Be Collaborative**: Work together constructively and help each other learn
- **Be Professional**: Maintain professional communication in all interactions

### Unacceptable Behavior

- Harassment, discrimination, or intimidation of any form
- Offensive, derogatory, or inappropriate language
- Personal attacks or public/private harassment
- Publishing others' private information without permission

### Reporting

If you experience or witness unacceptable behavior, please report it to the maintainers at [maintainers@thecloudexplorers.com](mailto:maintainers@thecloudexplorers.com).

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Git** installed and configured
- **PowerShell 7.0+** for script development
- **Azure CLI** for testing Azure integrations
- **Visual Studio Code** (recommended) with extensions:
  - PowerShell
  - Azure Account
  - Azure Pipelines
  - Bicep
  - YAML

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/release-engine.git
   cd release-engine
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/thecloudexplorers/release-engine.git
   ```

### Development Environment Setup

1. **Install development tools**:
   ```bash
   # Install PowerShell modules for development
   Install-Module -Name Pester -Force          # For testing
   Install-Module -Name PSScriptAnalyzer -Force # For linting
   Install-Module -Name platyPS -Force         # For documentation
   ```

2. **Configure Git hooks** (optional but recommended):
   ```bash
   # Set up pre-commit hooks for code quality
   cp .github/hooks/pre-commit .git/hooks/
   chmod +x .git/hooks/pre-commit
   ```

## Development Workflow

### Branch Strategy

We use a simplified Git flow:

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/*`**: Individual feature branches
- **`bugfix/*`**: Bug fix branches
- **`hotfix/*`**: Critical production fixes

### Creating a Feature Branch

1. **Update your fork**:
   ```bash
   git checkout main
   git pull upstream main
   git push origin main
   ```

2. **Create feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes** and commit regularly:
   ```bash
   git add .
   git commit -m "feat: add new pipeline template"
   ```

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat(pipelines): add support for multi-region deployment
fix(scripts): resolve token replacement issue with special characters
docs(readme): update setup instructions
chore(deps): update Azure CLI requirements
```

## Contribution Types

### 1. Bug Reports

Help us improve by reporting bugs:

1. **Check existing issues** to avoid duplicates
2. **Use the bug report template**
3. **Provide detailed information**:
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Error messages/logs

### 2. Feature Requests

Suggest new features or improvements:

1. **Check existing feature requests**
2. **Use the feature request template**
3. **Explain the use case** and benefits
4. **Provide implementation ideas** if possible

### 3. Code Contributions

#### Pipeline Templates

When adding new pipeline templates:

```yaml
# Template structure
parameters:
- name: workload
  type: string
- name: environment
  type: string
- name: serviceConnection
  type: string

jobs:
- job: YourJob
  displayName: 'Descriptive Job Name'
  steps:
  - template: ../04-steps/your-step.yml
    parameters:
      workload: ${{ parameters.workload }}
```

#### PowerShell Scripts

Follow PowerShell best practices:

```powershell
#Requires -PSEdition Core

<#
.SYNOPSIS
    Brief description of the script

.DESCRIPTION
    Detailed description of what the script does

.PARAMETER ParameterName
    Description of the parameter

.EXAMPLE
    Example usage of the script

.NOTES
    Author: Your Name
    Version: 1.0.0
    Source: https://github.com/thecloudexplorers/release-engine
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RequiredParameter,
    
    [Parameter()]
    [string]$OptionalParameter = "default-value"
)

# Set error action preference
$ErrorActionPreference = 'Stop'

try {
    # Script logic here
    Write-Host "Processing $RequiredParameter"
    
    # Return results
    return $result
}
catch {
    Write-Error "An error occurred: $_"
    throw
}
```

#### Bicep Templates

Follow Azure Bicep best practices:

```bicep
@description('The name of the workload')
param workloadName string

@description('The environment name')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('The Azure region for deployment')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

// Variables
var resourcePrefix = '${workloadName}-${environment}'

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'st${replace(resourcePrefix, '-', '')}${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Outputs
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
```

## Code Standards

### PowerShell Standards

1. **Use PowerShell 7+ syntax**
2. **Follow PSScriptAnalyzer rules**:
   ```powershell
   # Run PSScriptAnalyzer
   Invoke-ScriptAnalyzer -Path ./scripts/ -Recurse
   ```

3. **Use approved verbs**:
   ```powershell
   # Good
   Get-Configuration
   Set-Environment
   
   # Avoid
   Retrieve-Configuration
   Change-Environment
   ```

4. **Parameter validation**:
   ```powershell
   param (
       [Parameter(Mandatory)]
       [ValidateNotNullOrEmpty()]
       [string]$Path,
       
       [Parameter()]
       [ValidateSet('dev', 'test', 'prod')]
       [string]$Environment = 'dev'
   )
   ```

5. **Error handling**:
   ```powershell
   try {
       # Risky operation
   }
   catch [System.IO.FileNotFoundException] {
       Write-Error "Configuration file not found: $_"
       throw
   }
   catch {
       Write-Error "Unexpected error: $_"
       throw
   }
   ```

### YAML Standards

1. **Use consistent indentation** (2 spaces)
2. **Add meaningful comments**:
   ```yaml
   # Deploy infrastructure to target environment
   - template: common/pipelines/02-stages/iac.deploy.stage.yml
     parameters:
       workload: ${{ parameters.workload }}
       environment: ${{ parameters.environment }}
   ```

3. **Use descriptive names**:
   ```yaml
   jobs:
   - job: DeployInfrastructure
     displayName: 'Deploy Infrastructure Components'
   ```

4. **Group related parameters**:
   ```yaml
   parameters:
   # Workload configuration
   - name: workload
     type: string
   - name: environment
     type: string
   
   # Azure configuration
   - name: serviceConnection
     type: string
   - name: location
     type: string
   ```

### Bicep Standards

1. **Use descriptive parameter names**
2. **Include parameter descriptions**
3. **Use parameter constraints**:
   ```bicep
   @minLength(3)
   @maxLength(24)
   param storageAccountName string
   ```

4. **Organize resources logically**
5. **Include outputs for important values**

## Testing Guidelines

### PowerShell Testing

Use Pester for PowerShell script testing:

```powershell
# tests/Convert-TokensToValues.Tests.ps1
Describe "Convert-TokensToValues" {
    BeforeAll {
        # Import the function
        . "$PSScriptRoot/../common/scripts/functions/Convert-TokensToValues.ps1"
        
        # Create test files
        $testConfig = @{
            "environment" = "test"
            "location" = "East US"
        }
    }
    
    Context "Token replacement" {
        It "Should replace simple tokens" {
            # Arrange
            $template = "Environment: #{environment}#"
            $tempFile = New-TemporaryFile
            $template | Out-File -FilePath $tempFile.FullName
            
            # Act
            Convert-TokensToValues -MetadataCollection $testConfig -TargetFilePath $tempFile.FullName -StartTokenPattern "#{" -EndTokenPattern "}#"
            
            # Assert
            $result = Get-Content -Path $tempFile.FullName -Raw
            $result | Should -Be "Environment: test"
            
            # Cleanup
            Remove-Item -Path $tempFile.FullName
        }
    }
}
```

### Pipeline Testing

Test pipeline templates:

```yaml
# tests/pipeline-test.yml
trigger: none

resources:
  repositories:
  - repository: self
    type: git

variables:
- name: testWorkload
  value: 'test-workload'

stages:
- template: ../common/pipelines/02-stages/iac.build.stage.yml
  parameters:
    workload: $(testWorkload)
```

### Integration Testing

Create integration tests for complete workflows:

```bash
# scripts/test-integration.sh
#!/bin/bash

echo "Running integration tests..."

# Test pipeline template syntax
az pipelines validate --yaml-path azure-pipelines.yml

# Test Bicep templates
for template in infrastructure/*.bicep; do
    echo "Validating $template"
    az bicep build --file "$template" --validate-only
done

# Test PowerShell scripts
pwsh -Command "Invoke-Pester tests/ -Output Detailed"

echo "Integration tests completed"
```

## Documentation Standards

### Code Documentation

1. **PowerShell**: Use comment-based help
2. **Bicep**: Use `@description` decorators
3. **YAML**: Use inline comments for complex logic

### Markdown Documentation

1. **Use consistent formatting**
2. **Include table of contents** for long documents
3. **Add code examples** with syntax highlighting
4. **Use relative links** for internal references

### Documentation Structure

```
docs/
├── README.md              # Overview and quick start
├── SETUP.md              # Detailed setup instructions
├── USAGE.md              # Usage examples and patterns
├── CONTRIBUTING.md       # This file
├── TROUBLESHOOTING.md    # Common issues and solutions
├── ARCHITECTURE.md       # System architecture
├── EXAMPLES.md           # Practical examples
└── adrs/                 # Architectural Decision Records
    ├── 00-adr-template.md
    └── 01-your-decision.md
```

## Pull Request Process

### Before Submitting

1. **Test your changes locally**
2. **Run code quality checks**:
   ```bash
   # PowerShell linting
   Invoke-ScriptAnalyzer -Path ./scripts/ -Recurse
   
   # Bicep validation
   az bicep build --file infrastructure/main.bicep --validate-only
   
   # YAML validation
   yamllint .github/workflows/
   ```

3. **Update documentation** if needed
4. **Add tests** for new functionality

### Pull Request Template

Use our PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project standards
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### Review Process

1. **Automated checks** must pass
2. **Peer review** by maintainers
3. **Testing** in staging environment
4. **Approval** by code owners

### Merge Requirements

- All CI checks passing
- At least one approval from maintainers
- No merge conflicts
- Branch up to date with target

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Workflow

1. **Feature freeze** on develop branch
2. **Create release branch**: `release/v1.2.0`
3. **Final testing** and bug fixes
4. **Update version numbers** and changelog
5. **Merge to main** and tag release
6. **Create GitHub release** with release notes

## Community and Support

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Pull Requests**: Code reviews and contributions

### Getting Help

- Review existing documentation
- Search GitHub issues
- Ask in GitHub Discussions
- Contact maintainers for sensitive issues

### Recognition

Contributors are recognized in:

- GitHub contributor list
- Release notes
- Project documentation
- Annual contributor appreciation

## Questions?

If you have questions about contributing, please:

1. Check this guide first
2. Search existing GitHub issues
3. Ask in GitHub Discussions
4. Contact maintainers directly

Thank you for contributing to the Release Engine! Your contributions help make CI/CD better for everyone. 🚀