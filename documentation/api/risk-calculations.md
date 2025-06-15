# Risk Calculations API Documentation

## Overview

This document provides comprehensive documentation of all risk calculation formulas, business rules, and mathematical operations used in the Risk Management Trading App.

## Core Risk Calculation Formulas

### 1. Maximum Loss Per Trade

The maximum amount that can be lost on a single trade, calculated as a percentage of the remaining risk capacity.

```
Formula: (Remaining Risk Capacity × Loss Per Trade %) / 100

Example:
- Remaining Risk Capacity: $400
- Loss Per Trade %: 5%
- Max Loss Per Trade: ($400 × 5%) / 100 = $20
```

**Implementation:**
```dart
double get maxLossPerTrade {
  return (remainingRiskCapacity * lossPerTradePercentage) / 100;
}
```

### 2. Current Drawdown Amount

The total amount lost from the initial account balance.

```
Formula: max(0, Account Balance - Current Balance)

Example:
- Account Balance: $10,000
- Current Balance: $9,750
- Current Drawdown: max(0, $10,000 - $9,750) = $250
```

**Implementation:**
```dart
double get currentDrawdownAmount {
  final drawdown = accountBalance - currentBalance;
  return drawdown > 0 ? drawdown : 0;
}
```

### 3. Remaining Risk Capacity

The amount of additional loss that can be sustained before hitting the maximum drawdown limit.

```
Formula: Effective Max Drawdown - Current Drawdown Amount

Static Mode:
- Effective Max Drawdown = Max Drawdown
- Remaining Risk = Max Drawdown - Current Drawdown

Dynamic Mode (when current balance > account balance):
- Profit Buffer = Current Balance - Account Balance
- Effective Max Drawdown = Max Drawdown + Profit Buffer
- Remaining Risk = Effective Max Drawdown - Current Drawdown
```

**Implementation:**
```dart
double get remainingRiskCapacity {
  final effectiveMaxDrawdown = _getEffectiveMaxDrawdown();
  final remaining = effectiveMaxDrawdown - currentDrawdownAmount.abs();
  return remaining > 0 ? remaining : 0;
}

double _getEffectiveMaxDrawdown() {
  if (!isDynamicMaxDrawdown) return maxDrawdown;
  
  if (currentBalance > accountBalance) {
    final profitBuffer = currentBalance - accountBalance;
    return maxDrawdown + profitBuffer;
  }
  
  return maxDrawdown;
}
```

## Risk Validation Rules

### 1. Trade Within Risk Limits

Determines if a proposed trade complies with risk management rules.

```
Rules:
1. Positive trades (profits) are ALWAYS allowed
2. Negative trades (losses) must satisfy:
   - |trade amount| ≤ maxLossPerTrade
```

**Implementation:**
```dart
bool isTradeWithinRiskLimits(double tradeAmount) {
  // Allow unlimited profits
  if (tradeAmount > 0) return true;
  
  // Check if loss exceeds max loss per trade
  return tradeAmount.abs() <= maxLossPerTrade;
}
```

### 2. Maximum Drawdown Validation

Checks if adding a trade would exceed the maximum allowable drawdown.

```
Validation Steps:
1. If trade amount ≥ 0 (profit): Always allowed
2. If trade amount < 0 (loss):
   - Calculate projected balance: Current Balance + Trade Amount
   - Calculate projected drawdown: Account Balance - Projected Balance
   - Check: Projected Drawdown ≤ Effective Max Drawdown
```

**Implementation:**
```dart
bool wouldExceedMaxDrawdown(double tradeAmount) {
  if (tradeAmount >= 0) return false; // Profits never exceed drawdown
  
  double projectedBalance = currentBalance + tradeAmount;
  double projectedDrawdown = accountBalance - projectedBalance;
  final effectiveMaxDrawdown = _getEffectiveMaxDrawdown();
  
  return projectedDrawdown > effectiveMaxDrawdown;
}
```

## Statistical Calculations

### 1. Win Rate Calculation

Percentage of profitable trades out of total trades.

```
Formula: (Number of Winning Trades / Total Trades) × 100

Example:
- Winning Trades: 15
- Total Trades: 25
- Win Rate: (15 / 25) × 100 = 60%
```

**Implementation:**
```dart
Future<double> getWinRate() async {
  if (_trades.isEmpty) return 0.0;
  final winCount = await getWinCount();
  return (winCount / _trades.length) * 100;
}
```

### 2. Average Win/Loss Calculation

Average profit from winning trades and average loss from losing trades.

```
Average Win Formula: Sum of All Winning Trades / Number of Winning Trades
Average Loss Formula: Sum of All Losing Trades / Number of Losing Trades

Example:
- Winning trades: [+100, +150, +75] = +325
- Number of wins: 3
- Average Win: 325 / 3 = $108.33

- Losing trades: [-50, -25, -75] = -150
- Number of losses: 3
- Average Loss: -150 / 3 = -$50.00
```

**Implementation:**
```dart
Future<double> getAverageWin() async {
  final wins = _trades.where((trade) => trade.result > 0).toList();
  if (wins.isEmpty) return 0.0;
  double total = 0.0;
  for (final trade in wins) {
    total += trade.result;
  }
  return total / wins.length;
}
```

### 3. Risk-Reward Ratio

Compares the potential reward to the risk taken.

```
Formula: Average Win / |Average Loss|

Example:
- Average Win: $108.33
- Average Loss: -$50.00
- Risk-Reward Ratio: 108.33 / 50.00 = 2.17

Interpretation: For every $1 risked, $2.17 is potentially gained
```

**Implementation:**
```dart
double calculateRiskRewardRatio(double riskAmount, double rewardAmount) {
  if (riskAmount == 0) return 0;
  return rewardAmount / riskAmount;
}
```

### 4. Required Win Rate for Profitability

The minimum win rate needed to be profitable given current average win/loss amounts.

```
Formula: |Average Loss| / (Average Win + |Average Loss|)

Example:
- Average Win: $108.33
- Average Loss: -$50.00
- Required Win Rate: 50.00 / (108.33 + 50.00) = 0.316 = 31.6%

Interpretation: Need to win at least 31.6% of trades to be profitable
```

**Implementation:**
```dart
double calculateRequiredWinRate(double averageWin, double averageLoss) {
  if (averageWin + averageLoss.abs() == 0) return 0;
  return averageLoss.abs() / (averageWin + averageLoss.abs());
}
```

## Dynamic Drawdown Calculations

### Static Mode (isDynamicMaxDrawdown = false)

In static mode, the maximum drawdown remains constant regardless of profits.

```
Example:
- Initial Settings: Max DD = $1,000, Account = $10,000
- After +$500 profit: Current Balance = $10,500
- Effective Max Drawdown: Still $1,000
- Remaining Risk: $1,000 (unchanged)
```

### Dynamic Mode (isDynamicMaxDrawdown = true)

In dynamic mode, the maximum drawdown increases when profits exceed the initial account balance.

```
Example:
- Initial Settings: Max DD = $1,000, Account = $10,000
- After +$500 profit: Current Balance = $10,500
- Profit Buffer: $10,500 - $10,000 = $500
- Effective Max Drawdown: $1,000 + $500 = $1,500
- Remaining Risk: $1,500 (increased by profit)
```

**Implementation:**
```dart
double _getEffectiveMaxDrawdown() {
  if (!isDynamicMaxDrawdown) return maxDrawdown;
  
  // If current balance is higher than initial balance, increase max drawdown
  if (currentBalance > accountBalance) {
    final profitBuffer = currentBalance - accountBalance;
    return maxDrawdown + profitBuffer;
  }
  
  return maxDrawdown;
}
```

## Position Size Calculation

Calculates the number of units to trade based on risk parameters and price levels.

```
Formula: Max Loss Per Trade / Risk Per Unit
Where: Risk Per Unit = |Entry Price - Stop Loss Price|

Example:
- Max Loss Per Trade: $50
- Entry Price: $100
- Stop Loss: $95
- Risk Per Unit: |$100 - $95| = $5
- Position Size: $50 / $5 = 10 units
```

**Implementation:**
```dart
double calculatePositionSize(double entryPrice, double stopLoss) {
  if (entryPrice == 0 || stopLoss == 0) return 0;
  double riskPerUnit = (entryPrice - stopLoss).abs();
  if (riskPerUnit == 0) return 0;
  return maxLossPerTrade / riskPerUnit;
}
```

## Risk Status Classification

Categorizes the current risk level based on remaining risk capacity.

```
Risk Status Levels:
- Critical: Remaining Risk ≤ 0
- High: 0 < Remaining Risk ≤ 20% of Max Drawdown
- Medium: 20% < Remaining Risk ≤ 50% of Max Drawdown
- Low: Remaining Risk > 50% of Max Drawdown

Example (Max Drawdown = $1,000):
- Critical: ≤ $0
- High: $0.01 - $200
- Medium: $200.01 - $500
- Low: > $500
```

**Implementation:**
```dart
Future<RiskStatus> checkRiskStatus() async {
  final remainingRisk = _riskSettings.remainingRiskCapacity;
  
  if (remainingRisk <= 0) {
    return RiskStatus.critical;
  } else if (remainingRisk <= _riskSettings.maxDrawdown * 0.2) {
    return RiskStatus.high;
  } else if (remainingRisk <= _riskSettings.maxDrawdown * 0.5) {
    return RiskStatus.medium;
  } else {
    return RiskStatus.low;
  }
}
```

## Balance Update Logic

Updates the current balance after each trade and recalculates all dependent values.

```
Update Process:
1. New Balance = Current Balance + Trade Result
2. Recalculate Current Drawdown
3. Recalculate Remaining Risk Capacity
4. Recalculate Max Loss Per Trade
5. Recalculate Risk Status

Example:
- Current Balance: $9,800
- Trade Result: -$75
- New Balance: $9,800 + (-$75) = $9,725
- New Drawdown: $10,000 - $9,725 = $275
- New Remaining Risk: $1,000 - $275 = $725
- New Max Loss Per Trade: $725 × 5% = $36.25
```

**Implementation:**
```dart
RiskManagement updateBalance(double tradeResult) {
  return copyWith(currentBalance: currentBalance + tradeResult);
}
```

## Validation Constraints

### Input Validation Rules

```
Max Drawdown:
- Must be > 0
- Must be ≤ Account Balance
- Data type: double

Loss Per Trade Percentage:
- Must be > 0
- Must be ≤ 100
- Data type: double

Account Balance:
- Must be > 0
- Data type: double

Trade Result:
- Can be any value (positive or negative)
- Data type: double
```

### Business Rule Validation

```
Trade Addition Rules:
1. Positive trades: Always allowed
2. Negative trades: Must pass both checks:
   - |trade| ≤ maxLossPerTrade
   - wouldNotExceedMaxDrawdown

Risk Settings Update Rules:
1. New settings must pass validateRiskSettings()
2. Current balance is preserved during updates
3. All dependent calculations automatically update
```

## Mathematical Edge Cases

### Division by Zero Protection

```
Scenarios:
1. Risk per unit = 0 in position size calculation
2. Average loss = 0 in risk-reward ratio
3. No trades for win rate calculation

Handling:
- Return 0 for invalid calculations
- Check denominators before division
- Handle empty datasets gracefully
```

### Negative Remaining Risk

```
Scenario: Current drawdown exceeds max drawdown
Handling: remainingRiskCapacity returns 0 (not negative)
Impact: maxLossPerTrade becomes 0, preventing further losses
```

### Floating Point Precision

```
Considerations:
- Use double precision for all calculations
- Round display values to 2 decimal places for currency
- Maintain precision in internal calculations
- Avoid equality comparisons with floating point numbers
```

## Performance Characteristics

### Calculation Complexity

```
O(1) Operations:
- maxLossPerTrade
- currentDrawdownAmount
- remainingRiskCapacity
- isTradeWithinRiskLimits
- wouldExceedMaxDrawdown

O(n) Operations (where n = number of trades):
- getTotalPnL
- getWinRate
- getAverageWin/Loss
- getCurrentDrawdown (repository method)
```

### Optimization Strategies

```
1. Computed Properties: Calculate on-demand, not stored
2. Signal Updates: Only recalculate when dependencies change
3. Incremental Updates: Update totals incrementally when possible
4. Lazy Evaluation: Expensive calculations only when needed
```

## Testing Formulas

### Unit Test Examples

```dart
test('maxLossPerTrade calculation', () {
  final risk = RiskManagement(
    maxDrawdown: 1000.0,
    lossPerTradePercentage: 5.0,
    accountBalance: 10000.0,
  );
  
  expect(risk.maxLossPerTrade, equals(50.0)); // 1000 * 5% = 50
});

test('dynamic drawdown with profits', () {
  final risk = RiskManagement(
    maxDrawdown: 1000.0,
    lossPerTradePercentage: 5.0,
    accountBalance: 10000.0,
    currentBalance: 10500.0, // +500 profit
    isDynamicMaxDrawdown: true,
  );
  
  expect(risk.remainingRiskCapacity, equals(1500.0)); // 1000 + 500
  expect(risk.maxLossPerTrade, equals(75.0)); // 1500 * 5% = 75
});
```

This documentation provides the mathematical foundation for all risk management decisions in the application, ensuring consistent and predictable behavior across all trading scenarios.