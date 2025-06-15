import '../trade.dart';

abstract class TradeRepository {
  Future<List<Trade>> getAllTrades();
  Future<Trade> addTrade(Trade trade);
  Future<Trade> updateTrade(Trade trade);
  Future<void> deleteTrade(int id);
  Future<Trade?> getTradeById(int id);
  Future<void> clearAllTrades();
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end);
  Future<double> getTotalPnL();
  Future<double> getCurrentDrawdown();
  Future<int> getWinCount();
  Future<int> getLossCount();
  Future<double> getWinRate();
  Future<double> getAverageWin();
  Future<double> getAverageLoss();
}

class InMemoryTradeRepository implements TradeRepository {
  final List<Trade> _trades = [Trade(id: 0, result: 0.0)];
  int _nextId = 0;

  @override
  Future<List<Trade>> getAllTrades() async {
    return List.unmodifiable(_trades);
  }

  @override
  Future<Trade> addTrade(Trade trade) async {
    final newTrade = trade.copyWith(id: _nextId++);
    _trades.add(newTrade);
    return newTrade;
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final index = _trades.indexWhere((t) => t.id == trade.id);
    if (index == -1) {
      throw Exception('Trade with id ${trade.id} not found');
    }
    _trades[index] = trade;
    return trade;
  }

  @override
  Future<void> deleteTrade(int id) async {
    final index = _trades.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Trade with id $id not found');
    }
    _trades.removeAt(index);
  }

  @override
  Future<Trade?> getTradeById(int id) async {
    try {
      return _trades.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearAllTrades() async {
    _trades.clear();
    _nextId = 0;
  }

  @override
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    return _trades
        .where(
          (trade) =>
              trade.timestamp.isAfter(
                start.subtract(const Duration(days: 1)),
              ) &&
              trade.timestamp.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  // Additional helper methods for statistics
  @override
  Future<double> getTotalPnL() async {
    double total = 0.0;
    for (final trade in _trades) {
      total += trade.result;
    }
    return total;
  }

  @override
  Future<double> getCurrentDrawdown() async {
    if (_trades.isEmpty) return 0.0;

    double peak = 0.0;
    double currentBalance = 0.0;
    double maxDrawdown = 0.0;

    for (final trade in _trades) {
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

  @override
  Future<int> getWinCount() async {
    return _trades.where((trade) => trade.result > 0).length;
  }

  @override
  Future<int> getLossCount() async {
    return _trades.where((trade) => trade.result < 0).length;
  }

  @override
  Future<double> getWinRate() async {
    if (_trades.isEmpty) return 0.0;
    final winCount = await getWinCount();
    return (winCount / _trades.length) * 100;
  }

  @override
  Future<double> getAverageWin() async {
    final wins = _trades.where((trade) => trade.result > 0).toList();
    if (wins.isEmpty) return 0.0;
    double total = 0.0;
    for (final trade in wins) {
      total += trade.result;
    }
    return total / wins.length;
  }

  @override
  Future<double> getAverageLoss() async {
    final losses = _trades.where((trade) => trade.result < 0).toList();
    if (losses.isEmpty) return 0.0;
    double total = 0.0;
    for (final trade in losses) {
      total += trade.result;
    }
    return total / losses.length;
  }
}
