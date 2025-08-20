import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class StorageInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.windows:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
            sqfliteFfiInit();
            databaseFactory = databaseFactoryFfi;
            break;
          case TargetPlatform.android:
          case TargetPlatform.iOS:
            break;
          case TargetPlatform.fuchsia:
            break;
        }
      }

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize storage: ${e.toString()}');
    }
  }

  static bool get isInitialized => _isInitialized;

  static void reset() {
    _isInitialized = false;
  }

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
