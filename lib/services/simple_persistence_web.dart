import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../model/risk_management.dart';

class PlatformPersistence {
  static const String _debugPrefix = '[WebPersistence]';

  static Future<int> saveToWebStorage({
    required String backupPrefix,
    required String jsonString,
    required RiskManagement riskSettings,
  }) async {
    int successCount = 0;

    try {
      html.window.localStorage['${backupPrefix}data'] = jsonString;
      html.window.localStorage['risk_settings'] = jsonEncode(
        riskSettings.toJson(),
      );
      successCount++;
    } catch (e) {
    }

    try {
      html.window.sessionStorage['${backupPrefix}data'] = jsonString;
      successCount++;
    } catch (e) {
    }

    return successCount;
  }

  static Future<Map<String, dynamic>?> recoverFromWebStorage({
    required String backupPrefix,
  }) async {
    try {
      final backupData = html.window.localStorage['${backupPrefix}data'];
      if (backupData != null) {
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        return data;
      }

      final riskData = html.window.localStorage['risk_settings'];
      if (riskData != null) {
        final riskSettings = jsonDecode(riskData) as Map<String, dynamic>;
        return {
          'version': '1.0.0',
          'timestamp': DateTime.now().toIso8601String(),
          'riskSettings': riskSettings,
          'trades': <Map<String, dynamic>>[],
        };
      }
    } catch (e) {
    }

    try {
      final backupData = html.window.sessionStorage['${backupPrefix}data'];
      if (backupData != null) {
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        return data;
      }
    } catch (e) {
    }

    return null;
  }

  static Future<bool> isPrivateMode() async {
    try {
      html.window.localStorage['__test'] = 'test';
      html.window.localStorage.remove('__test');
      return false;
    } catch (e) {
      return true;
    }
  }

  static Future<String> getWebStorageStatus() async {
    final buffer = StringBuffer();

    try {
      html.window.localStorage['__test'] = 'test';
      html.window.localStorage.remove('__test');
      buffer.writeln('LocalStorage: AVAILABLE');
    } catch (e) {
      buffer.writeln('LocalStorage: BLOCKED');
    }

    try {
      html.window.sessionStorage['__test'] = 'test';
      html.window.sessionStorage.remove('__test');
      buffer.writeln('SessionStorage: AVAILABLE');
    } catch (e) {
      buffer.writeln('SessionStorage: BLOCKED');
    }

    return buffer.toString();
  }

  static Future<void> clearWebBackups(String backupPrefix) async {
    try {
      html.window.localStorage.remove('${backupPrefix}data');
    } catch (e) {
    }

    try {
      html.window.sessionStorage.remove('${backupPrefix}data');
    } catch (e) {
    }
  }
}
