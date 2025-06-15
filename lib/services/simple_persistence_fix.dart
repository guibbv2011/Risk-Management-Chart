import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/storage/app_storage.dart';
import '../model/risk_management.dart';
import '../model/trade.dart';

// Conditional import for web-only HTML operations
import 'simple_persistence_web.dart'
    if (dart.library.io) 'simple_persistence_native.dart';

/// Simple web storage persistence fix
class SimplePersistenceFix {
  static const String _backupPrefix = 'backup_';
  static const String _debugPrefix = '[SimplePersistenceFix]';

  /// Force save data to multiple storage locations
  static Future<bool> forceSaveData({
    required RiskManagement riskSettings,
    required List<Trade> trades,
  }) async {
    debugPrint('$_debugPrefix Force saving data...');

    final backupData = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'riskSettings': riskSettings.toJson(),
      'trades': trades.map((t) => t.toJson()).toList(),
    };

    final jsonString = jsonEncode(backupData);
    int successCount = 0;

    // Save to SharedPreferences (works on all platforms)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_backupPrefix}data', jsonString);
      await prefs.setString('risk_settings', jsonEncode(riskSettings.toJson()));
      successCount++;
      debugPrint('$_debugPrefix ✓ SharedPreferences backup saved');
    } catch (e) {
      debugPrint('$_debugPrefix ✗ SharedPreferences failed: $e');
    }

    // Save to web storage (only on web platform)
    if (kIsWeb) {
      final webSuccessCount = await PlatformPersistence.saveToWebStorage(
        backupPrefix: _backupPrefix,
        jsonString: jsonString,
        riskSettings: riskSettings,
      );
      successCount += webSuccessCount;
    }

    final success = successCount > 0;
    debugPrint(
      '$_debugPrefix Force save completed: $success ($successCount saves)',
    );
    return success;
  }

  /// Try to recover data from backups
  static Future<Map<String, dynamic>?> tryRecoverData() async {
    debugPrint('$_debugPrefix Attempting data recovery...');

    // Try SharedPreferences first (works on all platforms)
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = prefs.getString('${_backupPrefix}data');
      if (backupData != null) {
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        debugPrint('$_debugPrefix ✓ Data recovered from SharedPreferences');
        return data;
      }

      // Try individual risk settings
      final riskData = prefs.getString('risk_settings');
      if (riskData != null) {
        final riskSettings = jsonDecode(riskData) as Map<String, dynamic>;
        debugPrint(
          '$_debugPrefix ✓ Risk settings recovered from SharedPreferences',
        );
        return {
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
          'riskSettings': riskSettings,
          'trades': <Map<String, dynamic>>[],
        };
      }
    } catch (e) {
      debugPrint('$_debugPrefix SharedPreferences recovery failed: $e');
    }

    // Try web storage recovery (only on web)
    if (kIsWeb) {
      final webData = await PlatformPersistence.recoverFromWebStorage(
        backupPrefix: _backupPrefix,
      );
      if (webData != null) {
        return webData;
      }
    }

    debugPrint('$_debugPrefix No recoverable data found');
    return null;
  }

  /// Restore data to app storage
  static Future<bool> restoreData(Map<String, dynamic> data) async {
    debugPrint('$_debugPrefix Restoring data...');

    try {
      final appStorage = AppStorageManager.instance;

      // Restore risk settings
      if (data['riskSettings'] != null) {
        final riskSettings = RiskManagement.fromJson(
          data['riskSettings'] as Map<String, dynamic>,
        );
        await appStorage.config.saveRiskSettings(riskSettings);
        debugPrint('$_debugPrefix ✓ Risk settings restored');
      }

      // Restore trades
      if (data['trades'] != null) {
        final tradesData = (data['trades'] as List)
            .cast<Map<String, dynamic>>();
        if (tradesData.isNotEmpty) {
          await appStorage.trades.clearAllTrades();
          await appStorage.trades.importTrades(tradesData);
          debugPrint('$_debugPrefix ✓ ${tradesData.length} trades restored');
        }
      }

      return true;
    } catch (e) {
      debugPrint('$_debugPrefix Restore failed: $e');
      return false;
    }
  }

  /// Check if we're in private mode (web only)
  static Future<bool> isPrivateMode() async {
    if (!kIsWeb) return false;
    return await PlatformPersistence.isPrivateMode();
  }

  /// Get simple storage status
  static Future<String> getStorageStatus() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Storage Status ===');
    buffer.writeln('Platform: ${kIsWeb ? "Web" : "Native"}');

    // Check private mode (web only)
    if (kIsWeb) {
      final isPrivate = await isPrivateMode();
      buffer.writeln(
        'Private Mode: ${isPrivate ? "YES (Data won't persist)" : "NO"}',
      );
    }

    // Check SharedPreferences (all platforms)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('__test', 'test');
      await prefs.remove('__test');
      buffer.writeln('SharedPreferences: AVAILABLE');
    } catch (e) {
      buffer.writeln('SharedPreferences: ERROR - $e');
    }

    // Check web storage (web only)
    if (kIsWeb) {
      final webStatus = await PlatformPersistence.getWebStorageStatus();
      buffer.writeln(webStatus);
    }

    // Check existing data
    try {
      final appStorage = AppStorageManager.instance;
      final hasData = await appStorage.hasStoredData();
      final info = await appStorage.getStorageInfo();
      buffer.writeln('Has Stored Data: $hasData');
      buffer.writeln('Trades Count: ${info['tradesCount'] ?? 0}');
      buffer.writeln('Has Config: ${info['hasConfig'] ?? false}');
    } catch (e) {
      buffer.writeln('App Storage: ERROR - $e');
    }

    // Check for backup data
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasBackup = prefs.getString('${_backupPrefix}data') != null;
      buffer.writeln('Has Backup: $hasBackup');
    } catch (e) {
      buffer.writeln('Backup Check: ERROR');
    }

    buffer.writeln('\n=== Solutions ===');
    if (kIsWeb) {
      final isPrivate = await isPrivateMode();
      if (isPrivate) {
        buffer.writeln('• Exit private/incognito mode');
      }
      buffer.writeln('• Enable cookies and site data in browser');
    }
    buffer.writeln('• Try refreshing the app');
    buffer.writeln('• Export data as backup regularly');

    return buffer.toString();
  }

  /// Clear all backup data
  static Future<void> clearBackups() async {
    debugPrint('$_debugPrefix Clearing backup data...');

    // Clear SharedPreferences backup
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_backupPrefix}data');
    } catch (e) {
      debugPrint('$_debugPrefix Failed to clear SharedPreferences backup: $e');
    }

    // Clear web storage backups (web only)
    if (kIsWeb) {
      await PlatformPersistence.clearWebBackups(_backupPrefix);
    }

    debugPrint('$_debugPrefix Backup data cleared');
  }
}
