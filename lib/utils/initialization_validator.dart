import 'package:flutter/foundation.dart';
import '../model/risk_management.dart';

/// Utility class to validate and ensure proper initialization of risk management settings
class InitializationValidator {
  /// Validates that initial values are properly set according to requirements
  static bool validateInitialValues(RiskManagement settings) {
    debugPrint('🔍 Validating initial risk management values...');

    bool isValid = true;

    // Check max drawdown is 0.00
    if (settings.maxDrawdown != 0.00) {
      debugPrint(
        '❌ Max drawdown should be 0.00, found: ${settings.maxDrawdown}',
      );
      isValid = false;
    }

    // Check account balance is 0.0
    if (settings.accountBalance != 0.0) {
      debugPrint(
        '❌ Account balance should be 0.0, found: ${settings.accountBalance}',
      );
      isValid = false;
    }

    // Check current balance is 0.0
    if (settings.currentBalance != 0.0) {
      debugPrint(
        '❌ Current balance should be 0.0, found: ${settings.currentBalance}',
      );
      isValid = false;
    }

    // Check % loss per trade is 0
    if (settings.lossPerTradePercentage != 0) {
      debugPrint(
        '❌ Loss per trade percentage should be 0, found: ${settings.lossPerTradePercentage}',
      );
      isValid = false;
    }

    if (isValid) {
      debugPrint('✅ All initial values are correctly set:');
      debugPrint(
        '   Max Drawdown: \$${settings.maxDrawdown.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Account Balance: \$${settings.accountBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Current Balance: \$${settings.currentBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   % Loss Per Trade: ${settings.lossPerTradePercentage.toInt()}%',
      );
    }

    return isValid;
  }

  /// Creates properly initialized default settings
  static RiskManagement createDefaultSettings() {
    debugPrint('🔧 Creating default risk management settings...');

    final settings = RiskManagement(
      maxDrawdown: 0.00,
      lossPerTradePercentage: 0,
      accountBalance: 0.0,
      currentBalance: 0.0,
      isDynamicMaxDrawdown: false,
    );

    // Validate the created settings
    if (validateInitialValues(settings)) {
      debugPrint('✅ Default settings created successfully');
    } else {
      debugPrint('❌ Failed to create valid default settings');
    }

    return settings;
  }

  /// Validates that max DD dialog updates are properly synchronized
  static bool validateMaxDrawdownUpdate({
    required double oldMaxDrawdown,
    required double newMaxDrawdown,
    required double oldAccountBalance,
    required double newAccountBalance,
    required double oldCurrentBalance,
    required double newCurrentBalance,
    required bool accountBalanceChanged,
  }) {
    debugPrint('🔍 Validating max drawdown dialog update...');

    bool isValid = true;

    // Validate max drawdown update
    if (newMaxDrawdown < 0) {
      debugPrint('❌ Max drawdown cannot be negative: $newMaxDrawdown');
      isValid = false;
    }

    if (newMaxDrawdown > newAccountBalance) {
      debugPrint(
        '❌ Max drawdown cannot exceed account balance: $newMaxDrawdown > $newAccountBalance',
      );
      isValid = false;
    }

    // Validate account balance update
    if (newAccountBalance <= 0) {
      debugPrint(
        '❌ Account balance must be greater than 0: $newAccountBalance',
      );
      isValid = false;
    }

    // Validate current balance recalculation when account balance changes
    if (accountBalanceChanged) {
      debugPrint(
        'ℹ️ Account balance changed, current balance should be recalculated',
      );
      debugPrint(
        '   Old Account Balance: \$${oldAccountBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   New Account Balance: \$${newAccountBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Old Current Balance: \$${oldCurrentBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   New Current Balance: \$${newCurrentBalance.toStringAsFixed(2)}',
      );
    }

    if (isValid) {
      debugPrint('✅ Max drawdown update validation passed');
      debugPrint(
        '   Max Drawdown: \$${oldMaxDrawdown.toStringAsFixed(2)} → \$${newMaxDrawdown.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Account Balance: \$${oldAccountBalance.toStringAsFixed(2)} → \$${newAccountBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Current Balance: \$${oldCurrentBalance.toStringAsFixed(2)} → \$${newCurrentBalance.toStringAsFixed(2)}',
      );
    }

    return isValid;
  }

  /// Validates state synchronization after dialog updates
  static bool validateStateSynchronization({
    required RiskManagement settings,
    required String maxDrawdownInput,
    required String lossPerTradeInput,
  }) {
    debugPrint('🔍 Validating state synchronization...');

    bool isValid = true;

    // Check if input fields match actual settings
    final expectedMaxDD = settings.maxDrawdown.toStringAsFixed(2);
    if (maxDrawdownInput != expectedMaxDD) {
      debugPrint(
        '❌ Max drawdown input not synchronized: "$maxDrawdownInput" != "$expectedMaxDD"',
      );
      isValid = false;
    }

    final expectedLossPerTrade = settings.lossPerTradePercentage
        .toInt()
        .toString();
    if (lossPerTradeInput != expectedLossPerTrade) {
      debugPrint(
        '❌ Loss per trade input not synchronized: "$lossPerTradeInput" != "$expectedLossPerTrade"',
      );
      isValid = false;
    }

    if (isValid) {
      debugPrint('✅ State synchronization validation passed');
    }

    return isValid;
  }

  /// Logs current state for debugging purposes
  static void logCurrentState(RiskManagement settings, String context) {
    debugPrint('📊 Current State ($context):');
    debugPrint('   Max Drawdown: \$${settings.maxDrawdown.toStringAsFixed(2)}');
    debugPrint(
      '   Account Balance: \$${settings.accountBalance.toStringAsFixed(2)}',
    );
    debugPrint(
      '   Current Balance: \$${settings.currentBalance.toStringAsFixed(2)}',
    );
    debugPrint(
      '   % Loss Per Trade: ${settings.lossPerTradePercentage.toInt()}%',
    );
    debugPrint('   Dynamic Max DD: ${settings.isDynamicMaxDrawdown}');
    debugPrint(
      '   Current Drawdown: \$${settings.currentDrawdownAmount.toStringAsFixed(2)}',
    );
    debugPrint(
      '   Remaining Risk: \$${settings.remainingRiskCapacity.toStringAsFixed(2)}',
    );
    debugPrint(
      '   Max Loss Per Trade: \$${settings.maxLossPerTrade.toStringAsFixed(2)}',
    );
  }
}
