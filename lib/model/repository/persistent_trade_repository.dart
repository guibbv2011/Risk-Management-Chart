import '../trade.dart';
import '../storage/storage_interface.dart';
import '../../utils/trade_statistics_calculator.dart';
import '../../utils/error_handling.dart';

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

    return await ErrorHandler.handleRepositoryOperation('add trade', () async {
      final savedTrade = await _storage.saveTrade(trade);

      // Update cache
      if (_cachedTrades != null) {
        _cachedTrades!.add(savedTrade);
      }

      return savedTrade;
    }, context: 'PersistentTradeRepository');
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    await _ensureInitialized();

    return await ErrorHandler.handleRepositoryOperation(
      'update trade',
      () async {
        final updatedTrade = await _storage.updateTrade(trade);

        // Update cache
        if (_cachedTrades != null) {
          final index = _cachedTrades!.indexWhere((t) => t.id == trade.id);
          if (index != -1) {
            _cachedTrades![index] = updatedTrade;
          }
        }

        return updatedTrade;
      },
      context: 'PersistentTradeRepository',
    );
  }

  @override
  Future<void> deleteTrade(int id) async {
    await _ensureInitialized();

    return await ErrorHandler.handleRepositoryOperation(
      'delete trade',
      () async {
        await _storage.deleteTrade(id);

        // Update cache
        if (_cachedTrades != null) {
          _cachedTrades!.removeWhere((trade) => trade.id == id);
        }
      },
      context: 'PersistentTradeRepository',
    );
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

    return await ErrorHandler.handleRepositoryOperation(
      'clear all trades',
      () async {
        await _storage.clearAllTrades();
        _clearCache();
      },
      context: 'PersistentTradeRepository',
    );
  }

  @override
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    await _ensureInitialized();

    return await ErrorHandler.handleRepositoryOperation(
      'get trades by date range',
      () async {
        return await _storage.getTradesByDateRange(start, end);
      },
      context: 'PersistentTradeRepository',
    );
  }

  @override
  Future<double> getTotalPnL() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateTotalPnL(trades);
  }

  @override
  Future<double> getCurrentDrawdown() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateCurrentDrawdown(trades);
  }

  @override
  Future<int> getWinCount() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateWinCount(trades);
  }

  @override
  Future<int> getLossCount() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateLossCount(trades);
  }

  @override
  Future<double> getWinRate() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateWinRate(trades);
  }

  @override
  Future<double> getAverageWin() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateAverageWin(trades);
  }

  @override
  Future<double> getAverageLoss() async {
    final trades = await getAllTrades();
    return TradeStatisticsCalculator.calculateAverageLoss(trades);
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

    // // If using SqliteTradeStorage, we can get count efficiently
    // if (_storage is SqliteTradeStorage) {
    //   return await _storage.getTradesCount();
    // }

    // Fallback: load all trades and count
    final trades = await getAllTrades();
    return trades.length;
  }

  /// Get recent trades
  Future<List<Trade>> getRecentTrades({int limit = 10}) async {
    await _ensureInitialized();

    return await ErrorHandler.handleRepositoryOperation(
      'get recent trades',
      () async {
        return await _storage.getRecentTrades(limit: limit);
      },
      context: 'PersistentTradeRepository',
    );
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

    return await ErrorHandler.handleRepositoryOperation(
      'import trades',
      () async {
        // Clear existing trades first
        await clearAllTrades();

        // Add each trade
        for (final tradeData in tradesData) {
          final trade = Trade.fromJson(tradeData);
          // Create trade without ID to let storage assign new ID
          final newTrade = Trade(
            result: trade.result,
            timestamp: trade.timestamp,
          );
          await addTrade(newTrade);
        }
      },
      context: 'PersistentTradeRepository',
    );
  }

  /// Close the repository and clean up resources
  Future<void> close() async {
    await _storage.close();
    _clearCache();
    _isInitialized = false;
  }
}
