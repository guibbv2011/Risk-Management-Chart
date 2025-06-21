# Risk Management Trading App - Documentation

## 📚 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [API Documentation](#api-documentation)
4. [User Guides](#user-guides)
5. [Diagrams](#diagrams)
6. [Storage Implementation](#storage-implementation)
7. [Troubleshooting](#troubleshooting)

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
- **[Risk Calculations](api/risk-calculations.md)** - Mathematical formulas and logic

## User Guides

### Getting Started
- **[Quick Start](guides/quick-start.md)** - First-time user walkthrough

## Diagrams

### System Architecture
- **[MVVM Architecture](diagrams/mvvm-architecture.md)** - High-level system design
- **[Data Flow](diagrams/data-flow.md)** - Information flow through layers
- **[Trade Entry Flow](diagrams/trade-entry-flow.md)** - Adding new trades

## Storage Implementation

### Storage Documentation
- **[Storage Implementation](storage/STORAGE_IMPLEMENTATION.md)** - Technical storage details
- **[Local Storage Summary](storage/LOCAL_STORAGE_SUMMARY.md)** - Local storage overview
- **[Storage Troubleshooting](storage/STORAGE_TROUBLESHOOTING.md)** - Storage-related issues
- **[Web Persistence Debugging](storage/WEB_PERSISTENCE_DEBUGGING_GUIDE.md)** - Web-specific debugging

## Troubleshooting

- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Fixes Summary](FIXES_SUMMARY.md)** - Summary of implemented fixes

## Quick Links

| Component | Purpose | Status |
|-----------|---------|--------|
| `RiskManagement` | Core risk calculations | ✅ Implemented |
| `Trade` | Trade data structure | ✅ Implemented |
| `TradeRepository` | Data persistence | ✅ Implemented |
| `RiskManagementService` | Business logic | ✅ Implemented |
| `RiskManagementViewModel` | State management | ✅ Implemented |
| `HomeView` | Main UI screen | ✅ Implemented |

## Version Information

- **Current Version**: 1.0.0
- **Flutter Version**: 3.x
- **Minimum Dart SDK**: 3.0.0
- **Target Platforms**: iOS, Android, Web, Desktop

## Support

For questions, issues, or feature requests:
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review the project's main README.md for usage instructions
- Submit issues via the project repository

---

*Last Updated: December 2024*