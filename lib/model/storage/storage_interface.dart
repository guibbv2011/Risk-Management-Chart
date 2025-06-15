import '../trade.dart';
import '../risk_management.dart';

/// Abstract interface for configuration storage
abstract class ConfigStorage {
  Future<void> saveRiskSettings(RiskManagement riskSettings);
  Future<RiskManagement?> loadRiskSettings();
  Future<void> clearRiskSettings();
  Future<bool> hasRiskSettings();
}

/// Abstract interface for trade data storage
abstract class TradeStorage {
  Future<void> initializeDatabase();
  Future<List<Trade>> getAllTrades();
  Future<Trade> saveTrade(Trade trade);
  Future<Trade> updateTrade(Trade trade);
  Future<void> deleteTrade(int id);
  Future<Trade?> getTradeById(int id);
  Future<void> clearAllTrades();
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end);
  Future<int> getTradesCount();
  Future<List<Trade>> getRecentTrades({int limit = 10});
  Future<List<Map<String, dynamic>>> exportTrades();
  Future<void> importTrades(List<Map<String, dynamic>> tradesData);
  Future<void> close();
}

/// Combined storage interface for both config and trades
abstract class AppStorage {
  ConfigStorage get config;
  TradeStorage get trades;
  Future<void> initialize();
  Future<void> close();
}
