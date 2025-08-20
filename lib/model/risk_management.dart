class RiskManagement {
  final double maxDrawdown;
  final double lossPerTradePercentage;
  final double accountBalance;
  final double currentBalance;
  final bool isDynamicMaxDrawdown;
  final double currentDrawdownThreshold;

  RiskManagement({
    required this.maxDrawdown,
    required this.lossPerTradePercentage,
    required this.accountBalance,
    double? currentBalance,
    this.isDynamicMaxDrawdown = false,
    double? currentDrawdownThreshold,
  })  : currentBalance = currentBalance ?? accountBalance,
        currentDrawdownThreshold = currentDrawdownThreshold ?? -maxDrawdown;

  /// Calculate maximum loss per trade based on percentage of remaining risk capacity
  double get maxLossPerTrade {
    return (remainingRiskCapacity * lossPerTradePercentage) / 100;
  }

  /// Maximum drawdown is the absolute amount (not percentage)
  double get maxDrawdownAmount {
    return maxDrawdown;
  }

  /// Calculate current drawdown from initial account balance
  double get currentDrawdownAmount {
    final drawdown = accountBalance - currentBalance;
    return drawdown > 0 ? drawdown : 0;
  }

  /// Calculate remaining risk capacity based on current drawdown
  double get remainingRiskCapacity {
    final effectiveMaxDrawdown = _getEffectiveMaxDrawdown();
    final remaining = effectiveMaxDrawdown - currentDrawdownAmount.abs();
    return remaining > 0 ? remaining : 0;
  }

  /// Get effective max drawdown based on dynamic setting
  double _getEffectiveMaxDrawdown() {
    if (!isDynamicMaxDrawdown) return maxDrawdown;

    // If current balance is higher than initial balance, increase max drawdown
    if (currentBalance > accountBalance) {
      final profitBuffer = currentBalance - accountBalance;
      return maxDrawdown + profitBuffer;
    }

    return maxDrawdown;
  }

  /// Check if a trade exceeds risk limits
  /// Only check limits for losing trades (negative values)
  bool isTradeWithinRiskLimits(double tradeAmount) {
    // Allow unlimited profits (positive trades)
    if (tradeAmount > 0) return true;

    // Check if loss exceeds max loss per trade
    return tradeAmount.abs() <= maxLossPerTrade;
  }

  /// Check if adding a trade would exceed maximum drawdown
  bool wouldExceedMaxDrawdown(double tradeAmount) {
    if (tradeAmount >= 0) return false; // Profits never exceed drawdown

    double projectedBalance = currentBalance + tradeAmount;
    double projectedDrawdown = accountBalance - projectedBalance;
    final effectiveMaxDrawdown = _getEffectiveMaxDrawdown();

    return projectedDrawdown > effectiveMaxDrawdown;
  }

  /// Calculate risk-reward ratio
  double calculateRiskRewardRatio(double riskAmount, double rewardAmount) {
    if (riskAmount == 0) return 0;
    return rewardAmount / riskAmount;
  }

  /// Calculate win rate needed for profitability
  double calculateRequiredWinRate(double averageWin, double averageLoss) {
    if (averageWin + averageLoss.abs() == 0) return 0;
    return averageLoss.abs() / (averageWin + averageLoss.abs());
  }

  /// Calculate position size based on risk percentage
  double calculatePositionSize(double entryPrice, double stopLoss) {
    if (entryPrice == 0 || stopLoss == 0) return 0;
    double riskPerUnit = (entryPrice - stopLoss).abs();
    if (riskPerUnit == 0) return 0;
    return maxLossPerTrade / riskPerUnit;
  }

  /// Update balance after a trade
  RiskManagement updateBalance(double tradeResult) {
    return copyWith(currentBalance: currentBalance + tradeResult);
  }

  RiskManagement copyWith({
    double? maxDrawdown,
    double? lossPerTradePercentage,
    double? accountBalance,
    double? currentBalance,
    bool? isDynamicMaxDrawdown,
    double? currentDrawdownThreshold,
  }) {
    return RiskManagement(
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      lossPerTradePercentage:
          lossPerTradePercentage ?? this.lossPerTradePercentage,
      accountBalance: accountBalance ?? this.accountBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isDynamicMaxDrawdown: isDynamicMaxDrawdown ?? this.isDynamicMaxDrawdown,
      currentDrawdownThreshold: currentDrawdownThreshold ?? this.currentDrawdownThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDrawdown': maxDrawdown,
      'lossPerTradePercentage': lossPerTradePercentage,
      'accountBalance': accountBalance,
      'currentBalance': currentBalance,
      'isDynamicMaxDrawdown': isDynamicMaxDrawdown,
      'currentDrawdownThreshold': currentDrawdownThreshold,
    };
  }

  factory RiskManagement.fromJson(Map<String, dynamic> json) {
    final maxDD = (json['maxDrawdown'] as num).toDouble();
    return RiskManagement(
      maxDrawdown: maxDD,
      lossPerTradePercentage: (json['lossPerTradePercentage'] as num)
          .toDouble(),
      accountBalance: (json['accountBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num?)?.toDouble(),
      isDynamicMaxDrawdown: json['isDynamicMaxDrawdown'] as bool? ?? false,
      currentDrawdownThreshold: (json['currentDrawdownThreshold'] as num?)?.toDouble() ?? -maxDD,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiskManagement &&
        other.maxDrawdown == maxDrawdown &&
        other.lossPerTradePercentage == lossPerTradePercentage &&
        other.accountBalance == accountBalance &&
        other.currentBalance == currentBalance &&
        other.isDynamicMaxDrawdown == isDynamicMaxDrawdown &&
        other.currentDrawdownThreshold == currentDrawdownThreshold;
  }

  @override
  int get hashCode => Object.hash(
        maxDrawdown,
        lossPerTradePercentage,
        accountBalance,
        currentBalance,
        isDynamicMaxDrawdown,
        currentDrawdownThreshold,
      );

  @override
  String toString() {
    return 'RiskManagement(maxDrawdown: \$${maxDrawdown.toStringAsFixed(2)}, lossPerTradePercentage: ${lossPerTradePercentage.toStringAsFixed(2)}%, accountBalance: \$${accountBalance.toStringAsFixed(2)}, currentBalance: \$${currentBalance.toStringAsFixed(2)}, isDynamicMaxDrawdown: $isDynamicMaxDrawdown)';
  }
}
