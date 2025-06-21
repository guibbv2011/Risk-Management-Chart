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
