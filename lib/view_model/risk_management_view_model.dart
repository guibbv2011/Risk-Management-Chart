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
    _statistics = Signal<TradingStatistics?>(null);
    _riskStatus = Signal<RiskStatus>(RiskStatus.low);
    _isLoading = Signal<bool>(false);
    _errorMessage = Signal<String?>(null);

    // Initialize input fields with current values for better UX
    _maxDrawdownInput = Signal<String>('0.00');
    _lossPerTradeInput = Signal<String>('0');
    _tradeResultInput = Signal<String>('');

    // Validate initial settings
    InitializationValidator.validateInitialValues(_riskService.riskSettings);
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
    List<ChartData> data = [];

    // Always start with 0 point at index 0 (starting point)
    data.add(ChartData(0, 0.0));

    debugPrint('🔢 Generating chart data:');
    debugPrint('   Starting point: (0, 0.0)');

    if (tradesList.isEmpty) {
      debugPrint('   No trades - returning starting point only');
      return data;
    }

    double runningTotal = 0.0;

    for (int i = 0; i < tradesList.length; i++) {
      runningTotal += tradesList[i].result;
      // Add trade points starting from index 1
      data.add(ChartData(i + 1, runningTotal));
      debugPrint(
        '   Trade ${i + 1}: \$${tradesList[i].result.toStringAsFixed(2)} → Running Total: \$${runningTotal.toStringAsFixed(2)}',
      );
    }

    debugPrint('   Final chart data: ${data.length} points');
    return data;
  }

  Future<void> _loadInitialData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      debugPrint('🚀 Starting view model data loading...');

      // Load saved risk settings first
      await _loadSavedRiskSettings();

      // Check if we have any existing trades in storage
      final existingTrades = await _riskService.getAllTrades();
      debugPrint('Found ${existingTrades.length} existing trades in storage');

      // Initialize current balance from existing trades
      await _riskService.initializeCurrentBalance();

      // Refresh all data
      await _refreshData();

      // If we still have no data, attempt recovery
      if (_trades.value.isEmpty && !await _configStorage.hasRiskSettings()) {
        debugPrint('⚠️ No data loaded, attempting recovery...');
        await attemptDataRecovery();
      }

      debugPrint('✅ View model data loading completed');
    } catch (e) {
      _errorMessage.value = 'Failed to load initial data: ${e.toString()}';
      debugPrint('❌ Error loading initial data: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Refreshing data from storage...');

    debugPrint('📊 Loading trades from storage...');
    final trades = await _riskService.getAllTrades();
    debugPrint('📊 Loaded ${trades.length} trades from storage');

    debugPrint('📈 Calculating statistics...');
    final stats = await _riskService.getTradingStatistics();
    final status = await _riskService.checkRiskStatus();

    _trades.value = trades;
    _statistics.value = stats;
    _riskStatus.value = status;
    _riskSettings.value = _riskService.riskSettings;

    debugPrint('✅ Data refresh completed:');
    debugPrint('   Trades loaded: ${trades.length}');
    debugPrint(
      '   Current balance: \$${_riskSettings.value.currentBalance.toStringAsFixed(2)}',
    );
    debugPrint('   Total P&L: \$${stats.totalPnL.toStringAsFixed(2)}');
    debugPrint('   Risk status: ${status.name}');
  }

  /// Load saved risk settings from storage
  Future<void> _loadSavedRiskSettings() async {
    try {
      debugPrint('📂 Loading saved risk settings from storage...');
      final savedSettings = await _configStorage.loadRiskSettings();
      if (savedSettings != null) {
        debugPrint('📄 Found saved settings in storage');
        debugPrint(
          '   Saved Balance: \$${savedSettings.currentBalance.toStringAsFixed(2)}',
        );
        debugPrint(
          '   Saved Max DD: \$${savedSettings.maxDrawdown.toStringAsFixed(2)}',
        );
        debugPrint(
          '   Saved Loss %: ${savedSettings.lossPerTradePercentage.toStringAsFixed(1)}%',
        );

        // Validate loaded settings
        if (_riskService.validateRiskSettings(savedSettings)) {
          _riskService.updateRiskSettings(savedSettings);
          debugPrint('✅ Loaded and applied saved risk settings successfully');
        } else {
          debugPrint('✗ Invalid saved risk settings, using defaults');
        }
      } else {
        debugPrint('No saved risk settings found, initializing with defaults');
        await _initializeDefaultSettings();
      }
    } catch (e) {
      debugPrint('✗ Failed to load saved risk settings: $e');
      // Continue with default settings
    }
  }

  /// Save risk settings to storage
  Future<void> _saveRiskSettings() async {
    try {
      debugPrint('💾 Saving risk settings to storage...');
      debugPrint(
        '   Balance: \$${_riskSettings.value.currentBalance.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Max DD: \$${_riskSettings.value.maxDrawdown.toStringAsFixed(2)}',
      );
      debugPrint(
        '   Loss %: ${_riskSettings.value.lossPerTradePercentage.toStringAsFixed(1)}%',
      );

      await _configStorage.saveRiskSettings(_riskSettings.value);
      debugPrint('✅ Risk settings saved to primary storage successfully');

      // Verify settings were saved by reading them back
      final savedSettings = await _configStorage.loadRiskSettings();
      if (savedSettings != null) {
        debugPrint(
          '📋 Verification: Settings loaded back with balance \$${savedSettings.currentBalance.toStringAsFixed(2)}',
        );
      } else {
        debugPrint('⚠️ Warning: Could not verify saved settings');
      }

      // Create simple backup
      debugPrint('Creating backup copies...');
      await _createSimpleBackup();
      debugPrint('✓ Risk settings backup completed');
    } catch (e) {
      debugPrint('✗ Failed to save risk settings: $e');
      // Don't throw error to avoid interrupting user workflow
    }
  }

  Future<void> addTrade(String tradeResultText) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      final tradeResult = double.parse(tradeResultText);
      final tradesCount = _trades.value.length;

      debugPrint(
        'Adding trade #${tradesCount + 1} with result: \$${tradeResult.toStringAsFixed(2)}',
      );
      debugPrint(
        'Current balance before trade: \$${_riskSettings.value.currentBalance.toStringAsFixed(2)}',
      );

      debugPrint('📤 Saving trade to storage...');
      await _riskService.addTrade(tradeResult);
      debugPrint('✓ Trade added to database successfully');

      // Verify trade was actually saved
      final tradesAfter = await _riskService.getAllTrades();
      debugPrint(
        '📊 Verification: ${tradesAfter.length} trades now in storage',
      );

      _tradeResultInput.value = '';

      // Update local risk settings to reflect the balance change
      _riskSettings.value = _riskService.riskSettings;

      // Save updated risk settings immediately after trade
      debugPrint('💾 Saving updated risk settings after trade...');
      await _saveRiskSettings();
      debugPrint('🔄 Refreshing data after trade addition...');
      await _refreshData();

      debugPrint(
        'New balance after trade: \$${_riskSettings.value.currentBalance.toStringAsFixed(2)}',
      );
      debugPrint('Total trades now: ${_trades.value.length}');

      // Create simple backup after adding trade
      debugPrint('Creating backup after trade addition...');
      await _createSimpleBackup();
      debugPrint('✓ Trade data backup completed');

      // Notify listeners of the state change
      notifyListeners();
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

  Future<void> updateMaxDrawdown(
    String maxDrawdownText,
    String? accountBalanceText, [
    bool? isDynamicEnabled,
  ]) async {
    try {
      _errorMessage.value = null;

      final maxDrawdown = double.parse(maxDrawdownText);

      // Parse account balance if provided
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

      // Calculate current balance based on existing trades if account balance changed
      double currentBalance = _riskSettings.value.currentBalance;
      if (accountBalanceChanged) {
        // Recalculate current balance: new account balance + existing P&L
        final totalPnL = await _riskService.getTotalPnL();
        currentBalance = accountBalance + totalPnL;
      }

      // Validate the update before applying
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

      // Update settings with all related values
      final newSettings = _riskSettings.value.copyWith(
        accountBalance: accountBalance,
        currentBalance: currentBalance,
        maxDrawdown: maxDrawdown,
        isDynamicMaxDrawdown:
            isDynamicEnabled ?? _riskSettings.value.isDynamicMaxDrawdown,
      );

      if (_riskService.validateRiskSettings(newSettings)) {
        _riskService.updateRiskSettings(newSettings);
        _riskSettings.value = newSettings;
        _maxDrawdownInput.value = '';

        // Save settings to storage
        await _saveRiskSettings();
        await _refreshData();

        debugPrint('✅ Max drawdown updated successfully:');
        debugPrint(
          '   Account Balance: \$${accountBalance.toStringAsFixed(2)}',
        );
        debugPrint(
          '   Current Balance: \$${currentBalance.toStringAsFixed(2)}',
        );
        debugPrint('   Max Drawdown: \$${maxDrawdown.toStringAsFixed(2)}');
        debugPrint('   Dynamic Max DD: ${newSettings.isDynamicMaxDrawdown}');

        // Update input signals to reflect new values
        _maxDrawdownInput.value = maxDrawdown.toStringAsFixed(2);

        // Validate state synchronization
        InitializationValidator.validateStateSynchronization(
          settings: newSettings,
          maxDrawdownInput: _maxDrawdownInput.value,
          lossPerTradeInput: _lossPerTradeInput.value,
        );

        // Log current state for verification
        InitializationValidator.logCurrentState(
          newSettings,
          'After Max DD Update',
        );

        // Notify listeners of the state change
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
        _lossPerTradeInput.value = lossPerTrade.toStringAsFixed(0);

        // Save settings to storage
        await _saveRiskSettings();
        await _refreshData();

        // Notify listeners of the state change
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
      debugPrint('Error updating loss per trade: $e');
    }
  }

  Future<void> clearAllTrades() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      debugPrint('🗑️ Clearing all trades from storage...');
      await _riskService.clearAllTrades();
      debugPrint('✅ All trades cleared from storage');

      // Save updated risk settings after clearing trades (balance reset)
      debugPrint('💾 Saving reset risk settings...');
      await _saveRiskSettings();
      debugPrint('🔄 Refreshing data after clearing trades...');
      await _refreshData();

      // Create simple backup after clearing trades
      await _createSimpleBackup();
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

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      // Create default settings
      final defaultSettings = RiskManagement(
        maxDrawdown: 0.0,
        lossPerTradePercentage: 0.0,
        accountBalance: 0.0,
        currentBalance: 0.0,
        isDynamicMaxDrawdown: false,
      );

      // Update service and view model
      _riskService.updateRiskSettings(defaultSettings);
      _riskSettings.value = defaultSettings;

      // Save to storage
      await _saveRiskSettings();
      await _refreshData();
    } catch (e) {
      _errorMessage.value = 'Failed to reset settings: ${e.toString()}';
      debugPrint('Error resetting to defaults: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear all stored data (settings and trades)
  Future<void> clearAllStoredData() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      // Clear trades
      await clearAllTrades();

      // Clear stored settings
      await _configStorage.clearRiskSettings();

      // Reset to defaults
      await resetToDefaults();
    } catch (e) {
      _errorMessage.value = 'Failed to clear all data: ${e.toString()}';
      debugPrint('Error clearing all stored data: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Create simple backup of current data
  Future<void> _createSimpleBackup() async {
    try {
      final trades = await _riskService.getAllTrades();
      await SimplePersistenceFix.forceSaveData(
        riskSettings: _riskSettings.value,
        trades: trades,
      );
      debugPrint('Simple backup created successfully');
    } catch (e) {
      debugPrint('Failed to create simple backup: $e');
      // Don't throw error to avoid interrupting user workflow
    }
  }

  /// Attempt to recover data if current data is empty
  Future<void> attemptDataRecovery() async {
    try {
      debugPrint('🔄 Attempting comprehensive data recovery...');

      // Step 1: Check current state
      final currentTrades = _trades.value.length;
      final hasSettings = await _configStorage.hasRiskSettings();
      debugPrint(
        'Current state - Trades: $currentTrades, Settings: $hasSettings',
      );

      // Step 2: Try backup recovery
      final recoveredData = await SimplePersistenceFix.tryRecoverData();

      if (recoveredData != null) {
        debugPrint('✅ Recovery data found, attempting restore...');
        final restored = await SimplePersistenceFix.restoreData(recoveredData);

        if (restored) {
          debugPrint('✅ Data recovery successful, refreshing view...');

          // Force reload everything
          await forceReload();

          // Verify recovery worked
          final newTrades = _trades.value.length;
          final newHasSettings = await _configStorage.hasRiskSettings();
          debugPrint(
            'After recovery - Trades: $newTrades, Settings: $newHasSettings',
          );

          if (newTrades > 0 || newHasSettings) {
            _errorMessage.value = 'Data recovered successfully from backup';
          }
        } else {
          debugPrint('❌ Data recovery failed during restoration');
          _errorMessage.value = 'Found backup data but failed to restore it';
        }
      } else {
        debugPrint('❌ No recoverable data found in backup locations');

        // Step 3: Try to directly check storage locations
        debugPrint('🔍 Checking storage status...');
        final storageStatus = await SimplePersistenceFix.getStorageStatus();
        debugPrint('Storage status:\n$storageStatus');
      }
    } catch (e) {
      debugPrint('❌ Data recovery attempt failed: $e');
      _errorMessage.value = 'Data recovery failed: ${e.toString()}';
    }
  }

  /// Force reload data from storage
  Future<void> forceReload() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      debugPrint('🔄 Force reload initiated...');

      // Clear view model cached data
      _trades.value = [];
      _statistics.value = null;

      // Reload from storage with verification
      await _loadSavedRiskSettings();
      await _riskService.initializeCurrentBalance();
      await _refreshData();

      // Verify data was loaded
      final finalTradesCount = _trades.value.length;
      final hasSettings = await _configStorage.hasRiskSettings();
      debugPrint(
        '✅ Force reload completed - Trades: $finalTradesCount, Settings: $hasSettings',
      );

      if (finalTradesCount == 0 && !hasSettings) {
        debugPrint(
          '⚠️ Force reload found no data, this might indicate a storage issue',
        );
      }
    } catch (e) {
      _errorMessage.value = 'Failed to reload data: ${e.toString()}';
      debugPrint('❌ Force reload failed: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Initialize default settings when no saved settings exist
  Future<void> _initializeDefaultSettings() async {
    try {
      debugPrint('Initializing default risk settings...');

      // Create default settings using validator
      final defaultSettings = InitializationValidator.createDefaultSettings();

      // Update service and signals
      _riskService.updateRiskSettings(defaultSettings);
      _riskSettings.value = defaultSettings;

      // Update input signals to match
      _maxDrawdownInput.value = '0.00';
      _lossPerTradeInput.value = '0';

      // Validate state synchronization
      InitializationValidator.validateStateSynchronization(
        settings: defaultSettings,
        maxDrawdownInput: _maxDrawdownInput.value,
        lossPerTradeInput: _lossPerTradeInput.value,
      );

      // Save the default settings
      await _saveRiskSettings();

      // Log the initialized state
      InitializationValidator.logCurrentState(
        defaultSettings,
        'Default Initialization',
      );

      debugPrint('✅ Default settings initialized and saved');
    } catch (e) {
      debugPrint('❌ Failed to initialize default settings: $e');
    }
  }

  @override
  void dispose() {
    // Dispose signals if needed
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
