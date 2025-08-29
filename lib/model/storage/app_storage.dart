import 'storage_interface.dart';
import 'shared_preferences_config_storage.dart';
import 'storage_factory.dart';
import '../risk_management.dart';

class AppStorageImpl implements AppStorage {
  late final SharedPreferencesConfigStorage _configStorage;
  late final TradeStorage _tradeStorage;

  AppStorageImpl() {
    _configStorage = SharedPreferencesConfigStorage();
    _tradeStorage = StorageFactory.createTradeStorage();
  }

  @override
  ConfigStorage get config => _configStorage;

  @override
  TradeStorage get trades => _tradeStorage;

  @override
  Future<void> initialize() async {
    try {
      await _tradeStorage.initializeDatabase();
      await _configStorage.migrateIfNeeded();
    } catch (e) {
      throw StorageException(
        'Failed to initialize app storage: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> close() async {
    try {
      await _tradeStorage.close();
    } catch (e) {
      throw StorageException('Failed to close app storage: ${e.toString()}');
    }
  }

  Future<void> clearAllData() async {
    try {
      await _tradeStorage.clearAllTrades();
      await _configStorage.clearAllData();
    } catch (e) {
      throw StorageException('Failed to clear all data: ${e.toString()}');
    }
  }

  Future<bool> hasStoredData() async {
    try {
      final hasConfig = await _configStorage.hasRiskSettings();
      final tradesCount = await _tradeStorage.getTradesCount();
      return hasConfig || tradesCount > 0;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final hasConfig = await _configStorage.hasRiskSettings();
      final tradesCount = await _tradeStorage.getTradesCount();
      final appVersion = await _configStorage.getStoredAppVersion();
      final allKeys = await _configStorage.getAllKeys();

      return {
        'hasConfig': hasConfig,
        'tradesCount': tradesCount,
        'appVersion': appVersion,
        'configKeys': allKeys.toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final riskSettings = await _configStorage.loadRiskSettings();
      final tradesData = await _tradeStorage.exportTrades();

      return {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'riskSettings': riskSettings?.toJson(),
        'trades': tradesData,
      };
    } catch (e) {
      throw StorageException('Failed to export data: ${e.toString()}');
    }
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    try {
      await clearAllData();

      if (data['riskSettings'] != null) {
        final riskSettings = RiskManagement.fromJson(
          data['riskSettings'] as Map<String, dynamic>,
        );
        await _configStorage.saveRiskSettings(riskSettings);
      }

      if (data['trades'] != null) {
        final tradesData = (data['trades'] as List)
            .cast<Map<String, dynamic>>();
        await _tradeStorage.importTrades(tradesData);
      }
    } catch (e) {
      throw StorageException('Failed to import data: ${e.toString()}');
    }
  }
}

class AppStorageManager {
  static AppStorageImpl? _instance;

  static AppStorageImpl get instance {
    _instance ??= AppStorageImpl();
    return _instance!;
  }

  static Future<void> initialize() async {
    _instance ??= AppStorageImpl();
    await _instance!.initialize();
  }

  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
