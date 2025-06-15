# Data Flow Diagram

## Overview

This document illustrates how data flows through the Risk Management Trading App, showing the movement of information from user interactions to data persistence and back to UI updates.

## Complete Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                 USER LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │   Button    │  │   Dialog    │  │   Chart     │  │     Info Display        │ │
│  │   Clicks    │  │   Inputs    │  │ Interaction │  │                         │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│         │                │                │                        ▲             │
└─────────┼────────────────┼────────────────┼────────────────────────┼─────────────┘
          │                │                │                        │
          ▼                ▼                ▼                        │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                               VIEW LAYER                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  User Events:                          UI Updates:                             │
│  ┌─────────────────────────────┐       ┌─────────────────────────────────────┐  │
│  │ - onMaxDrawdownPressed()    │       │ - Watch(() => Signal Updates)      │  │
│  │ - onLossPerTradePressed()   │       │ - Chart Data Refresh               │  │
│  │ - onAddTradePressed()       │       │ - Risk Status Color Changes        │  │
│  │ - Dialog Form Submissions   │       │ - Error Message Display            │  │
│  └─────────────────────────────┘       └─────────────────────────────────────┘  │
│             │                                        ▲                          │
└─────────────┼────────────────────────────────────────┼──────────────────────────┘
              │                                        │
              ▼                                        │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            VIEWMODEL LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Event Processing:                     State Management:                        │
│  ┌─────────────────────────────┐       ┌─────────────────────────────────────┐  │
│  │ - updateMaxDrawdown()       │       │ Signal<RiskManagement> _riskSettings│  │
│  │ - updateLossPerTrade()      │       │ Signal<List<Trade>> _trades         │  │
│  │ - addTrade()                │       │ Signal<TradingStatistics> _stats    │  │
│  │ - clearAllTrades()          │       │ Signal<RiskStatus> _riskStatus      │  │
│  │                             │       │ Signal<bool> _isLoading             │  │
│  │ Validation:                 │       │ Signal<String?> _errorMessage       │  │
│  │ - Input format checking     │       │                                     │  │
│  │ - Business rule validation  │       │ Computed Properties:                │  │
│  │ - Error message setting     │       │ - formattedMaxLossPerTrade          │  │
│  └─────────────────────────────┘       │ - chartData                         │  │
│             │                          │ - getRiskStatusColor()              │  │
│             ▼                          └─────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                    Service Method Calls                                    │  │
│  │                                                                             │  │
│  │  _riskService.addTrade(result)                                             │  │
│  │  _riskService.updateRiskSettings(newSettings)                             │  │
│  │  _riskService.getTradingStatistics()                                      │  │
│  │  _riskService.checkRiskStatus()                                           │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│             │                                        ▲                          │
└─────────────┼────────────────────────────────────────┼──────────────────────────┘
              │                                        │
              ▼                                        │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            SERVICE LAYER                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Business Logic Processing:                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                        RiskManagementService                               │  │
│  │                                                                             │  │
│  │  Input Processing:           Risk Validation:           State Updates:     │  │
│  │  ┌─────────────────┐         ┌─────────────────┐       ┌─────────────────┐ │  │
│  │  │ • Parse trade   │         │ • Check max DD  │       │ • Update balance│ │  │
│  │  │   result        │ ──────► │ • Validate loss │ ────► │ • Recalculate   │ │  │
│  │  │ • Validate      │         │   per trade     │       │   risk capacity │ │  │
│  │  │   format        │         │ • Risk status   │       │ • Update stats  │ │  │
│  │  └─────────────────┘         └─────────────────┘       └─────────────────┘ │  │
│  │                                                                             │  │
│  │  Error Handling:                                                            │  │
│  │  • RiskLimitExceededException                                              │  │
│  │  • Validation errors                                                        │  │
│  │  • Data format errors                                                       │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│             │                                        ▲                          │
└─────────────┼────────────────────────────────────────┼──────────────────────────┘
              │                                        │
              ▼                                        │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          REPOSITORY LAYER                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Data Operations:                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                      InMemoryTradeRepository                               │  │
│  │                                                                             │  │
│  │  CRUD Operations:            Statistics Calculation:                       │  │
│  │  ┌─────────────────┐         ┌─────────────────────────────────────────┐   │  │
│  │  │ • addTrade()    │         │ • getTotalPnL()                         │   │  │
│  │  │ • getAllTrades()│ ──────► │ • getCurrentDrawdown()                  │   │  │
│  │  │ • updateTrade() │         │ • getWinCount() / getLossCount()        │   │  │
│  │  │ • deleteTrade() │         │ • getWinRate()                          │   │  │
│  │  │ • clearAll()    │         │ • getAverageWin() / getAverageLoss()    │   │  │
│  │  └─────────────────┘         └─────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│             │                                        ▲                          │
└─────────────┼────────────────────────────────────────┼──────────────────────────┘
              │                                        │
              ▼                                        │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            DATA LAYER                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  In-Memory Storage:                    Business Models:                         │
│  ┌─────────────────────────────┐       ┌─────────────────────────────────────┐  │
│  │ List<Trade> _trades         │       │         Trade Model                 │  │
│  │                             │       │ ┌─────────────────────────────────┐ │  │
│  │ Operations:                 │       │ │ - id: int                       │ │  │
│  │ • Add trade to list         │ ◄───► │ │ - result: double                │ │  │
│  │ • Update existing trade     │       │ │ - timestamp: DateTime           │ │  │
│  │ • Remove trade from list    │       │ └─────────────────────────────────┘ │  │
│  │ • Calculate statistics      │       │                                     │  │
│  │ • Filter by criteria        │       │      RiskManagement Model          │  │
│  └─────────────────────────────┘       │ ┌─────────────────────────────────┐ │  │
│                                        │ │ - maxDrawdown: double           │ │  │
│                                        │ │ - lossPerTrade: double          │ │  │
│                                        │ │ - accountBalance: double        │ │  │
│                                        │ │ - currentBalance: double        │ │  │
│                                        │ │ - isDynamicMaxDrawdown: bool    │ │  │
│                                        │ │                                 │ │  │
│                                        │ │ Computed Properties:            │ │  │
│                                        │ │ - maxLossPerTrade              │ │  │
│                                        │ │ - remainingRiskCapacity        │ │  │
│                                        │ │ - currentDrawdownAmount        │ │  │
│                                        │ └─────────────────────────────────┘ │  │
│                                        └─────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Specific Data Flow Scenarios

### 1. Adding a New Trade

```
User Input (Trade Result) → Dialog Validation → ViewModel Processing → Service Validation → Repository Storage → Statistics Update → UI Refresh

Detailed Flow:
1. User enters trade result in InputDialog
2. DialogViewModel validates input format
3. RiskManagementViewModel.addTrade() called
4. RiskManagementService validates business rules:
   - Check if loss exceeds maxLossPerTrade
   - Check if trade would exceed maxDrawdown
5. TradeRepository.addTrade() stores the trade
6. RiskManagement.updateBalance() recalculates current balance
7. Service recalculates all statistics
8. ViewModel updates all relevant signals
9. View automatically refreshes via Watch widgets
```

### 2. Updating Risk Settings

```
User Input (Max DD/Loss %) → Dialog Validation → ViewModel Processing → Service Update → Settings Validation → UI Refresh

Detailed Flow:
1. User opens risk settings dialog
2. User modifies max drawdown or loss percentage
3. DialogViewModel validates input
4. RiskManagementViewModel updates corresponding setting
5. RiskManagementService validates new settings
6. RiskManagement model recalculates derived properties
7. All dependent signals update automatically
8. UI reflects new risk parameters immediately
```

### 3. Dynamic Drawdown Toggle

```
User Toggle → Dialog State Change → ViewModel Update → Risk Recalculation → UI Update

Detailed Flow:
1. User toggles dynamic drawdown switch
2. DialogViewModel.isDynamicMaxDrawdownEnabled signal updates
3. On confirm, new RiskManagement object created with toggle state
4. Service validates and updates risk settings
5. All risk calculations (maxLossPerTrade, remainingRiskCapacity) recalculate
6. Chart and risk displays update with new values
```

## Signal-Based Reactive Flow

```
Data Change → Signal.value = newValue → Watch Widget Detects Change → UI Rebuilds

Example:
_trades.value = newTradesList
    ↓
Watch((_) => TradeChartWidget updates)
    ↓
Chart redraws with new data
```

## Error Handling Flow

```
Exception Thrown → Service/ViewModel Catches → Error Signal Updated → UI Shows Error

Types of Errors:
1. Validation Errors: Input format, business rule violations
2. Risk Limit Errors: Trade exceeds limits, drawdown exceeded
3. System Errors: Repository failures, calculation errors

Error Display:
- Error banner at top of screen
- Dialog error messages
- Input field validation errors
- Loading state management
```

## Performance Optimizations

### 1. Reactive Updates
- Only affected widgets rebuild when signals change
- Efficient chart updates with incremental data
- Lazy calculation of expensive properties

### 2. Data Management
- In-memory storage for fast access
- Efficient list operations for trade management
- Computed properties cached until dependency changes

### 3. UI Optimizations
- Watch widgets minimize rebuild scope
- Chart only redraws when data actually changes
- Loading states prevent UI blocking

## Data Persistence Points

Currently using in-memory storage, but architecture supports:

1. **Local Storage**: SharedPreferences, SQLite, Hive
2. **Cloud Storage**: Firebase, REST APIs, GraphQL
3. **Hybrid Approach**: Local cache with cloud sync

The Repository pattern makes switching between storage types seamless without affecting business logic or UI code.