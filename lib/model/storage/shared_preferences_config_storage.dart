import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../risk_management.dart';
import 'storage_interface.dart';

/// SharedPreferences implementation for configuration storage
/// Works across Android, iOS, Linux, Windows, and Web
class SharedPreferencesConfigStorage implements ConfigStorage {
  static const String _riskSettingsKey = 'risk_settings';
  static const String _appVersionKey = 'app_version';
  static const String _currentVersion = '1.0.0';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences instance
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveRiskSettings(RiskManagement riskSettings) async {
    await _ensureInitialized();

    try {
      final jsonString = jsonEncode(riskSettings.toJson());
      await _prefs!.setString(_riskSettingsKey, jsonString);
      await _prefs!.setString(_appVersionKey, _currentVersion);
    } catch (e) {
      throw StorageException('Failed to save risk settings: ${e.toString()}');
    }
  }

  @override
  Future<RiskManagement?> loadRiskSettings() async {
    await _ensureInitialized();

    try {
      final jsonString = _prefs!.getString(_riskSettingsKey);
      if (jsonString == null) {
        return null;
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return RiskManagement.fromJson(jsonMap);
    } catch (e) {
      // If there's an error loading settings, return null and let the app use defaults
      // Log the error but don't throw to prevent app crashes
      debugPrint('Warning: Failed to load risk settings: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<void> clearRiskSettings() async {
    await _ensureInitialized();

    try {
      await _prefs!.remove(_riskSettingsKey);
      await _prefs!.remove(_appVersionKey);
    } catch (e) {
      throw StorageException('Failed to clear risk settings: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasRiskSettings() async {
    await _ensureInitialized();
    return _prefs!.containsKey(_riskSettingsKey);
  }

  /// Get stored app version for migration purposes
  Future<String?> getStoredAppVersion() async {
    await _ensureInitialized();
    return _prefs!.getString(_appVersionKey);
  }

  /// Check if migration is needed
  Future<bool> needsMigration() async {
    final storedVersion = await getStoredAppVersion();
    return storedVersion != null && storedVersion != _currentVersion;
  }

  /// Perform data migration if needed
  Future<void> migrateIfNeeded() async {
    if (await needsMigration()) {
      // Implement migration logic here if needed in future versions
      await _prefs!.setString(_appVersionKey, _currentVersion);
    }
  }

  /// Get all stored keys (useful for debugging)
  Future<Set<String>> getAllKeys() async {
    await _ensureInitialized();
    return _prefs!.getKeys();
  }

  /// Clear all app data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _prefs!.clear();
  }
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
