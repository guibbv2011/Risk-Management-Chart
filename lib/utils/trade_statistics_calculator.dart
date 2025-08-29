import '../model/trade.dart';


class TradeStatisticsCalculator {
  static double calculateTotalPnL(List<Trade> trades) {
    if (trades.isEmpty) return 0.0;

    double total = 0.0;
    for (final trade in trades) {
      total += trade.result;
    }
    return total;
  }

  static double calculateCurrentDrawdown(List<Trade> trades) {
    if (trades.isEmpty) return 0.0;

    double peak = 0.0;
    double currentBalance = 0.0;
    double maxDrawdown = 0.0;

    for (final trade in trades) {
      currentBalance += trade.result;
      if (currentBalance > peak) {
        peak = currentBalance;
      }
      final drawdown = peak - currentBalance;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }

    return maxDrawdown;
  }

  static int calculateWinCount(List<Trade> trades) {
    return trades.where((trade) => trade.result > 0).length;
  }

  static int calculateLossCount(List<Trade> trades) {
    return trades.where((trade) => trade.result < 0).length;
  }

  static double calculateWinRate(List<Trade> trades) {
    if (trades.isEmpty) return 0.0;
    final winCount = calculateWinCount(trades);
    return (winCount / trades.length) * 100;
  }

  static double calculateAverageWin(List<Trade> trades) {
    final wins = trades.where((trade) => trade.result > 0).toList();
    if (wins.isEmpty) return 0.0;

    double total = 0.0;
    for (final trade in wins) {
      total += trade.result;
    }
    return total / wins.length;
  }

  static double calculateAverageLoss(List<Trade> trades) {
    final losses = trades.where((trade) => trade.result < 0).toList();
    if (losses.isEmpty) return 0.0;

    double total = 0.0;
    for (final trade in losses) {
      total += trade.result;
    }
    return total / losses.length;
  }

  static TradeStatistics calculateAllStatistics(List<Trade> trades) {
    if (trades.isEmpty) {
      return TradeStatistics(
        totalTrades: 0,
        totalPnL: 0.0,
        currentDrawdown: 0.0,
        winCount: 0,
        lossCount: 0,
        winRate: 0.0,
        averageWin: 0.0,
        averageLoss: 0.0,
        bestWin: 0.0,
        worstLoss: 0.0,
        profitFactor: 0.0,
        riskRewardRatio: 0.0,
      );
    }

    double totalPnL = 0.0;
    int winCount = 0;
    int lossCount = 0;
    double totalWins = 0.0;
    double totalLosses = 0.0;
    double bestWin = double.negativeInfinity;
    double worstLoss = double.infinity;

    for (final trade in trades) {
      totalPnL += trade.result;

      if (trade.result > 0) {
        winCount++;
        totalWins += trade.result;
        if (trade.result > bestWin) {
          bestWin = trade.result;
        }
      } else if (trade.result < 0) {
        lossCount++;
        totalLosses += trade.result;
        if (trade.result < worstLoss) {
          worstLoss = trade.result;
        }
      }
    }

    final winRate = (winCount / trades.length) * 100;
    final averageWin = winCount > 0 ? totalWins / winCount : 0.0;
    final averageLoss = lossCount > 0 ? totalLosses / lossCount : 0.0;
    final currentDrawdown = calculateCurrentDrawdown(trades);

    final profitFactor = totalLosses != 0 ? totalWins / totalLosses.abs() : 0.0;

    final riskRewardRatio = averageLoss != 0
        ? averageWin / averageLoss.abs()
        : 0.0;

    return TradeStatistics(
      totalTrades: trades.length,
      totalPnL: totalPnL,
      currentDrawdown: currentDrawdown,
      winCount: winCount,
      lossCount: lossCount,
      winRate: winRate,
      averageWin: averageWin,
      averageLoss: averageLoss,
      bestWin: bestWin == double.negativeInfinity ? 0.0 : bestWin,
      worstLoss: worstLoss == double.infinity ? 0.0 : worstLoss,
      profitFactor: profitFactor,
      riskRewardRatio: riskRewardRatio,
    );
  }

  static List<Trade> filterTradesByDateRange(
    List<Trade> trades,
    DateTime start,
    DateTime end,
  ) {
    return trades
        .where(
          (trade) =>
              trade.timestamp.isAfter(
                start.subtract(const Duration(days: 1)),
              ) &&
              trade.timestamp.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  static List<Trade> getSortedTrades(
    List<Trade> trades, {
    bool ascending = true,
  }) {
    final sortedTrades = List<Trade>.from(trades);
    sortedTrades.sort(
      (a, b) => ascending
          ? a.timestamp.compareTo(b.timestamp)
          : b.timestamp.compareTo(a.timestamp),
    );
    return sortedTrades;
  }

  static List<Trade> getRecentTrades(List<Trade> trades, {int limit = 10}) {
    final sortedTrades = getSortedTrades(trades, ascending: false);
    return sortedTrades.take(limit).toList();
  }
}

class TradeStatistics {
  final int totalTrades;
  final double totalPnL;
  final double currentDrawdown;
  final int winCount;
  final int lossCount;
  final double winRate;
  final double averageWin;
  final double averageLoss;
  final double bestWin;
  final double worstLoss;
  final double profitFactor;
  final double riskRewardRatio;

  const TradeStatistics({
    required this.totalTrades,
    required this.totalPnL,
    required this.currentDrawdown,
    required this.winCount,
    required this.lossCount,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.bestWin,
    required this.worstLoss,
    required this.profitFactor,
    required this.riskRewardRatio,
  });

  @override
  String toString() {
    return 'TradeStatistics('
        'totalTrades: $totalTrades, '
        'totalPnL: ${totalPnL.toStringAsFixed(2)}, '
        'winRate: ${winRate.toStringAsFixed(1)}%, '
        'profitFactor: ${profitFactor.toStringAsFixed(2)}'
        ')';
  }
}
