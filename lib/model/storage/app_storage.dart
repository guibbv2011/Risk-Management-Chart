import 'package:flutter/foundation.dart';
import 'storage_interface.dart';
import 'shared_preferences_config_storage.dart';
import 'sqlite_trade_storage.dart';
import '../risk_management.dart';

/// Combined storage implementation that manages both config and trade storage
class AppStorageImpl implements AppStorage {
  late final SharedPreferencesConfigStorage _configStorage;
  late final SqliteTradeStorage _tradeStorage;

  AppStorageImpl() {
    _configStorage = SharedPreferencesConfigStorage();
    _tradeStorage = SqliteTradeStorage();
  }

  @override
  ConfigStorage get config => _configStorage;

  @override
  TradeStorage get trades => _tradeStorage;

  @override
  Future<void> initialize() async {
    try {
      debugPrint('AppStorage: Starting initialization...');

      // Initialize trade storage (database)
      debugPrint('AppStorage: Initializing trade storage...');
      await _tradeStorage.initializeDatabase();
      debugPrint('AppStorage: Trade storage initialized successfully');

      // Check if config migration is needed
      debugPrint('AppStorage: Checking config migration...');
      await _configStorage.migrateIfNeeded();
      debugPrint('AppStorage: Config migration check completed');

      debugPrint('AppStorage: Initialization completed successfully');
    } catch (e) {
      debugPrint('AppStorage: Initialization failed - ${e.toString()}');
      throw StorageException(
        'Failed to initialize app storage: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> close() async {
    try {
      await _tradeStorage.close();
      // Config storage (SharedPreferences) doesn't need explicit closing
    } catch (e) {
      throw StorageException('Failed to close app storage: ${e.toString()}');
    }
  }

  /// Clear all application data
  Future<void> clearAllData() async {
    try {
      await _tradeStorage.clearAllTrades();
      await _configStorage.clearAllData();
    } catch (e) {
      throw StorageException('Failed to clear all data: ${e.toString()}');
    }
  }

  /// Check if the app has any stored data
  Future<bool> hasStoredData() async {
    try {
      final hasConfig = await _configStorage.hasRiskSettings();
      final tradesCount = await _tradeStorage.getTradesCount();
      return hasConfig || tradesCount > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get storage info for debugging
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

  /// Export all data for backup
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

  /// Import data from backup
  Future<void> importAllData(Map<String, dynamic> data) async {
    try {
      // Clear existing data first
      await clearAllData();

      // Import risk settings if available
      if (data['riskSettings'] != null) {
        final riskSettings = RiskManagement.fromJson(
          data['riskSettings'] as Map<String, dynamic>,
        );
        await _configStorage.saveRiskSettings(riskSettings);
      }

      // Import trades if available
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

/// Singleton instance for app storage
class AppStorageManager {
  static AppStorageImpl? _instance;

  static AppStorageImpl get instance {
    _instance ??= AppStorageImpl();
    return _instance!;
  }

  /// Initialize the storage manager
  static Future<void> initialize() async {
    await instance.initialize();
  }

  /// Close the storage manager
  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
