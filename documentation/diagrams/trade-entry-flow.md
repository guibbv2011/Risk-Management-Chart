# Trade Entry Flow Diagram

## Overview

This document illustrates the complete flow of adding a new trade to the Risk Management Trading App, from user interaction to data persistence and UI updates.

## Trade Entry Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERACTION                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐                                                            │
│  │   User clicks   │                                                            │
│  │  "Add Trade"    │                                                            │
│  │    button       │                                                            │
│  └─────────────────┘                                                            │
│           │                                                                     │
│           ▼                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                      INPUT DIALOG OPENS                                    │ │
│  │                                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │  Dialog     │  │  Input      │  │ Validation  │  │   Action Buttons    │ │ │
│  │  │  Title      │  │  Field      │  │  Messages   │  │                     │ │ │
│  │  │ "Trade      │  │ - Number    │  │ - Format    │  │ ┌─────────────────┐ │ │ │
│  │  │  Result"    │  │ - Decimal   │  │ - Business  │  │ │     Cancel      │ │ │ │
│  │  │             │  │ - Signed    │  │   Rules     │  │ └─────────────────┘ │ │ │
│  │  └─────────────┘  │   Values    │  │             │  │ ┌─────────────────┐ │ │ │
│  │                   │             │  │             │  │ │   Add Trade     │ │ │ │
│  │                   └─────────────┘  └─────────────┘  │ └─────────────────┘ │ │ │
│  │                                                     └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           INPUT VALIDATION PHASE                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                        DialogViewModel                                     │ │
│  │                                                                             │ │
│  │  Input Format Validation:                                                  │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                                                                         │ │ │
│  │  │  1. Check if input is not empty                                        │ │ │
│  │  │  2. Parse as double value                                              │ │ │
│  │  │  3. Validate number format                                             │ │ │
│  │  │  4. Allow positive and negative values                                 │ │ │
│  │  │                                                                         │ │ │
│  │  │  Success Path: ✓ Valid number → Continue to ViewModel                 │ │ │
│  │  │  Error Path:   ✗ Invalid format → Show error message                  │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         VIEWMODEL PROCESSING                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                   RiskManagementViewModel.addTrade()                       │ │
│  │                                                                             │ │
│  │  1. Set loading state: _isLoading.value = true                            │ │
│  │  2. Clear previous errors: _errorMessage.value = null                     │ │
│  │  3. Parse trade result: double.parse(tradeResultText)                     │ │
│  │  4. Call service: await _riskService.addTrade(tradeResult)                │ │
│  │  5. Update state: _riskSettings.value = _riskService.riskSettings         │ │
│  │  6. Refresh data: await _refreshData()                                    │ │
│  │  7. Clear input: _tradeResultInput.value = ''                             │ │
│  │  8. Reset loading: _isLoading.value = false                               │ │
│  │                                                                             │ │
│  │  Error Handling:                                                           │ │
│  │  • FormatException → "Invalid number format"                              │ │
│  │  • RiskLimitExceededException → Display specific risk error               │ │
│  │  • Generic Exception → "Failed to add trade"                              │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         SERVICE LAYER PROCESSING                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                 RiskManagementService.addTrade()                           │ │
│  │                                                                             │ │
│  │  Business Logic Validation:                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                                                                         │ │ │
│  │  │  IF trade result < 0 (Loss):                                          │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐   │ │ │
│  │  │  │  1. Check: |result| ≤ maxLossPerTrade                           │   │ │ │
│  │  │  │  2. Check: Would not exceed max drawdown                        │   │ │ │
│  │  │  │                                                                  │   │ │ │
│  │  │  │  If fails → Throw RiskLimitExceededException                    │   │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────┘   │ │ │
│  │  │                                                                         │ │ │
│  │  │  IF trade result ≥ 0 (Profit):                                        │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐   │ │ │
│  │  │  │  Always allowed - no validation needed                          │   │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────┘   │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                             │ │
│  │  Trade Processing:                                                         │ │
│  │  1. Create Trade object: Trade(id: 0, result: result)                     │ │
│  │  2. Add to repository: await _tradeRepository.addTrade(trade)              │ │
│  │  3. Update balance: _riskSettings = _riskSettings.updateBalance(result)   │ │
│  │                                                                             │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        REPOSITORY DATA STORAGE                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                InMemoryTradeRepository.addTrade()                          │ │
│  │                                                                             │ │
│  │  Data Operations:                                                          │ │
│  │  1. Assign unique ID: newTrade = trade.copyWith(id: _nextId++)            │ │
│  │  2. Add to list: _trades.add(newTrade)                                    │ │
│  │  3. Return trade: return newTrade                                         │ │
│  │                                                                             │ │
│  │  List State After Addition:                                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  _trades = [                                                           │ │ │
│  │  │    Trade(id: 1, result: 150.0, timestamp: 2024-01-01T10:00:00),      │ │ │
│  │  │    Trade(id: 2, result: -75.0, timestamp: 2024-01-01T11:30:00),      │ │ │
│  │  │    Trade(id: 3, result: 200.0, timestamp: 2024-01-01T14:15:00),      │ │ │
│  │  │    Trade(id: 4, result: newResult, timestamp: now),  // ← NEW         │ │ │
│  │  │  ]                                                                     │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      STATISTICS RECALCULATION                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                   ViewModel._refreshData()                                 │ │
│  │                                                                             │ │
│  │  Parallel Data Updates:                                                    │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                                                                         │ │ │
│  │  │  1. Get trades: _riskService.getAllTrades()                           │ │ │
│  │  │  2. Get statistics: _riskService.getTradingStatistics()               │ │ │
│  │  │  3. Get risk status: _riskService.checkRiskStatus()                   │ │ │
│  │  │                                                                         │ │ │
│  │  │  Statistics Calculated:                                                │ │ │
│  │  │  • Total P&L = sum of all trade results                               │ │ │
│  │  │  • Win rate = (winning trades / total trades) × 100                   │ │ │
│  │  │  • Current drawdown = account balance - current balance               │ │ │
│  │  │  • Remaining risk = max drawdown - current drawdown                   │ │ │
│  │  │  • Max loss per trade = remaining risk × loss percentage / 100        │ │ │
│  │  │  • Risk status = low/medium/high/critical based on remaining risk     │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          SIGNAL UPDATES                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Reactive State Updates                                  │ │
│  │                                                                             │ │
│  │  Signal Updates Trigger UI Rebuilds:                                      │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                                                                         │ │ │
│  │  │  _trades.value = newTradesList                                         │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Watch(() => TradeChartWidget) rebuilds                               │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Chart adds new data point and redraws                                │ │ │
│  │  │                                                                         │ │ │
│  │  │  _riskSettings.value = updatedRiskSettings                            │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Watch(() => RiskControlsWidget) rebuilds                             │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Max loss per trade display updates                                   │ │ │
│  │  │                                                                         │ │ │
│  │  │  _riskStatus.value = newRiskStatus                                    │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Watch(() => Risk status indicator) rebuilds                          │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Status color and text update                                         │ │ │
│  │  │                                                                         │ │ │
│  │  │  _statistics.value = newStatistics                                    │ │ │
│  │  │      ↓                                                                  │ │ │
│  │  │  Info dialog data refreshes (if open)                                 │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│           │                                                                     │
└───────────┼─────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            UI UPDATES                                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                      Visual Updates Complete                               │ │
│  │                                                                             │ │
│  │  UI Components That Update:                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                                                                         │ │ │
│  │  │  📊 Chart Widget:                                                      │ │ │
│  │  │     • New data point added to P&L curve                               │ │ │
│  │  │     • Chart automatically scrolls/scales if needed                    │ │ │
│  │  │     • Animation plays for new point                                   │ │ │
│  │  │                                                                         │ │ │
│  │  │  🎛️ Risk Controls Widget:                                             │ │ │
│  │  │     • Max loss per trade value updates                                │ │ │
│  │  │     • Color changes if approaching limits                              │ │ │
│  │  │                                                                         │ │ │
│  │  │  🚦 Risk Status Indicator:                                            │ │ │
│  │  │     • Status text updates (Low/Medium/High/Critical)                  │ │ │
│  │  │     • Background color changes                                         │ │ │
│  │  │     • Icon changes                                                     │ │ │
│  │  │                                                                         │ │ │
│  │  │  💬 Dialog:                                                           │ │ │
│  │  │     • Input field clears                                              │ │ │
│  │  │     • Dialog closes automatically                                     │ │ │
│  │  │     • Loading state resets                                            │ │ │
│  │  │                                                                         │ │ │
│  │  │  📊 Statistics (if info dialog open):                                 │ │ │
│  │  │     • All numerical values update                                     │ │ │
│  │  │     • Win rate recalculates                                           │ │ │
│  │  │     • P&L total updates                                               │ │ │
│  │  │                                                                         │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Error Handling Paths

### 1. Input Validation Errors
```
Invalid Input → Dialog Shows Error → User Corrects → Retry Flow
```

### 2. Risk Limit Exceeded
```
Risk Violation → Service Throws Exception → ViewModel Catches → Error Banner Shows
```

### 3. System Errors
```
Repository Fails → Service Propagates → ViewModel Handles → User Notification
```

## Trade Entry Examples

### Example 1: Successful Profit Trade
```
Input: +150.50
Validation: ✓ Valid number
Risk Check: ✓ Profits always allowed
Storage: ✓ Added to repository
Balance: $10,000 → $10,150.50
Max Loss: Increases (if dynamic mode)
Chart: New point at (+1, +150.50)
Status: Improved risk status
```

### Example 2: Successful Loss Trade
```
Input: -75.00
Validation: ✓ Valid number
Risk Check: ✓ Within $100 max loss limit
Storage: ✓ Added to repository
Balance: $10,000 → $9,925.00
Max Loss: Decreases to new limit
Chart: New point at (+1, -75.00)
Status: Slightly worse risk status
```

### Example 3: Risk Limit Exceeded
```
Input: -200.00
Validation: ✓ Valid number
Risk Check: ✗ Exceeds $100 max loss limit
Error: "Trade loss amount $200.00 exceeds maximum allowed loss per trade $100.00"
Result: Trade rejected, no changes made
```

### Example 4: Max Drawdown Exceeded
```
Input: -150.00
Validation: ✓ Valid number
Risk Check: ✗ Would exceed max drawdown
Error: "Adding this trade would exceed maximum drawdown limit"
Result: Trade rejected, no changes made
```

## Performance Characteristics

- **Input Validation**: ~1ms (local)
- **Risk Calculations**: ~1ms (mathematical operations)
- **Repository Storage**: ~1ms (in-memory list operation)
- **Statistics Recalculation**: ~5ms (depends on trade count)
- **UI Updates**: ~16ms (single frame)
- **Total Flow Time**: ~25ms for typical trade

## Reactive Update Chain

```
Single Trade Addition → Multiple UI Components Update Automatically
```

The beauty of the reactive architecture is that one data change triggers all necessary UI updates without manual intervention:

1. **Chart** automatically adds new point
2. **Risk display** automatically updates limits
3. **Status indicator** automatically changes color
4. **Statistics** automatically recalculate
5. **Balance** automatically updates

This ensures the UI is always in sync with the data state.