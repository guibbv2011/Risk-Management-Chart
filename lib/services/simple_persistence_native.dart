import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/risk_management.dart';

/// Native-specific persistence operations (stub for non-web platforms)
class PlatformPersistence {
  static const String _debugPrefix = '[NativePersistence]';

  /// Save data to native storage (only SharedPreferences available)
  static Future<int> saveToWebStorage({
    required String backupPrefix,
    required String jsonString,
    required RiskManagement riskSettings,
  }) async {
    // On native platforms, we don't have web storage
    // This is handled by SharedPreferences in the main persistence fix
    debugPrint('$_debugPrefix Web storage not available on native platform');
    return 0;
  }

  /// Recover data from native storage
  static Future<Map<String, dynamic>?> recoverFromWebStorage({
    required String backupPrefix,
  }) async {
    // On native platforms, recovery is handled by SharedPreferences
    debugPrint(
      '$_debugPrefix Web storage recovery not available on native platform',
    );
    return null;
  }

  /// Check if in private mode (not applicable for native)
  static Future<bool> isPrivateMode() async {
    return false; // Native apps don't have private mode
  }

  /// Get native storage status
  static Future<String> getWebStorageStatus() async {
    return 'Web storage: NOT AVAILABLE (Native platform)';
  }

  /// Clear web storage backups (no-op on native)
  static Future<void> clearWebBackups(String backupPrefix) async {
    debugPrint(
      '$_debugPrefix Web storage cleanup not needed on native platform',
    );
  }
}
