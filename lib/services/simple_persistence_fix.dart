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
    debugPrint('$_debugPrefix 🔍 Starting comprehensive data recovery scan...');

    int sourcesChecked = 0;
    int sourcesWithData = 0;

    // Try SharedPreferences first (works on all platforms)
    try {
      sourcesChecked++;
      debugPrint('$_debugPrefix Checking SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      // Check for backup data
      final backupData = prefs.getString('${_backupPrefix}data');
      if (backupData != null) {
        sourcesWithData++;
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        debugPrint('$_debugPrefix ✅ Full backup data recovered from SharedPreferences');
        debugPrint('$_debugPrefix   - Contains: ${data.keys.join(', ')}');
        if (data['trades'] != null) {
          debugPrint('$_debugPrefix   - Trades: ${(data['trades'] as List).length}');
        }
        return data;
      }

      // Try individual risk settings
      final riskData = prefs.getString('risk_settings');
      if (riskData != null) {
        sourcesWithData++;
        final riskSettings = jsonDecode(riskData) as Map<String, dynamic>;
        debugPrint('$_debugPrefix ✅ Risk settings recovered from SharedPreferences');
        debugPrint('$_debugPrefix   - Balance: \$${riskSettings['accountBalance'] ?? 'unknown'}');
        debugPrint('$_debugPrefix   - Max DD: \$${riskSettings['maxDrawdown'] ?? 'unknown'}');
        return {
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
          'riskSettings': riskSettings,
          'trades': <Map<String, dynamic>>[],
        };
      }

      debugPrint('$_debugPrefix ❌ No data found in SharedPreferences');
    } catch (e) {
      debugPrint('$_debugPrefix ❌ SharedPreferences recovery failed: $e');
    }

    // Try web storage recovery (only on web)
    if (kIsWeb) {
      sourcesChecked++;
      debugPrint('$_debugPrefix Checking web storage...');
      final webData = await PlatformPersistence.recoverFromWebStorage(
        backupPrefix: _backupPrefix,
      );
      if (webData != null) {
        sourcesWithData++;
        debugPrint('$_debugPrefix ✅ Data recovered from web storage');
        return webData;
      } else {
        debugPrint('$_debugPrefix ❌ No data found in web storage');
      }
    }

    debugPrint('$_debugPrefix 📊 Recovery summary: $sourcesWithData/$sourcesChecked sources had data');

    if (sourcesWithData == 0) {
      debugPrint('$_debugPrefix ❌ No recoverable data found in any backup location');
    }

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

  /// Check what data exists immediately on startup
  static Future<Map<String, dynamic>> checkStartupData() async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'native',
      'sources': <String, dynamic>{},
    };

    debugPrint('$_debugPrefix 🔍 Starting immediate storage check...');

    // Check SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList();
      final hasRiskSettings = keys.contains('risk_settings');
      final hasBackup = keys.contains('${_backupPrefix}data');

      result['sources']['sharedPreferences'] = {
        'available': true,
        'totalKeys': keys.length,
        'hasRiskSettings': hasRiskSettings,
        'hasBackup': hasBackup,
        'allKeys': keys,
      };

      if (hasRiskSettings) {
        final riskData = prefs.getString('risk_settings');
        if (riskData != null) {
          try {
            final settings = jsonDecode(riskData);
            result['sources']['sharedPreferences']['riskSettingsData'] = settings;
            debugPrint('$_debugPrefix ✅ Found risk settings in SharedPreferences');
          } catch (e) {
            debugPrint('$_debugPrefix ❌ Corrupted risk settings in SharedPreferences: $e');
          }
        }
      }

      if (hasBackup) {
        final backupData = prefs.getString('${_backupPrefix}data');
        if (backupData != null) {
          try {
            final backup = jsonDecode(backupData);
            result['sources']['sharedPreferences']['backupData'] = backup;
            debugPrint('$_debugPrefix ✅ Found backup data in SharedPreferences');
          } catch (e) {
            debugPrint('$_debugPrefix ❌ Corrupted backup data in SharedPreferences: $e');
          }
        }
      }
    } catch (e) {
      result['sources']['sharedPreferences'] = {'available': false, 'error': e.toString()};
      debugPrint('$_debugPrefix ❌ SharedPreferences check failed: $e');
    }

    // Check web storage if on web
    if (kIsWeb) {
      try {
        final webData = await PlatformPersistence.recoverFromWebStorage(backupPrefix: _backupPrefix);
        result['sources']['webStorage'] = {
          'available': true,
          'hasData': webData != null,
          'data': webData,
        };
        if (webData != null) {
          debugPrint('$_debugPrefix ✅ Found data in web storage');
        } else {
          debugPrint('$_debugPrefix ❌ No data in web storage');
        }
      } catch (e) {
        result['sources']['webStorage'] = {'available': false, 'error': e.toString()};
        debugPrint('$_debugPrefix ❌ Web storage check failed: $e');
      }
    }

    // Summary
    final hasAnyData = result['sources'].values.any((source) =>
      source is Map && (source['hasRiskSettings'] == true || source['hasBackup'] == true || source['hasData'] == true)
    );

    result['hasAnyData'] = hasAnyData;
    debugPrint('$_debugPrefix 📊 Startup check complete - Has any data: $hasAnyData');

    return result;
  }

  /// Get simple storage status
  static Future<String> getStorageStatus() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Storage Status ===');
    buffer.writeln('Platform: ${kIsWeb ? "Web" : "Native"}');
    buffer.writeln('Time: ${DateTime.now()}');

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

      // Check what's actually stored
      final keys = prefs.getKeys();
      buffer.writeln('  Stored keys: ${keys.length} (${keys.take(5).join(', ')}${keys.length > 5 ? '...' : ''})');
    } catch (e) {
      buffer.writeln('SharedPreferences: ERROR - $e');
    }

    // Check web storage (web only)
    if (kIsWeb) {
      final webStatus = await PlatformPersistence.getWebStorageStatus();
      buffer.writeln(webStatus);
    }

    // Check existing data with detailed breakdown
    try {
      final appStorage = AppStorageManager.instance;
      final hasData = await appStorage.hasStoredData();
      final info = await appStorage.getStorageInfo();
      buffer.writeln('\n=== App Data Status ===');
      buffer.writeln('Has Stored Data: $hasData');
      buffer.writeln('Trades Count: ${info['tradesCount'] ?? 0}');
      buffer.writeln('Has Config: ${info['hasConfig'] ?? false}');
      buffer.writeln('App Version: ${info['appVersion'] ?? 'Not set'}');

      if (info['configKeys'] != null) {
        final configKeys = info['configKeys'] as List;
        buffer.writeln('Config Keys: ${configKeys.length} (${configKeys.join(', ')})');
      }

      if (info.containsKey('error')) {
        buffer.writeln('Storage Error: ${info['error']}');
      }
    } catch (e) {
      buffer.writeln('App Storage: ERROR - $e');
    }

    // Check for backup data with details
    buffer.writeln('\n=== Backup Data ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasMainBackup = prefs.getString('${_backupPrefix}data') != null;
      final hasRiskSettings = prefs.getString('risk_settings') != null;
      buffer.writeln('Main Backup: ${hasMainBackup ? 'FOUND' : 'NOT FOUND'}');
      buffer.writeln('Risk Settings: ${hasRiskSettings ? 'FOUND' : 'NOT FOUND'}');

      if (kIsWeb) {
        final hasWebBackup = await PlatformPersistence.recoverFromWebStorage(backupPrefix: _backupPrefix) != null;
        buffer.writeln('Web Backup: ${hasWebBackup ? 'FOUND' : 'NOT FOUND'}');
      }
    } catch (e) {
      buffer.writeln('Backup Check: ERROR - $e');
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
    buffer.writeln('• Use "Try Recovery" to restore backup data');
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
