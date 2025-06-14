import 'package:flutter/foundation.dart';
import 'package:signals/signals_flutter.dart';

class DialogViewModel extends ChangeNotifier {
  // Signals for dialog state
  late final Signal<bool> _isDialogOpen;
  late final Signal<String> _dialogTitle;
  late final Signal<String> _dialogHint;
  late final Signal<String> _dialogInputValue;
  late final Signal<String?> _dialogError;
  late final Signal<DialogType> _dialogType;
  late final Signal<bool> _isDynamicMaxDrawdownEnabled;

  DialogViewModel() {
    _initializeSignals();
  }

  void _initializeSignals() {
    _isDialogOpen = Signal<bool>(false);
    _dialogTitle = Signal<String>('');
    _dialogHint = Signal<String>('');
    _dialogInputValue = Signal<String>('');
    _dialogError = Signal<String?>(null);
    _dialogType = Signal<DialogType>(DialogType.maxDrawdown);
    _isDynamicMaxDrawdownEnabled = Signal<bool>(false);
  }

  // Getters for signals
  Signal<bool> get isDialogOpen => _isDialogOpen;
  Signal<String> get dialogTitle => _dialogTitle;
  Signal<String> get dialogHint => _dialogHint;
  Signal<String> get dialogInputValue => _dialogInputValue;
  Signal<String?> get dialogError => _dialogError;
  Signal<DialogType> get dialogType => _dialogType;
  Signal<bool> get isDynamicMaxDrawdownEnabled => _isDynamicMaxDrawdownEnabled;

  void openDialog({
    required String title,
    required String hint,
    required DialogType type,
    String initialValue = '',
    bool? isDynamicMaxDrawdownEnabled,
  }) {
    _dialogTitle.value = title;
    _dialogHint.value = hint;
    _dialogType.value = type;
    _dialogInputValue.value = initialValue;
    _dialogError.value = null;
    if (type == DialogType.maxDrawdown && isDynamicMaxDrawdownEnabled != null) {
      _isDynamicMaxDrawdownEnabled.value = isDynamicMaxDrawdownEnabled;
    }
    _isDialogOpen.value = true;
    notifyListeners();
  }

  void closeDialog() {
    _isDialogOpen.value = false;
    _dialogInputValue.value = '';
    _dialogError.value = null;
    _isDynamicMaxDrawdownEnabled.value = false;
    notifyListeners();
  }

  void updateInputValue(String value) {
    _dialogInputValue.value = value;
    _dialogError.value = null; // Clear error when user types
    notifyListeners();
  }

  bool validateInput() {
    final value = _dialogInputValue.value.trim();

    if (value.isEmpty) {
      _dialogError.value = 'Please enter a value';
      notifyListeners();
      return false;
    }

    // Try to parse as double
    final parsedValue = double.tryParse(value);
    if (parsedValue == null) {
      _dialogError.value = 'Please enter a valid number';
      notifyListeners();
      return false;
    }

    // Type-specific validation
    switch (_dialogType.value) {
      case DialogType.maxDrawdown:
        if (parsedValue <= 0) {
          _dialogError.value = 'Max drawdown must be greater than \$0';
          notifyListeners();
          return false;
        }
        break;
      case DialogType.lossPerTrade:
        if (parsedValue <= 0 || parsedValue > 100) {
          _dialogError.value = 'Percentage must be between 0 and 100';
          notifyListeners();
          return false;
        }
        break;
      case DialogType.tradeResult:
        // Trade result can be any positive or negative number
        break;
    }

    _dialogError.value = null;
    notifyListeners();
    return true;
  }

  String? getInputValue() {
    if (validateInput()) {
      return _dialogInputValue.value.trim();
    }
    return null;
  }

  void setError(String error) {
    _dialogError.value = error;
    notifyListeners();
  }

  void clearError() {
    _dialogError.value = null;
    notifyListeners();
  }

  void toggleDynamicMaxDrawdown(bool value) {
    _isDynamicMaxDrawdownEnabled.value = value;
    notifyListeners();
  }

  // Helper methods for specific dialog types
  void openMaxDrawdownDialog({bool isDynamicEnabled = false}) {
    openDialog(
      title: 'Max Drawdown',
      hint: 'Enter maximum drawdown amount in dollars',
      type: DialogType.maxDrawdown,
      isDynamicMaxDrawdownEnabled: isDynamicEnabled,
    );
  }

  void openLossPerTradeDialog() {
    openDialog(
      title: '% Loss Per Trade',
      hint: 'Enter maximum loss per trade percentage (0-100)',
      type: DialogType.lossPerTrade,
    );
  }

  void openTradeResultDialog() {
    openDialog(
      title: 'Trade Result',
      hint: 'Enter trade result (positive for profit, negative for loss)',
      type: DialogType.tradeResult,
    );
  }

  String getDialogButtonText() {
    switch (_dialogType.value) {
      case DialogType.maxDrawdown:
        return 'Set Max Drawdown';
      case DialogType.lossPerTrade:
        return 'Set Loss Per Trade';
      case DialogType.tradeResult:
        return 'Add Trade';
    }
  }

  String getValidationHelpText() {
    switch (_dialogType.value) {
      case DialogType.maxDrawdown:
        return 'Maximum total amount you can lose from your account balance';
      case DialogType.lossPerTrade:
        return 'Maximum risk per trade as a percentage of your account balance';
      case DialogType.tradeResult:
        return 'Enter the profit or loss amount for this trade';
    }
  }

  @override
  void dispose() {
    // Dispose of signals if needed
    super.dispose();
  }
}

enum DialogType { maxDrawdown, lossPerTrade, tradeResult }

class DialogResult {
  final bool confirmed;
  final String? value;
  final DialogType type;

  DialogResult({required this.confirmed, this.value, required this.type});
}
