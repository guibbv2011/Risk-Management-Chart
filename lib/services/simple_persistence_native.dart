import 'dart:async';
import '../model/risk_management.dart';

class PlatformPersistence {

  static Future<int> saveToWebStorage({
    required String backupPrefix,
    required String jsonString,
    required RiskManagement riskSettings,
  }) async {
    return 0;
  }

  static Future<Map<String, dynamic>?> recoverFromWebStorage({
    required String backupPrefix,
  }) async {
    return null;
  }

  static Future<bool> isPrivateMode() async {
    return false;
  }

  static Future<String> getWebStorageStatus() async {
    return 'Web storage: NOT AVAILABLE (Native platform)';
  }

  static Future<void> clearWebBackups(String backupPrefix) async {
  }
}
