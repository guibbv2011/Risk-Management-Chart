import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../model/trade.dart';
import '../model/risk_management.dart';
import '../model/service/risk_management_service.dart';
import '../model/storage/storage_interface.dart';

import '../services/simple_persistence_fix.dart';
import '../utils/initialization_validator.dart';

class RiskManagementViewModel extends ChangeNotifier {
  final RiskManagementService _riskService;
  final ConfigStorage _configStorage;

  late final Signal<List<Trade>> _trades;
  late final Signal<RiskManagement> _riskSettings;
  late final Signal<ServiceTradingStatistics?> _statistics;
  late final Signal<RiskStatus> _riskStatus;
  late final Signal<bool> _isLoading;
  late final Signal<String?> _errorMessage;

  late final Signal<String> _maxDrawdownInput;
  late final Signal<String> _lossPerTradeInput;
  late final Signal<String> _tradeResultInput;

  RiskManagementViewModel({
    required RiskManagementService riskService,
    required ConfigStorage configStorage,
  }) : _riskService = riskService,
       _configStorage = configStorage {
    _initializeSignals();
    _loadInitialData();
  }

  void _initializeSignals() {
    _trades = Signal<List<Trade>>([]);
    _riskSettings = Signal<RiskManagement>(_riskService.riskSettings);
    _statistics = Signal<ServiceTradingStatistics?>(null);
    _riskStatus = Signal<RiskStatus>(RiskStatus.low);
    _isLoading = Signal<bool>(false);
    _errorMessage = Signal<String?>(null);

    _maxDrawdownInput = Signal<String>('');
    _lossPerTradeInput = Signal<String>('');
    _tradeResultInput = Signal<String>('');

    InitializationValidator.validateInitialValues(_riskService.riskSettings);
  }

  Signal<List<Trade>> get trades => _trades;
  Signal<RiskManagement> get riskSettings => _riskSettings;
  Signal<ServiceTradingStatistics?> get statistics => _statistics;
  Signal<RiskStatus> get riskStatus => _riskStatus;
  Signal<bool> get isLoading => _isLoading;
  Signal<String?> get errorMessage => _errorMessage;

  Signal<String> get maxDrawdownInput => _maxDrawdownInput;
  Signal<String> get lossPerTradeInput => _lossPerTradeInput;
  Signal<String> get tradeResultInput => _tradeResultInput;

  String get formattedMaxLossPerTrade {
    return _riskSettings.value.maxLossPerTrade.toStringAsFixed(2);
  }

  List<ChartData> get chartData {
    final tradesList = _trades.value;
    List<ChartData> data = [];

    data.add(ChartData(0, 0.0));

    if (tradesList.isEmpty) {
      return data;
    }

    double runningTotal = 0.0;

    for (int i = 0; i < tradesList.length; i++) {
      runningTotal += tradesList[i].result;
      data.add(ChartData(i + 1, runningTotal));
    }

    return data;
  }

  List<ChartData> get drawdownChartData {
    final tradesList = _trades.value;
    List<ChartData> data = [];
    data.add(ChartData(0, -riskSettings.value.maxDrawdown));
    if (tradesList.isEmpty) {
      return data;
    }
    double currentDD = -riskSettings.value.maxDrawdown;
    double runningTotal = 0.0;
    final maxDD = riskSettings.value.maxDrawdown;
    final isDynamic = riskSettings.value.isDynamicMaxDrawdown;
    for (int i = 0; i < tradesList.length; i++) {
      runningTotal += tradesList[i].result;
      final result = tradesList[i].result;
      if (result < 0) {
        data.add(ChartData(i + 1, currentDD));
      } else {
        final distance = runningTotal - currentDD;
        if (distance >= maxDD) {
          double newDD = runningTotal - maxDD;
          if (!isDynamic && newDD > 0) {
            newDD = 0;
          }
          currentDD = newDD;
          data.add(ChartData(i + 1, currentDD));
        } else {
          data.add(ChartData(i + 1, currentDD));
        }
      }
    }
    return data;
  }

  Future<void> _loadInitialData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      await _loadSavedRiskSettings();


      await _riskService.initializeCurrentBalance();

      await _refreshData();

      if (_trades.value.isEmpty && !await _configStorage.hasRiskSettings()) {
        await attemptDataRecovery();
      }

    } catch (e) {
      _errorMessage.value = 'Failed to load initial data: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshData() async {
    final trades = await _riskService.getAllTrades();

    final stats = await _riskService.getTradingStatistics();
    final status = await _riskService.checkRiskStatus();

    _trades.value = trades;
    _statistics.value = stats;
    _riskStatus.value = status;
    _riskSettings.value = _riskService.riskSettings;

  }

  Future<void> _loadSavedRiskSettings() async {
    try {
      final savedSettings = await _configStorage.loadRiskSettings();
      if (savedSettings != null) {

        if (_riskService.validateRiskSettings(savedSettings)) {
          _riskService.updateRiskSettings(savedSettings);
        } 
      } else {
        await _initializeDefaultSettings();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveRiskSettings() async {
    try {
      await _configStorage.saveRiskSettings(_riskSettings.value);

      await _createSimpleBackup();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTrade(String tradeResultText) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      final tradeResult = double.parse(tradeResultText);

      await _riskService.addTrade(tradeResult);

      _tradeResultInput.value = '';

      _riskSettings.value = _riskService.riskSettings;

      await _saveRiskSettings();
      await _refreshData();

      await _createSimpleBackup();
      notifyListeners();
    } on FormatException {
      _errorMessage.value =
          'Invalid trade result format. Please enter a valid number.';
    } on RiskLimitExceededException catch (e) {
      _errorMessage.value = e.message;
    } catch (e) {
      _errorMessage.value = 'Failed to add trade: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateMaxDrawdown(
    String maxDrawdownText,
    String? accountBalanceText, [
    bool? isDynamicEnabled,
  ]) async {
    try {
      _errorMessage.value = null;

      final maxDrawdown = double.parse(maxDrawdownText);

      double accountBalance = _riskSettings.value.accountBalance;
      bool accountBalanceChanged = false;

      if (accountBalanceText != null && accountBalanceText.isNotEmpty) {
        final newAccountBalance = double.parse(accountBalanceText);
        if (newAccountBalance <= 0) {
          throw ArgumentError('Account balance must be greater than \$0');
        }
        if (newAccountBalance != accountBalance) {
          accountBalance = newAccountBalance;
          accountBalanceChanged = true;
        }
      }

      if (maxDrawdown < 0 || maxDrawdown > accountBalance) {
        throw ArgumentError(
          'Max drawdown must be between \$0 and \$${accountBalance.toStringAsFixed(2)}',
        );
      }

      double currentBalance = _riskSettings.value.currentBalance;
      if (accountBalanceChanged) {
        final totalPnL = await _riskService.getTotalPnL();
        currentBalance = accountBalance + totalPnL;
      }

      final updateValid = InitializationValidator.validateMaxDrawdownUpdate(
        oldMaxDrawdown: _riskSettings.value.maxDrawdown,
        newMaxDrawdown: maxDrawdown,
        oldAccountBalance: _riskSettings.value.accountBalance,
        newAccountBalance: accountBalance,
        oldCurrentBalance: _riskSettings.value.currentBalance,
        newCurrentBalance: currentBalance,
        accountBalanceChanged: accountBalanceChanged,
      );

      if (!updateValid) {
        throw ArgumentError('Invalid max drawdown update parameters');
      }

      final newSettings = _riskSettings.value.copyWith(
        accountBalance: accountBalance,
        currentBalance: currentBalance,
        maxDrawdown: maxDrawdown,
        isDynamicMaxDrawdown:
            isDynamicEnabled ?? _riskSettings.value.isDynamicMaxDrawdown,
        currentDrawdownThreshold: -maxDrawdown,
      );

      if (_riskService.validateRiskSettings(newSettings)) {
        _riskService.updateRiskSettings(newSettings);
        _riskSettings.value = newSettings;
        _maxDrawdownInput.value = '';

        await _saveRiskSettings();
        await _refreshData();

        _maxDrawdownInput.value = maxDrawdown.toStringAsFixed(2);

        InitializationValidator.validateStateSynchronization(
          settings: newSettings,
          maxDrawdownInput: _maxDrawdownInput.value,
          lossPerTradeInput: _lossPerTradeInput.value,
        );

        notifyListeners();
      } else {
        throw ArgumentError('Invalid risk settings');
      }
    } on FormatException {
      _errorMessage.value =
          'Invalid format. Please enter valid dollar amounts.';
    } on ArgumentError catch (e) {
      _errorMessage.value = e.message;
    } catch (e) {
      _errorMessage.value = 'Failed to update max drawdown: ${e.toString()}';
    }
  }

  Future<void> updateLossPerTrade(String lossPerTradeText) async {
    try {
      _errorMessage.value = null;

      final lossPerTrade = double.parse(lossPerTradeText);
      if (lossPerTrade <= 0 || lossPerTrade > 100) {
        throw ArgumentError('Loss per trade must be between 0 and 100');
      }

      final newSettings = _riskSettings.value.copyWith(
        lossPerTradePercentage: lossPerTrade,
      );

      if (_riskService.validateRiskSettings(newSettings)) {
        _riskService.updateRiskSettings(newSettings);
        _riskSettings.value = newSettings;
        _lossPerTradeInput.value = lossPerTrade.toStringAsFixed(0);

        await _saveRiskSettings();
        await _refreshData();

        notifyListeners();
      } else {
        throw ArgumentError('Invalid risk settings');
      }
    } on FormatException {
      _errorMessage.value =
          'Invalid loss per trade format. Please enter a valid percentage.';
    } on ArgumentError catch (e) {
      _errorMessage.value = e.message;
    } catch (e) {
      _errorMessage.value = 'Failed to update loss per trade: ${e.toString()}';
    }
  }

  Future<void> clearAllTrades() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      await _riskService.clearAllTrades();

      await _saveRiskSettings();
      await _refreshData();

      await _createSimpleBackup();
    } catch (e) {
      _errorMessage.value = 'Failed to clear trades: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  double calculatePositionSize(double entryPrice, double stopLoss) {
    return _riskService.calculatePositionSize(entryPrice, stopLoss);
  }

  void updateInputField(InputField field, String value) {
    switch (field) {
      case InputField.maxDrawdown:
        _maxDrawdownInput.value = value;
        break;
      case InputField.lossPerTrade:
        _lossPerTradeInput.value = value;
        break;
      case InputField.tradeResult:
        _tradeResultInput.value = value;
        break;
    }
  }

  void clearError() {
    _errorMessage.value = null;
  }

  Color getRiskStatusColor() {
    switch (_riskStatus.value) {
      case RiskStatus.low:
        return const Color(0xFF4CAF50);
      case RiskStatus.medium:
        return const Color(0xFFFF9800);
      case RiskStatus.high:
        return const Color(0xFFFF5722);
      case RiskStatus.critical:
        return const Color(0xFFF44336);
    }
  }

  String getRiskStatusText() {
    switch (_riskStatus.value) {
      case RiskStatus.low:
        return 'Low Risk';
      case RiskStatus.medium:
        return 'Medium Risk';
      case RiskStatus.high:
        return 'High Risk';
      case RiskStatus.critical:
        return 'Critical Risk';
    }
  }

  Future<void> resetToDefaults() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      final defaultSettings = RiskManagement(
        maxDrawdown: 0.0,
        lossPerTradePercentage: 0.0,
        accountBalance: 0.0,
        currentBalance: 0.0,
        isDynamicMaxDrawdown: false,
      );

      _riskService.updateRiskSettings(defaultSettings);
      _riskSettings.value = defaultSettings;

      await _saveRiskSettings();
      await _refreshData();
    } catch (e) {
      _errorMessage.value = 'Failed to reset settings: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> clearAllStoredData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      await clearAllTrades();

      await _configStorage.clearRiskSettings();

      await resetToDefaults();
    } catch (e) {
      _errorMessage.value = 'Failed to clear all data: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _createSimpleBackup() async {
    try {
      final trades = await _riskService.getAllTrades();
      await SimplePersistenceFix.forceSaveData(
        riskSettings: _riskSettings.value,
        trades: trades,
      );
    } catch (e) {
    }
  }

  Future<void> attemptDataRecovery() async {
    try {
      final recoveredData = await SimplePersistenceFix.tryRecoverData();

      if (recoveredData != null) {
        final restored = await SimplePersistenceFix.restoreData(recoveredData);

        if (restored) {

          await forceReload();

          final newTrades = _trades.value.length;
          final newHasSettings = await _configStorage.hasRiskSettings();

          if (newTrades > 0 || newHasSettings) {
            _errorMessage.value = 'Data recovered successfully from backup';
          }
        } else {
          _errorMessage.value = 'Found backup data but failed to restore it';
        }
      } 
    } catch (e) {
      _errorMessage.value = 'Data recovery failed: ${e.toString()}';
    }
  }

  Future<void> forceReload() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      _trades.value = [];
      _statistics.value = null;

      await _loadSavedRiskSettings();
      await _riskService.initializeCurrentBalance();
      await _refreshData();

    } catch (e) {
      _errorMessage.value = 'Failed to reload data: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _initializeDefaultSettings() async {
    try {

      final defaultSettings = InitializationValidator.createDefaultSettings();

      _riskService.updateRiskSettings(defaultSettings);
      _riskSettings.value = defaultSettings;

      _maxDrawdownInput.value = '0.00';
      _lossPerTradeInput.value = '0';

      InitializationValidator.validateStateSynchronization(
        settings: defaultSettings,
        maxDrawdownInput: _maxDrawdownInput.value,
        lossPerTradeInput: _lossPerTradeInput.value,
      );

      await _saveRiskSettings();

    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ChartData {
  final int x;
  final double y;

  ChartData(this.x, this.y);
}

enum InputField { maxDrawdown, lossPerTrade, tradeResult }
