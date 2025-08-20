import '../model/risk_management.dart';

class InitializationValidator {
  static bool validateInitialValues(RiskManagement settings) {

    bool isValid = true;

    if (settings.maxDrawdown != 0.00) {
      isValid = false;
    }

    if (settings.accountBalance != 0.0) {
      isValid = false;
    }

    if (settings.currentBalance != 0.0) {
      isValid = false;
    }

    if (settings.lossPerTradePercentage != 0) {
      isValid = false;
    }

    return isValid;
  }

  static RiskManagement createDefaultSettings() {

    final settings = RiskManagement(
      maxDrawdown: 0.00,
      lossPerTradePercentage: 0,
      accountBalance: 0.0,
      currentBalance: 0.0,
      isDynamicMaxDrawdown: false,
    );

    return settings;
  }

  static bool validateMaxDrawdownUpdate({
    required double oldMaxDrawdown,
    required double newMaxDrawdown,
    required double oldAccountBalance,
    required double newAccountBalance,
    required double oldCurrentBalance,
    required double newCurrentBalance,
    required bool accountBalanceChanged,
  }) {

    bool isValid = true;

    if (newMaxDrawdown < 0) {
      isValid = false;
    }

    if (newMaxDrawdown > newAccountBalance) {
      isValid = false;
    }

    if (newAccountBalance <= 0) {
      isValid = false;
    }

    return isValid;
  }

  static bool validateStateSynchronization({
    required RiskManagement settings,
    required String maxDrawdownInput,
    required String lossPerTradeInput,
  }) {

    bool isValid = true;

    final expectedMaxDD = settings.maxDrawdown.toStringAsFixed(2);
    if (maxDrawdownInput != expectedMaxDD) {
      isValid = false;
    }

    final expectedLossPerTrade = settings.lossPerTradePercentage
        .toInt()
        .toString();
    if (lossPerTradeInput != expectedLossPerTrade) {
      isValid = false;
    }

    return isValid;
  }

}
