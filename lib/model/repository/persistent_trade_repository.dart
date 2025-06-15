import '../trade.dart';
import '../storage/storage_interface.dart';
import '../storage/sqlite_trade_storage.dart';
import 'trade_repository.dart';

/// Persistent implementation of TradeRepository using local storage
class PersistentTradeRepository implements TradeRepository {
  final TradeStorage _storage;
  List<Trade>? _cachedTrades;
  bool _isInitialized = false;

  PersistentTradeRepository({required TradeStorage storage})
    : _storage = storage;

  /// Ensure the repository is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _storage.initializeDatabase();
      _isInitialized = true;
    }
  }

  /// Clear cache to force reload from storage
  void _clearCache() {
    _cachedTrades = null;
  }

  @override
  Future<List<Trade>> getAllTrades() async {
    await _ensureInitialized();

    // Use cache if available, otherwise load from storage
    if (_cachedTrades == null) {
      _cachedTrades = await _storage.getAllTrades();
    }

    return List.unmodifiable(_cachedTrades!);
  }

  @override
  Future<Trade> addTrade(Trade trade) async {
    await _ensureInitialized();

    try {
      final savedTrade = await _storage.saveTrade(trade);

      // Update cache
      if (_cachedTrades != null) {
        _cachedTrades!.add(savedTrade);
      }

      return savedTrade;
    } catch (e) {
      throw Exception('Failed to add trade: ${e.toString()}');
    }
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    await _ensureInitialized();

    try {
      final updatedTrade = await _storage.updateTrade(trade);

      // Update cache
      if (_cachedTrades != null) {
        final index = _cachedTrades!.indexWhere((t) => t.id == trade.id);
        if (index != -1) {
          _cachedTrades![index] = updatedTrade;
        }
      }

      return updatedTrade;
    } catch (e) {
      throw Exception('Failed to update trade: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTrade(int id) async {
    await _ensureInitialized();

    try {
      await _storage.deleteTrade(id);

      // Update cache
      if (_cachedTrades != null) {
        _cachedTrades!.removeWhere((trade) => trade.id == id);
      }
    } catch (e) {
      throw Exception('Failed to delete trade: ${e.toString()}');
    }
  }

  @override
  Future<Trade?> getTradeById(int id) async {
    await _ensureInitialized();

    // First check cache
    if (_cachedTrades != null) {
      try {
        return _cachedTrades!.firstWhere((trade) => trade.id == id);
      } catch (e) {
        return null;
      }
    }

    // If not in cache, get from storage
    return await _storage.getTradeById(id);
  }

  @override
  Future<void> clearAllTrades() async {
    await _ensureInitialized();

    try {
      await _storage.clearAllTrades();
      _clearCache();
    } catch (e) {
      throw Exception('Failed to clear all trades: ${e.toString()}');
    }
  }

  @override
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    await _ensureInitialized();

    try {
      return await _storage.getTradesByDateRange(start, end);
    } catch (e) {
      throw Exception('Failed to get trades by date range: ${e.toString()}');
    }
  }

  @override
  Future<double> getTotalPnL() async {
    final trades = await getAllTrades();
    double total = 0.0;
    for (final trade in trades) {
      total += trade.result;
    }
    return total;
  }

  @override
  Future<double> getCurrentDrawdown() async {
    final trades = await getAllTrades();
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

  @override
  Future<int> getWinCount() async {
    final trades = await getAllTrades();
    return trades.where((trade) => trade.result > 0).length;
  }

  @override
  Future<int> getLossCount() async {
    final trades = await getAllTrades();
    return trades.where((trade) => trade.result < 0).length;
  }

  @override
  Future<double> getWinRate() async {
    final trades = await getAllTrades();
    if (trades.isEmpty) return 0.0;
    final winCount = await getWinCount();
    return (winCount / trades.length) * 100;
  }

  @override
  Future<double> getAverageWin() async {
    final trades = await getAllTrades();
    final wins = trades.where((trade) => trade.result > 0).toList();
    if (wins.isEmpty) return 0.0;

    double total = 0.0;
    for (final trade in wins) {
      total += trade.result;
    }
    return total / wins.length;
  }

  @override
  Future<double> getAverageLoss() async {
    final trades = await getAllTrades();
    final losses = trades.where((trade) => trade.result < 0).toList();
    if (losses.isEmpty) return 0.0;

    double total = 0.0;
    for (final trade in losses) {
      total += trade.result;
    }
    return total / losses.length;
  }

  /// Force refresh cache from storage
  Future<void> refreshCache() async {
    await _ensureInitialized();
    _clearCache();
    await getAllTrades(); // This will reload the cache
  }

  /// Get the number of trades without loading all trades into memory
  Future<int> getTradesCount() async {
    await _ensureInitialized();

    if (_cachedTrades != null) {
      return _cachedTrades!.length;
    }

    // If using SqliteTradeStorage, we can get count efficiently
    if (_storage is SqliteTradeStorage) {
      return await _storage.getTradesCount();
    }

    // Fallback: load all trades and count
    final trades = await getAllTrades();
    return trades.length;
  }

  /// Get recent trades
  Future<List<Trade>> getRecentTrades({int limit = 10}) async {
    await _ensureInitialized();

    // If using SqliteTradeStorage, use efficient method
    if (_storage is SqliteTradeStorage) {
      return await _storage.getRecentTrades(limit: limit);
    }

    // Fallback: get all trades and take the most recent
    final trades = await getAllTrades();
    trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return trades.take(limit).toList();
  }

  /// Export trades for backup
  Future<List<Map<String, dynamic>>> exportTrades() async {
    await _ensureInitialized();

    final trades = await getAllTrades();
    return trades.map((trade) => trade.toJson()).toList();
  }

  /// Import trades from backup
  Future<void> importTrades(List<Map<String, dynamic>> tradesData) async {
    await _ensureInitialized();

    try {
      // Clear existing trades first
      await clearAllTrades();

      // Add each trade
      for (final tradeData in tradesData) {
        final trade = Trade.fromJson(tradeData);
        // Create trade without ID to let storage assign new ID
        final newTrade = Trade(
          id: 0, // Will be assigned by storage
          result: trade.result,
          timestamp: trade.timestamp,
        );
        await addTrade(newTrade);
      }
    } catch (e) {
      throw Exception('Failed to import trades: ${e.toString()}');
    }
  }

  /// Close the repository and clean up resources
  Future<void> close() async {
    await _storage.close();
    _clearCache();
    _isInitialized = false;
  }
}
