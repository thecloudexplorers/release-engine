# Documentation Index

Welcome to the Release Engine documentation! This index provides an overview of all available documentation and guides you to the right resources for your needs.

## 📖 Documentation Overview

The Release Engine documentation is organized into several key areas to help you quickly find the information you need:

## 🚀 Getting Started

### [README](../README.md)
**Start here!** Overview of the project, features, and quick start guide.

### [Setup Guide](SETUP.md)
Comprehensive setup instructions including:
- Prerequisites and requirements
- Azure DevOps configuration
- Service connection setup
- Initial environment configuration
- Verification steps

### [Usage Guide](USAGE.md)
Detailed usage instructions covering:
- Basic pipeline integration
- Configuration management
- Infrastructure deployment
- Application deployment
- Multi-environment workflows

## 📚 Detailed Guides

### [Examples](EXAMPLES.md)
Real-world implementation examples including:
- Basic infrastructure deployments
- Application + infrastructure pipelines
- Multi-environment scenarios
- Advanced deployment patterns
- Configuration examples

### [Architecture](ARCHITECTURE.md)
System architecture and design documentation:
- High-level architecture overview
- Design principles
- Component interactions
- Security architecture
- Extensibility model

### [Troubleshooting](TROUBLESHOOTING.md)
Solutions for common issues:
- Pipeline problems
- Azure authentication issues
- Configuration problems
- PowerShell script errors
- Performance troubleshooting

## 🤝 Contributing

### [Contributing Guide](CONTRIBUTING.md)
Information for contributors including:
- Code of conduct
- Development workflow
- Code standards
- Testing guidelines
- Pull request process

### [Architectural Decision Records (ADRs)](adrs/)
Documentation of important architectural decisions:
- [ADR Template](adrs/00-adr-template.md) - Template for creating new ADRs

## 📋 Reference Documentation

### Quick Reference Tables

#### Template Hierarchy
| Level | Purpose | Examples |
|-------|---------|----------|
| **Orchestrators** | End-to-end workflows | `alz.devops.workload.orchestrator.yml` |
| **Stages** | Major pipeline phases | `iac.build.stage.yml`, `iac.deploy.stage.yml` |
| **Jobs** | Specific tasks within stages | `iac.build.job.yml`, `iac.deploy.job.yml` |
| **Steps** | Atomic operations | `token-replacement.yml`, `bicep-deployment.yml` |

#### Common Parameters
| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `workload` | string | Workload identifier | `my-application` |
| `environment` | string | Target environment | `dev`, `test`, `prod` |
| `serviceConnection` | string | Azure service connection | `azure-connection-dev` |
| `location` | string | Azure region | `East US 2` |

#### Configuration Files
| File | Purpose | Location |
|------|---------|----------|
| `metadata.jsonc` | Environment-specific metadata | `config/{environment}/` |
| `parameters.json` | Bicep parameters | `config/{environment}/` |
| `azure-pipelines.yml` | Main pipeline definition | Project root |

## 🔗 External Resources

### Azure DevOps Documentation
- [Azure Pipelines Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [YAML Schema Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [Template Expressions](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions)

### Azure Documentation
- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/azure/)

### PowerShell Resources
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)

## 🎯 Documentation by Use Case

### I want to...

#### Get started with Release Engine
1. Read the [README](../README.md)
2. Follow the [Setup Guide](SETUP.md)
3. Try the basic examples in [Usage Guide](USAGE.md)

#### Deploy infrastructure only
1. Review [Infrastructure Deployment](USAGE.md#infrastructure-deployment) in Usage Guide
2. Check [Infrastructure Examples](EXAMPLES.md#infrastructure-only-deployments)
3. Understand the [Architecture](ARCHITECTURE.md#pipeline-architecture)

#### Deploy applications with infrastructure
1. Study [Application Deployment](USAGE.md#application-deployment) patterns
2. Review [Application Examples](EXAMPLES.md#application-deployments)
3. Follow [Multi-Environment Workflows](USAGE.md#multi-environment-workflows)

#### Implement advanced deployment patterns
1. Review [Advanced Scenarios](USAGE.md#advanced-scenarios)
2. Study [Advanced Patterns](EXAMPLES.md#advanced-patterns) examples
3. Understand [Deployment Patterns](ARCHITECTURE.md#deployment-patterns)

#### Troubleshoot issues
1. Check [Troubleshooting Guide](TROUBLESHOOTING.md) for your specific issue
2. Review [Common Issues](TROUBLESHOOTING.md#getting-help) section
3. Search existing [GitHub Issues](https://github.com/thecloudexplorers/release-engine/issues)

#### Contribute to the project
1. Read the [Contributing Guide](CONTRIBUTING.md)
2. Review [Code Standards](CONTRIBUTING.md#code-standards)
3. Understand the [Development Workflow](CONTRIBUTING.md#development-workflow)

#### Understand the architecture
1. Start with [Architecture Overview](ARCHITECTURE.md)
2. Review [Design Principles](ARCHITECTURE.md#design-principles)
3. Study [System Components](ARCHITECTURE.md#system-components)

## 📝 Documentation Conventions

### File Naming
- Use descriptive, lowercase names with hyphens
- Include appropriate file extensions (`.md`, `.yml`, `.ps1`)
- Use consistent naming patterns across environments

### Markdown Style
- Use proper heading hierarchy (H1 → H2 → H3)
- Include table of contents for long documents
- Use code blocks with syntax highlighting
- Include examples and practical scenarios

### Code Examples
- Provide complete, working examples
- Include necessary context and setup
- Use realistic parameter values
- Add explanatory comments

## 🔄 Documentation Updates

### Staying Current
The Release Engine documentation is continuously updated. To stay current:

1. **Watch the repository** for updates
2. **Check release notes** for documentation changes
3. **Review ADRs** for architectural decisions
4. **Participate in discussions** for clarifications

### Feedback and Improvements
Help improve the documentation:

1. **Report issues** with documentation
2. **Suggest improvements** via GitHub Issues
3. **Contribute updates** via Pull Requests
4. **Share your experiences** in GitHub Discussions

## 📞 Getting Help

### Self-Service Resources
1. Search this documentation
2. Check [Troubleshooting Guide](TROUBLESHOOTING.md)
3. Review [Examples](EXAMPLES.md)
4. Search [GitHub Issues](https://github.com/thecloudexplorers/release-engine/issues)

### Community Support
1. [GitHub Discussions](https://github.com/thecloudexplorers/release-engine/discussions)
2. [GitHub Issues](https://github.com/thecloudexplorers/release-engine/issues) for bugs and feature requests

### Direct Contact
For sensitive issues or enterprise support:
- Contact the maintainers via the repository
- Create a private issue for security concerns

---

**Last Updated**: This documentation index is automatically updated with each release. For the most current information, always refer to the latest version in the main branch.