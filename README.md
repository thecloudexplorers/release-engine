# Release Engine

A comprehensive collection of reusable Azure DevOps deployment pipelines and PowerShell scripts developed by The Cloud Explorers, designed to simplify and standardize CI/CD implementations for both application code and infrastructure deployments.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

## 🔍 Overview

Release Engine is a battle-tested DevOps framework that provides:

- **Standardized CI/CD Patterns**: Pre-built Azure DevOps pipelines following industry best practices
- **Infrastructure as Code**: Comprehensive Bicep templates and deployment scripts
- **Token Replacement System**: Flexible configuration management across environments
- **Modular Architecture**: Reusable components that can be easily integrated into existing projects
- **Enterprise-Ready**: Designed for scalable, enterprise-grade deployments

The primary goal is to reduce the time and complexity involved in setting up robust CI/CD pipelines while maintaining consistency and reliability across deployments.

## ✨ Features

### 🔄 Reusable Pipelines
- **Orchestrator Pipelines**: High-level workflow orchestration for complex deployments
- **Build Pipelines**: Standardized artifact creation and validation
- **Deploy Pipelines**: Multi-stage deployment with approval gates
- **Infrastructure Pipelines**: Automated infrastructure provisioning and updates

### 🏗️ Infrastructure as Code
- **Bicep Templates**: Modern ARM template alternatives with enhanced readability
- **Deployment Scripts**: PowerShell automation for complex deployment scenarios
- **Configuration Management**: Environment-specific parameter handling
- **Resource Lifecycle**: Complete infrastructure lifecycle management

### 📜 PowerShell Automation
- **Token Replacement**: Dynamic configuration file processing
- **Deployment Utilities**: Common deployment tasks and operations
- **Validation Scripts**: Pre and post-deployment validation
- **Error Handling**: Robust error handling and logging

### 🔧 Customization & Integration
- **Template System**: Copy-and-customize templates for new workloads
- **Configuration-Driven**: YAML-based configuration for easy customization
- **Modular Design**: Pick and choose components based on your needs
- **Extensible Framework**: Easy to extend with custom functionality

## 📋 Prerequisites

Before using Release Engine, ensure you have:

- **Azure DevOps Organization** with appropriate permissions
- **Azure Subscription** with Contributor access or higher
- **PowerShell 7.0+** for local script execution
- **Azure CLI** or **Azure PowerShell** for authentication
- **Git** for version control operations

### Required Azure DevOps Extensions
- **Azure DevOps Service Connections** configured for target Azure subscriptions
- **Agent Pools** with appropriate capabilities (PowerShell, Azure CLI)

## 🚀 Quick Start

### 1. Repository Setup
```bash
# Clone the repository
git clone https://github.com/thecloudexplorers/release-engine.git
cd release-engine
```

### 2. Basic Pipeline Integration
```yaml
# In your Azure DevOps pipeline
resources:
  repositories:
  - repository: releaseEngine
    type: git
    name: release-engine
    ref: refs/heads/main

stages:
- template: common/pipelines/02-stages/iac.deploy.stage.yml@releaseEngine
  parameters:
    workload: 'your-workload-name'
    environment: 'dev'
```

### 3. Configuration Setup
1. Copy a template from `templates/workloads/platform/_TEMPLATE-COPY-ME-design-area/`
2. Customize the configuration files for your specific needs
3. Update the pipeline references in your Azure DevOps project

## 📁 Project Structure

```
release-engine/
├── common/                     # Shared components and utilities
│   ├── pipelines/             # Reusable pipeline templates
│   │   ├── 01-orchestrators/  # High-level workflow orchestration
│   │   ├── 02-stages/         # Pipeline stage definitions
│   │   ├── 03-jobs/           # Specific job implementations
│   │   └── 04-steps/          # Individual step templates
│   └── scripts/               # Shared PowerShell utilities
│       └── functions/         # Reusable PowerShell functions
├── docs/                      # Documentation
│   ├── adrs/                  # Architectural Decision Records
│   └── diagrams/              # Architecture diagrams
├── pipelines/                 # Project-specific pipelines
├── templates/                 # Template resources
│   ├── utilities/             # Utility templates and scripts
│   └── workloads/             # Workload-specific templates
└── README.md                  # This file
```

## 📚 Documentation

For detailed information, please refer to our comprehensive documentation:

- **[Setup Guide](docs/SETUP.md)** - Detailed installation and configuration instructions
- **[Usage Guide](docs/USAGE.md)** - Step-by-step usage examples and workflows
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System architecture and design patterns
- **[Examples](docs/EXAMPLES.md)** - Real-world implementation examples
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Contributing Guide](docs/CONTRIBUTING.md)** - How to contribute to the project
- **[ADRs](docs/adrs/)** - Architectural Decision Records

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details on:

- Code of conduct
- Development workflow
- Submitting pull requests
- Reporting issues
- Coding standards

## 💬 Support

- **Issues**: Report bugs and request features via [GitHub Issues](https://github.com/thecloudexplorers/release-engine/issues)
- **Discussions**: Join community discussions in [GitHub Discussions](https://github.com/thecloudexplorers/release-engine/discussions)
- **Documentation**: Check our [documentation](docs/) for detailed guides

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ by [The Cloud Explorers](https://github.com/thecloudexplorers)**
