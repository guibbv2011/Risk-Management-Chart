import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/storage/app_storage.dart';
import '../model/risk_management.dart';
import '../model/trade.dart';

import 'simple_persistence_web.dart'
    if (dart.library.io) 'simple_persistence_native.dart';

class SimplePersistenceFix {
  static const String _backupPrefix = 'backup_';

  static Future<bool> forceSaveData({
    required RiskManagement riskSettings,
    required List<Trade> trades,
  }) async {
    final backupData = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'riskSettings': riskSettings.toJson(),
      'trades': trades.map((t) => t.toJson()).toList(),
    };

    final jsonString = jsonEncode(backupData);
    int successCount = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_backupPrefix}data', jsonString);
      await prefs.setString('risk_settings', jsonEncode(riskSettings.toJson()));
      successCount++;
    } catch (e) {
      rethrow;
    }

    if (kIsWeb) {
      final webSuccessCount = await PlatformPersistence.saveToWebStorage(
        backupPrefix: _backupPrefix,
        jsonString: jsonString,
        riskSettings: riskSettings,
      );
      successCount += webSuccessCount;
    }

    final success = successCount > 0;
    return success;
  }

  static Future<Map<String, dynamic>?> tryRecoverData() async {
    int sourcesChecked = 0;
    int sourcesWithData = 0;

    try {
      sourcesChecked++;
      final prefs = await SharedPreferences.getInstance();

      final backupData = prefs.getString('${_backupPrefix}data');
      if (backupData != null) {
        sourcesWithData++;
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        return data;
      }

      final riskData = prefs.getString('risk_settings');
      if (riskData != null) {
        sourcesWithData++;
        final riskSettings = jsonDecode(riskData) as Map<String, dynamic>;
        return {
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
          'riskSettings': riskSettings,
          'trades': <Map<String, dynamic>>[],
        };
      }

    } catch (e) {
      rethrow;
    }

    if (kIsWeb) {
      sourcesChecked++;
      final webData = await PlatformPersistence.recoverFromWebStorage(
        backupPrefix: _backupPrefix,
      );
      if (webData != null) {
        sourcesWithData++;
        return webData;
      } else {
      }
    }

    return null;
  }

  static Future<bool> restoreData(Map<String, dynamic> data) async {

    try {
      final appStorage = AppStorageManager.instance;

      if (data['riskSettings'] != null) {
        final riskSettings = RiskManagement.fromJson(
          data['riskSettings'] as Map<String, dynamic>,
        );
        await appStorage.config.saveRiskSettings(riskSettings);
      }

      if (data['trades'] != null) {
        final tradesData = (data['trades'] as List)
            .cast<Map<String, dynamic>>();
        if (tradesData.isNotEmpty) {
          await appStorage.trades.clearAllTrades();
          await appStorage.trades.importTrades(tradesData);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isPrivateMode() async {
    if (!kIsWeb) return false;
    return await PlatformPersistence.isPrivateMode();
  }

  static Future<Map<String, dynamic>> checkStartupData() async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'native',
      'sources': <String, dynamic>{},
    };

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
          } catch (e) {
            rethrow;
          }
        }
      }

      if (hasBackup) {
        final backupData = prefs.getString('${_backupPrefix}data');
        if (backupData != null) {
          try {
            final backup = jsonDecode(backupData);
            result['sources']['sharedPreferences']['backupData'] = backup;
          } catch (e) {
            rethrow;
          }
        }
      }
    } catch (e) {
      result['sources']['sharedPreferences'] = {'available': false, 'error': e.toString()};
    }

    if (kIsWeb) {
      try {
        final webData = await PlatformPersistence.recoverFromWebStorage(backupPrefix: _backupPrefix);
        result['sources']['webStorage'] = {
          'available': true,
          'hasData': webData != null,
          'data': webData,
        };
      } catch (e) {
        result['sources']['webStorage'] = {'available': false, 'error': e.toString()};
      }
    }

    final hasAnyData = result['sources'].values.any((source) =>
      source is Map && (source['hasRiskSettings'] == true || source['hasBackup'] == true || source['hasData'] == true)
    );

    result['hasAnyData'] = hasAnyData;

    return result;
  }

  static Future<String> getStorageStatus() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Storage Status ===');
    buffer.writeln('Platform: ${kIsWeb ? "Web" : "Native"}');
    buffer.writeln('Time: ${DateTime.now()}');

    if (kIsWeb) {
      final isPrivate = await isPrivateMode();
      buffer.writeln(
        'Private Mode: ${isPrivate ? "YES (Data won't persist)" : "NO"}',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('__test', 'test');
      await prefs.remove('__test');
      buffer.writeln('SharedPreferences: AVAILABLE');

      final keys = prefs.getKeys();
      buffer.writeln('  Stored keys: ${keys.length} (${keys.take(5).join(', ')}${keys.length > 5 ? '...' : ''})');
    } catch (e) {
      buffer.writeln('SharedPreferences: ERROR - $e');
    }

    if (kIsWeb) {
      final webStatus = await PlatformPersistence.getWebStorageStatus();
      buffer.writeln(webStatus);
    }

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

  static Future<void> clearBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_backupPrefix}data');
    } catch (e) {
      rethrow;
    }

    if (kIsWeb) {
      await PlatformPersistence.clearWebBackups(_backupPrefix);
    }

  }
}
