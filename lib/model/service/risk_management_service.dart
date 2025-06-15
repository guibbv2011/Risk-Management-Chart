import '../trade.dart';
import '../risk_management.dart';
import '../repository/trade_repository.dart';

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
    final trade = Trade(id: 0, result: result);

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

    return addedTrade;
  }

  /// Get all trades
  Future<List<Trade>> getAllTrades() async {
    return await _tradeRepository.getAllTrades();
  }

  /// Get comprehensive trading statistics
  Future<TradingStatistics> getTradingStatistics() async {
    final trades = await _tradeRepository.getAllTrades();
    final totalPnL = await _tradeRepository.getTotalPnL();
    final winCount = await _tradeRepository.getWinCount();
    final lossCount = await _tradeRepository.getLossCount();
    final winRate = await _tradeRepository.getWinRate();
    final averageWin = await _tradeRepository.getAverageWin();
    final averageLoss = await _tradeRepository.getAverageLoss();

    return TradingStatistics(
      totalTrades: trades.length,
      totalPnL: totalPnL,
      currentDrawdown: _riskSettings.currentDrawdownAmount,
      maxAllowedDrawdown:
          _riskSettings.isDynamicMaxDrawdown &&
              _riskSettings.currentBalance > _riskSettings.accountBalance
          ? _riskSettings.maxDrawdown +
                (_riskSettings.currentBalance - _riskSettings.accountBalance)
          : _riskSettings.maxDrawdown,
      winCount: winCount,
      lossCount: lossCount,
      winRate: winRate,
      averageWin: averageWin,
      averageLoss: averageLoss,
      remainingRiskCapacity: _riskSettings.remainingRiskCapacity,
      maxLossPerTrade: _riskSettings.maxLossPerTrade,
      riskRewardRatio: averageLoss != 0 ? averageWin / averageLoss.abs() : 0,
      requiredWinRate: _riskSettings.calculateRequiredWinRate(
        averageWin,
        averageLoss.abs(),
      ),
    );
  }

  /// Calculate position size for a given entry and stop loss
  double calculatePositionSize(double entryPrice, double stopLoss) {
    return _riskSettings.calculatePositionSize(entryPrice, stopLoss);
  }

  /// Check if account is approaching risk limits
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

  /// Clear all trades
  Future<void> clearAllTrades() async {
    await _tradeRepository.clearAllTrades();
    // Reset balance to initial account balance
    _riskSettings = _riskSettings.copyWith(
      currentBalance: _riskSettings.accountBalance,
    );
  }

  /// Get trades within a specific date range
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    return await _tradeRepository.getTradesByDateRange(start, end);
  }

  /// Validate risk settings
  bool validateRiskSettings(RiskManagement settings) {
    return settings.maxDrawdown >= 0 &&
        settings.maxDrawdown <= settings.accountBalance &&
        settings.lossPerTradePercentage > 0 &&
        settings.lossPerTradePercentage <= 100 &&
        settings.accountBalance >= 0;
  }

  /// Initialize current balance from repository data
  Future<void> initializeCurrentBalance() async {
    final totalPnL = await _tradeRepository.getTotalPnL();
    final currentBalance = _riskSettings.accountBalance + totalPnL;
    _riskSettings = _riskSettings.copyWith(currentBalance: currentBalance);
  }

  /// Get total P&L from all trades
  Future<double> getTotalPnL() async {
    return await _tradeRepository.getTotalPnL();
  }
}

class TradingStatistics {
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

  TradingStatistics({
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
  });
}

enum RiskStatus { low, medium, high, critical }

class RiskLimitExceededException implements Exception {
  final String message;
  RiskLimitExceededException(this.message);

  @override
  String toString() => 'RiskLimitExceededException: $message';
}
