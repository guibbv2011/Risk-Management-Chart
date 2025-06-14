import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../model/trade.dart';
import '../model/risk_management.dart';
import '../model/service/risk_management_service.dart';

class RiskManagementViewModel extends ChangeNotifier {
  final RiskManagementService _riskService;

  // Signals for reactive state management
  late final Signal<List<Trade>> _trades;
  late final Signal<RiskManagement> _riskSettings;
  late final Signal<TradingStatistics?> _statistics;
  late final Signal<RiskStatus> _riskStatus;
  late final Signal<bool> _isLoading;
  late final Signal<String?> _errorMessage;

  // Input field signals
  late final Signal<String> _maxDrawdownInput;
  late final Signal<String> _lossPerTradeInput;
  late final Signal<String> _tradeResultInput;

  RiskManagementViewModel({required RiskManagementService riskService})
    : _riskService = riskService {
    _initializeSignals();
    _loadInitialData();
  }

  void _initializeSignals() {
    _trades = Signal<List<Trade>>([]);
    _riskSettings = Signal<RiskManagement>(_riskService.riskSettings);
    _statistics = Signal<TradingStatistics?>(null);
    _riskStatus = Signal<RiskStatus>(RiskStatus.low);
    _isLoading = Signal<bool>(false);
    _errorMessage = Signal<String?>(null);

    _maxDrawdownInput = Signal<String>('');
    _lossPerTradeInput = Signal<String>('');
    _tradeResultInput = Signal<String>('');
  }

  // Getters for signals
  Signal<List<Trade>> get trades => _trades;
  Signal<RiskManagement> get riskSettings => _riskSettings;
  Signal<TradingStatistics?> get statistics => _statistics;
  Signal<RiskStatus> get riskStatus => _riskStatus;
  Signal<bool> get isLoading => _isLoading;
  Signal<String?> get errorMessage => _errorMessage;

  Signal<String> get maxDrawdownInput => _maxDrawdownInput;
  Signal<String> get lossPerTradeInput => _lossPerTradeInput;
  Signal<String> get tradeResultInput => _tradeResultInput;

  // Computed properties
  String get formattedMaxLossPerTrade {
    return _riskSettings.value.maxLossPerTrade.toStringAsFixed(2);
  }

  List<ChartData> get chartData {
    final tradesList = _trades.value;
    if (tradesList.isEmpty) {
      return [ChartData(0, 0.0)];
    }

    double runningTotal = 0.0;
    List<ChartData> data = [];

    for (int i = 0; i < tradesList.length; i++) {
      runningTotal += tradesList[i].result;
      data.add(ChartData(i + 1, runningTotal));
    }

    return data;
  }

  Future<void> _loadInitialData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      // Initialize current balance from existing trades
      await _riskService.initializeCurrentBalance();
      await _refreshData();
    } catch (e) {
      _errorMessage.value = 'Failed to load initial data: ${e.toString()}';
      debugPrint('Error loading initial data: $e');
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

  Future<void> addTrade(String tradeResultText) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      final tradeResult = double.parse(tradeResultText);
      await _riskService.addTrade(tradeResult);

      _tradeResultInput.value = '';
      // Update local risk settings to reflect the balance change
      _riskSettings.value = _riskService.riskSettings;
      await _refreshData();
    } on FormatException {
      _errorMessage.value =
          'Invalid trade result format. Please enter a valid number.';
    } on RiskLimitExceededException catch (e) {
      _errorMessage.value = e.message;
    } catch (e) {
      _errorMessage.value = 'Failed to add trade: ${e.toString()}';
      debugPrint('Error adding trade: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateMaxDrawdown(String maxDrawdownText, [bool? isDynamicEnabled]) async {
    try {
      _errorMessage.value = null;

      final maxDrawdown = double.parse(maxDrawdownText);
      if (maxDrawdown <= 0 ||
          maxDrawdown > _riskSettings.value.accountBalance) {
        throw ArgumentError(
          'Max drawdown must be between \$0 and \$${_riskSettings.value.accountBalance.toStringAsFixed(2)}',
        );
      }

      // Preserve current balance when updating max drawdown and set dynamic toggle
      final newSettings = _riskSettings.value.copyWith(
        maxDrawdown: maxDrawdown,
        isDynamicMaxDrawdown: isDynamicEnabled ?? _riskSettings.value.isDynamicMaxDrawdown,
      );

      if (_riskService.validateRiskSettings(newSettings)) {
        _riskService.updateRiskSettings(newSettings);
        _riskSettings.value = newSettings;
        _maxDrawdownInput.value = '';
        await _refreshData();
      } else {
        throw ArgumentError('Invalid risk settings');
      }
    } on FormatException {
      _errorMessage.value =
          'Invalid max drawdown format. Please enter a valid dollar amount.';
    } on ArgumentError catch (e) {
      _errorMessage.value = e.message;
    } catch (e) {
      _errorMessage.value = 'Failed to update max drawdown: ${e.toString()}';
      debugPrint('Error updating max drawdown: $e');
    }
  }

  Future<void> updateLossPerTrade(String lossPerTradeText) async {
    try {
      _errorMessage.value = null;

      final lossPerTrade = double.parse(lossPerTradeText);
      if (lossPerTrade <= 0 || lossPerTrade > 100) {
        throw ArgumentError('Loss per trade must be between 0 and 100');
      }

      // Preserve current balance when updating loss per trade percentage
      final newSettings = _riskSettings.value.copyWith(
        lossPerTradePercentage: lossPerTrade,
      );

      if (_riskService.validateRiskSettings(newSettings)) {
        _riskService.updateRiskSettings(newSettings);
        _riskSettings.value = newSettings;
        _lossPerTradeInput.value = '';
        await _refreshData();
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
      debugPrint('Error updating loss per trade: $e');
    }
  }

  Future<void> clearAllTrades() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      await _riskService.clearAllTrades();
      await _refreshData();
    } catch (e) {
      _errorMessage.value = 'Failed to clear trades: ${e.toString()}';
      debugPrint('Error clearing trades: $e');
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
        return const Color(0xFF4CAF50); // Green
      case RiskStatus.medium:
        return const Color(0xFFFF9800); // Orange
      case RiskStatus.high:
        return const Color(0xFFFF5722); // Deep Orange
      case RiskStatus.critical:
        return const Color(0xFFF44336); // Red
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

  @override
  void dispose() {
    // Dispose of signals if needed
    super.dispose();
  }
}

// Helper classes
class ChartData {
  final int x;
  final double y;

  ChartData(this.x, this.y);
}

enum InputField { maxDrawdown, lossPerTrade, tradeResult }
