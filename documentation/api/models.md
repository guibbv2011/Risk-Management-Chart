# Models API Documentation

## Overview

The Models layer contains the core data structures and business logic for the Risk Management Trading App. These classes define the fundamental entities and their behaviors within the system.

## Trade Model

### Class: `Trade`

**Location**: `lib/model/trade.dart`

Represents a single trading transaction with its result and metadata.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `int` | Unique identifier for the trade |
| `result` | `double` | Trade result (positive for profit, negative for loss) |
| `timestamp` | `DateTime` | When the trade was executed |

#### Constructor

```dart
Trade({
  required int id,
  required double result,
  DateTime? timestamp,
})
```

**Parameters:**
- `id`: Unique trade identifier
- `result`: Trade profit/loss amount
- `timestamp`: Trade execution time (defaults to `DateTime.now()`)

#### Methods

##### `copyWith()`
```dart
Trade copyWith({
  int? id,
  double? result,
  DateTime? timestamp,
})
```
Creates a copy of the trade with optionally modified properties.

**Returns:** New `Trade` instance with updated values.

##### `toJson()`
```dart
Map<String, dynamic> toJson()
```
Converts the trade to a JSON-serializable map.

**Returns:** Map containing trade data in JSON format.

##### `fromJson()`
```dart
factory Trade.fromJson(Map<String, dynamic> json)
```
Creates a Trade instance from JSON data.

**Parameters:**
- `json`: Map containing trade data

**Returns:** New `Trade` instance.

#### Usage Examples

```dart
// Create a new trade
final trade = Trade(
  id: 1,
  result: 150.50,
  timestamp: DateTime.now(),
);

// Create a profitable trade
final profit = Trade(id: 2, result: 75.25);

// Create a losing trade
final loss = Trade(id: 3, result: -25.00);

// Copy with modifications
final updatedTrade = trade.copyWith(result: 200.00);

// JSON serialization
final json = trade.toJson();
final reconstructed = Trade.fromJson(json);
```

---

## RiskManagement Model

### Class: `RiskManagement`

**Location**: `lib/model/risk_management.dart`

Contains risk management settings and calculations for trading operations.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `maxDrawdown` | `double` | Maximum drawdown amount in dollars |
| `lossPerTradePercentage` | `double` | Maximum loss per trade as percentage |
| `accountBalance` | `double` | Initial account balance |
| `currentBalance` | `double` | Current account balance |
| `isDynamicMaxDrawdown` | `bool` | Whether max drawdown adjusts with profits |

#### Constructor

```dart
RiskManagement({
  required double maxDrawdown,
  required double lossPerTradePercentage,
  required double accountBalance,
  double? currentBalance,
  bool isDynamicMaxDrawdown = false,
})
```

**Parameters:**
- `maxDrawdown`: Maximum total loss allowed
- `lossPerTradePercentage`: Risk percentage per trade (0-100)
- `accountBalance`: Starting account balance
- `currentBalance`: Current balance (defaults to account balance)
- `isDynamicMaxDrawdown`: Enable dynamic drawdown mode

#### Computed Properties

##### `maxLossPerTrade`
```dart
double get maxLossPerTrade
```
Calculates maximum allowed loss per trade.

**Formula:** `(remainingRiskCapacity × lossPerTradePercentage) / 100`

**Returns:** Maximum dollar amount that can be lost per trade.

##### `maxDrawdownAmount`
```dart
double get maxDrawdownAmount
```
Returns the absolute maximum drawdown amount.

**Returns:** The `maxDrawdown` value.

##### `currentDrawdownAmount`
```dart
double get currentDrawdownAmount
```
Calculates current drawdown from initial balance.

**Formula:** `max(0, accountBalance - currentBalance)`

**Returns:** Current drawdown amount in dollars.

##### `remainingRiskCapacity`
```dart
double get remainingRiskCapacity
```
Calculates remaining risk capacity based on effective max drawdown.

**Returns:** Remaining risk amount available.

#### Methods

##### `isTradeWithinRiskLimits()`
```dart
bool isTradeWithinRiskLimits(double tradeAmount)
```
Validates if a trade amount is within risk limits.

**Parameters:**
- `tradeAmount`: Trade result to validate

**Returns:** `true` if trade is within limits, `false` otherwise.

**Rules:**
- Positive trades (profits) are always allowed
- Negative trades must not exceed `maxLossPerTrade`

##### `wouldExceedMaxDrawdown()`
```dart
bool wouldExceedMaxDrawdown(double tradeAmount)
```
Checks if adding a trade would exceed maximum drawdown.

**Parameters:**
- `tradeAmount`: Trade result to test

**Returns:** `true` if trade would exceed max drawdown.

##### `updateBalance()`
```dart
RiskManagement updateBalance(double tradeResult)
```
Creates new instance with updated balance after trade.

**Parameters:**
- `tradeResult`: Trade profit/loss amount

**Returns:** New `RiskManagement` instance with updated balance.

##### `calculateRiskRewardRatio()`
```dart
double calculateRiskRewardRatio(double riskAmount, double rewardAmount)
```
Calculates risk-to-reward ratio.

**Parameters:**
- `riskAmount`: Amount at risk
- `rewardAmount`: Potential reward

**Returns:** Risk/reward ratio.

##### `calculateRequiredWinRate()`
```dart
double calculateRequiredWinRate(double averageWin, double averageLoss)
```
Calculates minimum win rate needed for profitability.

**Parameters:**
- `averageWin`: Average winning trade amount
- `averageLoss`: Average losing trade amount

**Returns:** Required win rate as decimal (0.0 - 1.0).

##### `calculatePositionSize()`
```dart
double calculatePositionSize(double entryPrice, double stopLoss)
```
Calculates position size based on risk parameters.

**Parameters:**
- `entryPrice`: Entry price per unit
- `stopLoss`: Stop loss price per unit

**Returns:** Number of units to trade.

##### `copyWith()`
```dart
RiskManagement copyWith({
  double? maxDrawdown,
  double? lossPerTradePercentage,
  double? accountBalance,
  double? currentBalance,
  bool? isDynamicMaxDrawdown,
})
```
Creates copy with optionally modified properties.

**Returns:** New `RiskManagement` instance.

#### Dynamic Drawdown Logic

When `isDynamicMaxDrawdown` is `true`:

1. **Profit Mode**: If `currentBalance > accountBalance`, max drawdown increases by the profit amount
2. **Loss Mode**: Standard max drawdown applies
3. **Effective Max Drawdown**: `maxDrawdown + max(0, currentBalance - accountBalance)`

#### Usage Examples

```dart
// Create risk management settings
final risk = RiskManagement(
  maxDrawdown: 1000.0,
  lossPerTradePercentage: 5.0,
  accountBalance: 10000.0,
  isDynamicMaxDrawdown: false,
);

// Check current risk capacity
print('Max loss per trade: \$${risk.maxLossPerTrade}');
print('Remaining risk: \$${risk.remainingRiskCapacity}');

// Validate a trade
final tradeAmount = -75.0;
if (risk.isTradeWithinRiskLimits(tradeAmount)) {
  print('Trade is within limits');
}

// Update balance after trade
final updatedRisk = risk.updateBalance(tradeAmount);
print('New balance: \$${updatedRisk.currentBalance}');

// Enable dynamic mode
final dynamicRisk = risk.copyWith(isDynamicMaxDrawdown: true);
```

#### Risk Calculation Examples

**Example 1: Basic Risk Calculation**
```dart
final risk = RiskManagement(
  maxDrawdown: 500.0,        // $500 max loss
  lossPerTradePercentage: 5.0, // 5% per trade
  accountBalance: 10000.0,
);

// Initial state:
// - Max loss per trade: $500 × 5% = $25
// - Remaining risk: $500
```

**Example 2: After Losing Trade**
```dart
final afterLoss = risk.updateBalance(-100.0); // Lost $100

// New state:
// - Current balance: $9,900
// - Current drawdown: $100
// - Remaining risk: $500 - $100 = $400
// - Max loss per trade: $400 × 5% = $20
```

**Example 3: Dynamic Mode with Profits**
```dart
final dynamicRisk = RiskManagement(
  maxDrawdown: 500.0,
  lossPerTradePercentage: 5.0,
  accountBalance: 10000.0,
  isDynamicMaxDrawdown: true,
);

final afterProfit = dynamicRisk.updateBalance(300.0); // Gained $300

// New state:
// - Current balance: $10,300
// - Effective max drawdown: $500 + $300 = $800
// - Remaining risk: $800
// - Max loss per trade: $800 × 5% = $40
```

## Validation Rules

### Trade Validation
- `id` must be positive integer
- `result` can be any double value (positive or negative)
- `timestamp` must be valid DateTime

### RiskManagement Validation
- `maxDrawdown` must be > 0 and ≤ account balance
- `lossPerTradePercentage` must be 0-100
- `accountBalance` must be > 0
- `currentBalance` can be any value
- `isDynamicMaxDrawdown` boolean flag

## Thread Safety

These models are immutable data classes that use the `copyWith()` pattern for updates, making them inherently thread-safe. All modifications return new instances rather than mutating existing objects.

## JSON Serialization

Both models support full JSON serialization for persistence:

```dart
// Serialize
final json = riskManagement.toJson();
final jsonString = jsonEncode(json);

// Deserialize
final decoded = jsonDecode(jsonString);
final restored = RiskManagement.fromJson(decoded);
```

## Performance Considerations

- Computed properties are calculated on-demand
- `copyWith()` operations are lightweight
- JSON serialization is optimized for small data sets
- No expensive operations in getters

## Error Handling

Models throw standard Dart exceptions:
- `ArgumentError` for invalid constructor parameters
- `FormatException` during JSON parsing
- `TypeError` for incorrect data types

Example error handling:
```dart
try {
  final risk = RiskManagement(
    maxDrawdown: -100, // Invalid: negative value
    lossPerTradePercentage: 5.0,
    accountBalance: 10000.0,
  );
} catch (e) {
  print('Invalid risk settings: $e');
}
```
