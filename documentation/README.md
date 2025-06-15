# Risk Management Trading App - Documentation

## 📚 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [API Documentation](#api-documentation)
4. [User Guides](#user-guides)
5. [Diagrams](#diagrams)
6. [Development](#development)

## Overview

This documentation provides comprehensive information about the Risk Management Trading App, a Flutter-based application designed for traders to monitor their trading performance and manage risk effectively.

### Key Features
- Real-time P&L tracking with interactive charts
- Dynamic risk management with customizable parameters
- MVVM architecture with reactive state management
- Professional-grade risk calculations
- Static and dynamic drawdown modes

## Architecture

The application follows the **Model-View-ViewModel (MVVM)** pattern with clean separation of concerns:

```
├── Model Layer (Data & Business Logic)
│   ├── Data Models (Trade, RiskManagement)
│   ├── Repository Pattern (TradeRepository)
│   └── Service Layer (RiskManagementService)
├── ViewModel Layer (State Management)
│   ├── RiskManagementViewModel
│   └── DialogViewModel
└── View Layer (UI Components)
    ├── Views (HomeView)
    ├── Widgets (TradeChartWidget, RiskControlsWidget)
    └── Dialogs (InputDialog)
```

## API Documentation

### Core Classes
- **[Model Classes](api/models.md)** - Data structures and business logic
- **[Repository Classes](api/repositories.md)** - Data access layer
- **[Service Classes](api/services.md)** - Business logic orchestration
- **[ViewModel Classes](api/viewmodels.md)** - State management
- **[View Classes](api/views.md)** - UI components

### Quick Reference
- **[Risk Calculations](api/risk-calculations.md)** - Mathematical formulas and logic
- **[State Management](api/state-management.md)** - Signals and reactive programming
- **[Error Handling](api/error-handling.md)** - Exception handling patterns

## User Guides

### Getting Started
- **[Installation Guide](guides/installation.md)** - Setup and configuration
- **[Quick Start](guides/quick-start.md)** - First-time user walkthrough
- **[Basic Usage](guides/basic-usage.md)** - Common tasks and workflows

### Advanced Features
- **[Risk Management Setup](guides/risk-management.md)** - Configuring risk parameters
- **[Dynamic Drawdown](guides/dynamic-drawdown.md)** - Understanding dynamic mode
- **[Trading Statistics](guides/statistics.md)** - Interpreting performance metrics

### Troubleshooting
- **[Common Issues](guides/troubleshooting.md)** - FAQ and solutions
- **[Performance Tips](guides/performance.md)** - Optimization recommendations

## Diagrams

### System Architecture
- **[MVVM Architecture](diagrams/mvvm-architecture.md)** - High-level system design
- **[Data Flow](diagrams/data-flow.md)** - Information flow through layers
- **[Component Interaction](diagrams/component-interaction.md)** - How components communicate

### User Flows
- **[Trade Entry Flow](diagrams/trade-entry-flow.md)** - Adding new trades
- **[Risk Configuration Flow](diagrams/risk-config-flow.md)** - Setting up risk parameters
- **[Dynamic Drawdown Flow](diagrams/dynamic-drawdown-flow.md)** - Dynamic mode operation

### Business Logic
- **[Risk Calculation Flow](diagrams/risk-calculation-flow.md)** - Risk assessment process
- **[Balance Update Flow](diagrams/balance-update-flow.md)** - Balance tracking mechanism

## Development

### Development Setup
- **[Environment Setup](guides/development-setup.md)** - Development environment configuration
- **[Testing Strategy](guides/testing.md)** - Unit and integration testing
- **[Code Style](guides/code-style.md)** - Coding standards and conventions

### Contributing
- **[Contributing Guidelines](guides/contributing.md)** - How to contribute to the project
- **[Pull Request Process](guides/pr-process.md)** - Code review and merge process

### Deployment
- **[Build Process](guides/build.md)** - Creating production builds
- **[Platform-specific Builds](guides/platform-builds.md)** - iOS, Android, Web, Desktop

## Quick Links

| Component | Purpose | Documentation |
|-----------|---------|---------------|
| `RiskManagement` | Core risk calculations | [Models API](api/models.md#riskmanagement) |
| `Trade` | Trade data structure | [Models API](api/models.md#trade) |
| `TradeRepository` | Data persistence | [Repository API](api/repositories.md#traderepository) |
| `RiskManagementService` | Business logic | [Service API](api/services.md#riskmanagementservice) |
| `RiskManagementViewModel` | State management | [ViewModel API](api/viewmodels.md#riskmanagementviewmodel) |
| `HomeView` | Main UI screen | [View API](api/views.md#homeview) |

## Version Information

- **Current Version**: 1.0.0
- **Flutter Version**: 3.x
- **Minimum Dart SDK**: 3.0.0
- **Target Platforms**: iOS, Android, Web, Desktop

## Support

For questions, issues, or feature requests:
- Check the [Troubleshooting Guide](guides/troubleshooting.md)
- Review [Common Issues](guides/troubleshooting.md#common-issues)
- Submit issues via the project repository

---

*Last Updated: December 2024*