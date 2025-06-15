import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../model/risk_management.dart';

/// Web-specific persistence operations
class PlatformPersistence {
  static const String _debugPrefix = '[WebPersistence]';

  /// Save data to web storage (LocalStorage and SessionStorage)
  static Future<int> saveToWebStorage({
    required String backupPrefix,
    required String jsonString,
    required RiskManagement riskSettings,
  }) async {
    int successCount = 0;

    // Save to LocalStorage
    try {
      html.window.localStorage['${backupPrefix}data'] = jsonString;
      html.window.localStorage['risk_settings'] = jsonEncode(
        riskSettings.toJson(),
      );
      successCount++;
      debugPrint('$_debugPrefix ✓ LocalStorage backup saved');
    } catch (e) {
      debugPrint('$_debugPrefix ✗ LocalStorage failed: $e');
    }

    // Save to SessionStorage
    try {
      html.window.sessionStorage['${backupPrefix}data'] = jsonString;
      successCount++;
      debugPrint('$_debugPrefix ✓ SessionStorage backup saved');
    } catch (e) {
      debugPrint('$_debugPrefix ✗ SessionStorage failed: $e');
    }

    return successCount;
  }

  /// Recover data from web storage
  static Future<Map<String, dynamic>?> recoverFromWebStorage({
    required String backupPrefix,
  }) async {
    // Try LocalStorage
    try {
      final backupData = html.window.localStorage['${backupPrefix}data'];
      if (backupData != null) {
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        debugPrint('$_debugPrefix ✓ Data recovered from LocalStorage');
        return data;
      }

      // Try individual risk settings
      final riskData = html.window.localStorage['risk_settings'];
      if (riskData != null) {
        final riskSettings = jsonDecode(riskData) as Map<String, dynamic>;
        debugPrint('$_debugPrefix ✓ Risk settings recovered from LocalStorage');
        return {
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
          'riskSettings': riskSettings,
          'trades': <Map<String, dynamic>>[],
        };
      }
    } catch (e) {
      debugPrint('$_debugPrefix LocalStorage recovery failed: $e');
    }

    // Try SessionStorage
    try {
      final backupData = html.window.sessionStorage['${backupPrefix}data'];
      if (backupData != null) {
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        debugPrint('$_debugPrefix ✓ Data recovered from SessionStorage');
        return data;
      }
    } catch (e) {
      debugPrint('$_debugPrefix SessionStorage recovery failed: $e');
    }

    return null;
  }

  /// Check if browser is in private mode
  static Future<bool> isPrivateMode() async {
    try {
      html.window.localStorage['__test'] = 'test';
      html.window.localStorage.remove('__test');
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Get web storage status
  static Future<String> getWebStorageStatus() async {
    final buffer = StringBuffer();

    // Check LocalStorage
    try {
      html.window.localStorage['__test'] = 'test';
      html.window.localStorage.remove('__test');
      buffer.writeln('LocalStorage: AVAILABLE');
    } catch (e) {
      buffer.writeln('LocalStorage: BLOCKED');
    }

    // Check SessionStorage
    try {
      html.window.sessionStorage['__test'] = 'test';
      html.window.sessionStorage.remove('__test');
      buffer.writeln('SessionStorage: AVAILABLE');
    } catch (e) {
      buffer.writeln('SessionStorage: BLOCKED');
    }

    return buffer.toString();
  }

  /// Clear web storage backups
  static Future<void> clearWebBackups(String backupPrefix) async {
    try {
      html.window.localStorage.remove('${backupPrefix}data');
    } catch (e) {
      debugPrint('$_debugPrefix Failed to clear LocalStorage backup: $e');
    }

    try {
      html.window.sessionStorage.remove('${backupPrefix}data');
    } catch (e) {
      debugPrint('$_debugPrefix Failed to clear SessionStorage backup: $e');
    }
  }
}
