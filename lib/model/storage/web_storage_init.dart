import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Initialize database factory for different platforms
class StorageInitializer {
  static bool _isInitialized = false;

  /// Initialize storage for the current platform
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // Initialize for web platform using IndexedDB
        databaseFactory = databaseFactoryFfiWeb;
        debugPrint('Initialized web storage using IndexedDB');
      } else {
        // Check platform using defaultTargetPlatform instead of dart:io
        switch (defaultTargetPlatform) {
          case TargetPlatform.windows:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
            // Initialize FFI for desktop platforms
            sqfliteFfiInit();
            databaseFactory = databaseFactoryFfi;
            debugPrint('Initialized desktop storage using SQLite FFI');
            break;
          case TargetPlatform.android:
          case TargetPlatform.iOS:
            // Android and iOS use the default SQLite implementation
            // No special initialization needed
            debugPrint('Using native SQLite for mobile platform');
            break;
          case TargetPlatform.fuchsia:
            // Fallback for Fuchsia
            debugPrint('Using default SQLite for Fuchsia');
            break;
        }
      }

      _isInitialized = true;
      debugPrint('Storage initialization completed successfully');
    } catch (e) {
      debugPrint('Storage initialization failed: ${e.toString()}');
      throw Exception('Failed to initialize storage: ${e.toString()}');
    }
  }

  /// Check if storage is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (mainly for testing)
  static void reset() {
    _isInitialized = false;
  }

  /// Get current platform info for debugging
  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web (IndexedDB)';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'Android (Native SQLite)';
        case TargetPlatform.iOS:
          return 'iOS (Native SQLite)';
        case TargetPlatform.windows:
          return 'Windows (SQLite FFI)';
        case TargetPlatform.linux:
          return 'Linux (SQLite FFI)';
        case TargetPlatform.macOS:
          return 'macOS (SQLite FFI)';
        case TargetPlatform.fuchsia:
          return 'Fuchsia (Default SQLite)';
      }
    }
  }
}
