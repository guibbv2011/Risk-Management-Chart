import '../trade.dart';
import '../risk_management.dart';
import '../repository/trade_repository.dart';
import '../../utils/trade_statistics_calculator.dart';
import '../../utils/error_handling.dart';
import '../../utils/date_time_utils.dart';

class RiskManagementService {
  final TradeRepository _tradeRepository;
  RiskManagement _riskSettings;

  RiskManagementService({
    required TradeRepository tradeRepository,
    required RiskManagement riskSettings,
  }) : _tradeRepository = tradeRepository,
       _riskSettings = riskSettings;

  RiskManagement get riskSettings => _riskSettings;

  void updateRiskSettings(RiskManagement newSettings) {
    _riskSettings = newSettings;
  }

  /// Add a new trade and validate it against risk parameters
  Future<Trade> addTrade(double result) async {
    return await ErrorHandler.handleServiceOperation('add trade', () async {
      // Validate trade result
      final validatedResult = ValidationRules.validateTradeResult(result);
      final trade = Trade(id: 0, result: validatedResult);

      // Only validate negative trades (losses) against risk limits
      // Positive trades (profits) have no limit
      if (result < 0 && !_riskSettings.isTradeWithinRiskLimits(result)) {
        throw RiskLimitExceededException(
          'Trade loss amount \$${result.abs().toStringAsFixed(2)} exceeds maximum allowed loss per trade \$${_riskSettings.maxLossPerTrade.toStringAsFixed(2)}',
        );
      }

      // Check if adding this trade would exceed maximum drawdown
      if (result < 0 && _riskSettings.wouldExceedMaxDrawdown(result)) {
        final effectiveMaxDrawdown =
            _riskSettings.isDynamicMaxDrawdown &&
                _riskSettings.currentBalance > _riskSettings.accountBalance
            ? _riskSettings.maxDrawdown +
                  (_riskSettings.currentBalance - _riskSettings.accountBalance)
            : _riskSettings.maxDrawdown;

        throw RiskLimitExceededException(
          'Adding this trade would exceed maximum drawdown limit. Current Balance: \$${_riskSettings.currentBalance.toStringAsFixed(2)}, Effective Max Drawdown: \$${effectiveMaxDrawdown.toStringAsFixed(2)}',
        );
      }

      // Add the trade and update current balance in risk settings
      final addedTrade = await _tradeRepository.addTrade(trade);
      _riskSettings = _riskSettings.updateBalance(result);
      if (result >= 0) {
        final cumulativePnL = _riskSettings.currentBalance - _riskSettings.accountBalance;
        final currentDD = _riskSettings.currentDrawdownThreshold;
        final distance = cumulativePnL - currentDD;
        if (distance >= _riskSettings.maxDrawdown) {
          double newDD = cumulativePnL - _riskSettings.maxDrawdown;
          if (!_riskSettings.isDynamicMaxDrawdown && newDD > 0) {
            newDD = 0;
          }
          _riskSettings = _riskSettings.copyWith(currentDrawdownThreshold: newDD);
        }
      }
      return addedTrade;
    }, context: 'RiskManagementService');
  }

  /// Get all trades
  Future<List<Trade>> getAllTrades() async {
    return await ErrorHandler.handleServiceOperation(
      'get all trades',
      () async {
        return await _tradeRepository.getAllTrades();
      },
      context: 'RiskManagementService',
    );
  }

  /// Get comprehensive trading statistics
  Future<ServiceTradingStatistics> getTradingStatistics() async {
    return await ErrorHandler.handleServiceOperation(
      'get trading statistics',
      () async {
        final trades = await _tradeRepository.getAllTrades();

        // Use the utility to calculate basic statistics efficiently
        final basicStats = TradeStatisticsCalculator.calculateAllStatistics(
          trades,
        );

        // Calculate risk-specific metrics
        final maxAllowedDrawdown =
            _riskSettings.isDynamicMaxDrawdown &&
                _riskSettings.currentBalance > _riskSettings.accountBalance
            ? _riskSettings.maxDrawdown +
                  (_riskSettings.currentBalance - _riskSettings.accountBalance)
            : _riskSettings.maxDrawdown;

        return ServiceTradingStatistics(
          totalTrades: basicStats.totalTrades,
          totalPnL: basicStats.totalPnL,
          currentDrawdown: _riskSettings.currentDrawdownAmount,
          maxAllowedDrawdown: maxAllowedDrawdown,
          winCount: basicStats.winCount,
          lossCount: basicStats.lossCount,
          winRate: basicStats.winRate,
          averageWin: basicStats.averageWin,
          averageLoss: basicStats.averageLoss,
          remainingRiskCapacity: _riskSettings.remainingRiskCapacity,
          maxLossPerTrade: _riskSettings.maxLossPerTrade,
          riskRewardRatio: basicStats.riskRewardRatio,
          requiredWinRate: _riskSettings.calculateRequiredWinRate(
            basicStats.averageWin,
            basicStats.averageLoss.abs(),
          ),
          bestWin: basicStats.bestWin,
          worstLoss: basicStats.worstLoss,
          profitFactor: basicStats.profitFactor,
        );
      },
      context: 'RiskManagementService',
    );
  }

  /// Calculate position size for a given entry and stop loss
  double calculatePositionSize(double entryPrice, double stopLoss) {
    return _riskSettings.calculatePositionSize(entryPrice, stopLoss);
  }

  /// Check if account is approaching risk limits
  Future<RiskStatus> checkRiskStatus() async {
    final cumulativePnL = _riskSettings.currentBalance - _riskSettings.accountBalance;
    final distance = cumulativePnL - _riskSettings.currentDrawdownThreshold;
    final maxDD = _riskSettings.maxDrawdown;
    if (maxDD == 0) {
      return RiskStatus.low;
    }
    final ratio = distance / maxDD;
    if (ratio <= 0) {
      return RiskStatus.critical;
    } else if (ratio <= 0.2) {
      return RiskStatus.high;
    } else if (ratio <= 0.5) {
      return RiskStatus.medium;
    } else {
      return RiskStatus.low;
    }
  }

  /// Clear all trades
  Future<void> clearAllTrades() async {
    return await ErrorHandler.handleServiceOperation(
      'clear all trades',
      () async {
        await _tradeRepository.clearAllTrades();
        // Reset balance to initial account balance
        _riskSettings = _riskSettings.copyWith(
          currentBalance: _riskSettings.accountBalance,
          currentDrawdownThreshold: -_riskSettings.maxDrawdown,
        );
      },
      context: 'RiskManagementService',
    );
  }

  /// Get trades within a specific date range
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    return await ErrorHandler.handleServiceOperation(
      'get trades by date range',
      () async {
        // Validate date range
        if (!DateTimeUtils.isValidDateRange(start, end)) {
          throw ValidationException(
            'Invalid date range: start date must be before or equal to end date',
          );
        }

        return await _tradeRepository.getTradesByDateRange(start, end);
      },
      context: 'RiskManagementService',
    );
  }

  /// Validate risk settings
  bool validateRiskSettings(RiskManagement settings) {
    try {
      ValidationRules.validateAccountBalance(settings.accountBalance);
      ValidationRules.validateMaxDrawdown(
        settings.maxDrawdown,
        settings.accountBalance,
      );
      ValidationRules.validateLossPercentage(settings.lossPerTradePercentage);
      return true;
    } catch (e) {
      ErrorHandler.logError(
        'RiskManagementService',
        e,
        additionalInfo: 'Risk settings validation',
      );
      return false;
    }
  }

  /// Initialize current balance from repository data
  Future<void> initializeCurrentBalance() async {
    return await ErrorHandler.handleServiceOperation(
      'initialize current balance',
      () async {
        final totalPnL = await _tradeRepository.getTotalPnL();
        final currentBalance = _riskSettings.accountBalance + totalPnL;
        _riskSettings = _riskSettings.copyWith(currentBalance: currentBalance);
      },
      context: 'RiskManagementService',
    );
  }

  /// Get total P&L from all trades
  Future<double> getTotalPnL() async {
    return await ErrorHandler.handleServiceOperation('get total PnL', () async {
      return await _tradeRepository.getTotalPnL();
    }, context: 'RiskManagementService');
  }
}

/// Extended trading statistics that includes risk management specific data
class ServiceTradingStatistics {
  final int totalTrades;
  final double totalPnL;
  final double currentDrawdown;
  final double maxAllowedDrawdown;
  final int winCount;
  final int lossCount;
  final double winRate;
  final double averageWin;
  final double averageLoss;
  final double remainingRiskCapacity;
  final double maxLossPerTrade;
  final double riskRewardRatio;
  final double requiredWinRate;
  final double bestWin;
  final double worstLoss;
  final double profitFactor;

  const ServiceTradingStatistics({
    required this.totalTrades,
    required this.totalPnL,
    required this.currentDrawdown,
    required this.maxAllowedDrawdown,
    required this.winCount,
    required this.lossCount,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.remainingRiskCapacity,
    required this.maxLossPerTrade,
    required this.riskRewardRatio,
    required this.requiredWinRate,
    required this.bestWin,
    required this.worstLoss,
    required this.profitFactor,
  });

  @override
  String toString() {
    return 'ServiceTradingStatistics('
        'totalTrades: $totalTrades, '
        'totalPnL: ${totalPnL.toStringAsFixed(2)}, '
        'winRate: ${winRate.toStringAsFixed(1)}%, '
        'profitFactor: ${profitFactor.toStringAsFixed(2)}, '
        'riskRewardRatio: ${riskRewardRatio.toStringAsFixed(2)}'
        ')';
  }
}

enum RiskStatus { low, medium, high, critical }

/// Risk-specific exception that extends the common ServiceException
class RiskLimitExceededException extends ServiceException {
  const RiskLimitExceededException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code ?? 'RISK_LIMIT_EXCEEDED',
         originalError: originalError,
         stackTrace: stackTrace,
       );

  @override
  String toString() => 'RiskLimitExceededException: $message';
}
