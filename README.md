# Release Engine

## Overview

Release Engine is a comprehensive three-tier solution that implements the Facade Pattern to simplify CI/CD pipeline implementation for Azure DevOps. Developed by The Cloud Explorers, this solution abstracts complexity across three distinct repositories, enabling teams to focus on business logic while leveraging battle-tested deployment patterns.

## Architecture

The Release Engine follows a layered architecture with clear separation of concerns:

- **Core Layer** (this repository): Foundational pipeline components, PowerShell scripts, and orchestrators
- **Abstraction Layer**: Workload patterns and Infrastructure as Code templates
- **Configuration Layer**: Simple configuration files that act as a facade for end users

## Features

- **Facade Pattern Implementation**: Hide complex pipeline logic behind simple configuration
- **Reusable Pipeline Components**: Modular orchestrators, stages, jobs, and steps
- **Infrastructure as Code**: Azure Bicep templates with Azure Verified Modules integration  
- **Multi-Environment Support**: Automated deployment across dev/test/prod environments
- **PowerShell Integration**: Standardized deployment scripts and utility functions
- **Dependency Management**: Complex stage dependency resolution and orchestration

## Documentation

📚 **[Complete Documentation](./docs/README.md)** - Start here for comprehensive guides

Key documents:

- [Solution Architecture](./docs/Release-Engine-Solution-Architecture.md) - Detailed architectural overview
- [Automated Release Management](./docs/AUTOMATED-RELEASE-MANAGEMENT.md) - CI/CD pipeline for automated releases
- [ADR Template](./docs/adrs/00-adr-template.md) - Architectural decision record template

## Quick Start

This repository serves as the **Core Layer** in a three-repository solution:

1. **release-engine-core** (this repo) - Core pipeline components and scripts
2. **release-engine-pattern-template** - Deployment patterns and templates  
3. **release-engine-*-configuration** - Simple configuration repositories for end users

## Getting Started

To use the Release Engine:

1. Choose an appropriate workload pattern from the pattern repository
2. Create a new configuration repository using the pattern
3. Configure your environments and parameters in simple YAML files
4. Let the Release Engine handle the complex pipeline orchestration

## Repository Structure

```text
├── common/
│   ├── pipelines/           # Reusable pipeline templates
│   │   ├── 01-orchestrators/ # High-level orchestration
│   │   ├── 02-stages/       # Build and deploy stages  
│   │   ├── 03-jobs/         # Individual job templates
│   │   └── 04-steps/        # Atomic pipeline steps
│   └── scripts/             # PowerShell deployment scripts
├── docs/                    # Documentation
└── templates/               # Project templates
```

## Benefits

- **Simplified Configuration**: Abstract away pipeline complexity
- **Consistent Patterns**: Standardized deployment across organization  
- **Rapid Development**: Quick setup of new workloads
- **Best Practices**: Built-in Azure and DevOps best practices
- **Scalable Architecture**: Easy to extend and maintain

## Contributing

Please refer to our documentation for guidance on:

- Creating new workload patterns
- Extending core pipeline functionality  
- Following PowerShell coding standards
- Architectural decision making

## License

This project is licensed under the terms specified in the LICENSE file.
