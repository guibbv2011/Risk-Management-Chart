# MVVM Architecture Diagram

## Overview

The Risk Management Trading App follows the **Model-View-ViewModel (MVVM)** architectural pattern, which provides clear separation of concerns and enables reactive programming with excellent testability.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                           VIEW LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────────────┐ │
│  │  HomeView   │  │ TradeChartWidget │  │ RiskControlsWidget  │ │
│  │             │  │                  │  │                     │ │
│  │ - Main UI   │  │ - P&L Chart      │  │ - Control Buttons   │ │
│  │ - Scaffold  │  │ - Visualization  │  │ - Risk Display      │ │
│  │ - AppBar    │  │ - Interactions   │  │ - Input Triggers    │ │
│  └─────────────┘  └──────────────────┘  └─────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    InputDialog                              │ │
│  │  - User Input Forms                                         │ │
│  │  - Validation UI                                            │ │
│  │  - Dynamic Drawdown Toggle                                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Data Binding & Events
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                        VIEWMODEL LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐ │
│  │  RiskManagementViewModel    │  │     DialogViewModel         │ │
│  │                             │  │                             │ │
│  │ - State Management          │  │ - Dialog State              │ │
│  │ - Business Logic            │  │ - Input Validation          │ │
│  │ - Reactive Signals          │  │ - Form Management           │ │
│  │ - Error Handling            │  │ - Toggle States             │ │
│  │ - UI Interactions           │  │                             │ │
│  │                             │  │ Signals:                    │ │
│  │ Signals:                    │  │ - dialogTitle               │ │
│  │ - trades                    │  │ - dialogInputValue          │ │
│  │ - riskSettings              │  │ - dialogError               │ │
│  │ - statistics                │  │ - isDynamicMaxDrawdown      │ │
│  │ - riskStatus                │  │                             │ │
│  │ - isLoading                 │  │                             │ │
│  │ - errorMessage              │  │                             │ │
│  └─────────────────────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Service Calls
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                         MODEL LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│                         SERVICE LAYER                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              RiskManagementService                          │ │
│  │                                                             │ │
│  │ - Business Logic Orchestration                              │ │
│  │ - Risk Validation                                           │ │
│  │ - Trade Processing                                          │ │
│  │ - Statistics Calculation                                    │ │
│  │ - Error Management                                          │ │
│  │                                                             │ │
│  │ Methods:                                                    │ │
│  │ - addTrade(result)                                          │ │
│  │ - getTradingStatistics()                                    │ │
│  │ - checkRiskStatus()                                         │ │
│  │ - validateRiskSettings()                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                   │                             │
│                                   │ Repository Calls            │
│                                   ▼                             │
│                        REPOSITORY LAYER                        │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                 TradeRepository                             │ │
│  │                                                             │ │
│  │ Abstract Interface:          In-Memory Implementation:      │ │
│  │ - getAllTrades()             - InMemoryTradeRepository      │ │
│  │ - addTrade(trade)            - List<Trade> storage          │ │
│  │ - updateTrade(trade)         - Statistics calculations      │ │
│  │ - deleteTrade(id)            - Data manipulation           │ │
│  │ - getTotalPnL()                                             │ │
│  │ - getCurrentDrawdown()                                      │ │
│  │ - getWinRate()                                              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│                          DATA MODELS                           │
│  ┌─────────────────────┐              ┌─────────────────────────┐ │
│  │       Trade         │              │    RiskManagement       │ │
│  │                     │              │                         │ │
│  │ Properties:         │              │ Properties:             │ │
│  │ - id: int           │              │ - maxDrawdown: double   │ │
│  │ - result: double    │              │ - lossPerTrade: double  │ │
│  │ - timestamp: DateTime│              │ - accountBalance: double│ │
│  │                     │              │ - currentBalance: double│ │
│  │ Methods:            │              │ - isDynamicMaxDD: bool  │ │
│  │ - copyWith()        │              │                         │ │
│  │ - toJson()          │              │ Computed Properties:    │ │
│  │ - fromJson()        │              │ - maxLossPerTrade       │ │
│  │                     │              │ - remainingRiskCapacity │ │
│  │                     │              │ - currentDrawdownAmount │ │
│  │                     │              │                         │ │
│  │                     │              │ Methods:                │ │
│  │                     │              │ - isTradeWithinLimits() │ │
│  │                     │              │ - wouldExceedMaxDD()    │ │
│  │                     │              │ - updateBalance()       │ │
│  └─────────────────────┘              └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Patterns

### 1. User Input Flow
```
User Action → View → ViewModel → Service → Repository → Data Models
     ↓              ↓         ↓         ↓          ↓
   Event        Binding   Business   Data      Storage
 Handling      Update     Logic    Access    Update
```

### 2. Reactive Updates Flow
```
Data Change → Repository → Service → ViewModel → Signal Update → View Refresh
     ↓             ↓         ↓          ↓            ↓            ↓
  Storage       Notify    Calculate   State      Reactive      UI
  Update       Service    Statistics  Change     Update       Render
```

## Key Design Principles

### 1. Separation of Concerns
- **View**: Pure UI rendering and user interaction
- **ViewModel**: State management and UI logic
- **Model**: Business logic and data management

### 2. Dependency Injection
```dart
// Service depends on Repository abstraction
RiskManagementService(
  tradeRepository: TradeRepository, // Interface
  riskSettings: RiskManagement,
)

// ViewModel depends on Service
RiskManagementViewModel(
  riskService: RiskManagementService,
)
```

### 3. Reactive Programming
- **Signals**: Reactive state management
- **Watch Widgets**: Automatic UI updates
- **Event-driven**: Decoupled communication

### 4. Repository Pattern
```dart
abstract class TradeRepository {
  Future<List<Trade>> getAllTrades();
  Future<Trade> addTrade(Trade trade);
  // ... other operations
}

// Implementation can be swapped
class InMemoryTradeRepository implements TradeRepository { ... }
class DatabaseTradeRepository implements TradeRepository { ... }
class ApiTradeRepository implements TradeRepository { ... }
```

## Benefits of This Architecture

### ✅ Testability
- Each layer can be tested independently
- Dependencies can be mocked easily
- Business logic is isolated from UI

### ✅ Maintainability
- Clear separation of responsibilities
- Changes in one layer don't affect others
- Easy to locate and fix issues

### ✅ Scalability
- New features can be added without major refactoring
- Components can be reused across different screens
- Repository pattern allows easy data source changes

### ✅ Code Reusability
- ViewModels can be shared between different Views
- Services can be used by multiple ViewModels
- Repository implementations can be swapped

## Communication Patterns

### View ↔ ViewModel
```dart
// View observes ViewModel state
Watch((_) {
  return Text(viewModel.formattedMaxLossPerTrade);
})

// View triggers ViewModel actions
onPressed: () => viewModel.addTrade(tradeResult)
```

### ViewModel ↔ Service
```dart
// ViewModel calls Service methods
await _riskService.addTrade(tradeResult);

// ViewModel gets Service state
_riskSettings.value = _riskService.riskSettings;
```

### Service ↔ Repository
```dart
// Service uses Repository for data operations
final trades = await _tradeRepository.getAllTrades();
await _tradeRepository.addTrade(trade);
```

## Error Handling Flow

```
Error Occurrence → Repository/Service → ViewModel → Signal Update → View Display
       ↓                    ↓              ↓            ↓            ↓
   Exception            Try/Catch       Error         Error        Error
   Thrown               Handle         Signal         State        Message
```

This architecture ensures robust error handling at each layer while maintaining clean separation of concerns.