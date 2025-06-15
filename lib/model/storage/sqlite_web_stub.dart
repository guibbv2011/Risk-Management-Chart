// Stub file for path_provider on web platform
// This file provides stub implementations for web builds where path_provider is not available

import 'dart:async';

/// Stub class representing a directory for web platform
class Directory {
  final String path;
  Directory(this.path);
}

/// Stub implementation for getApplicationDocumentsDirectory on web
/// This function should not be called on web platform
Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError(
    'getApplicationDocumentsDirectory is not supported on web platform',
  );
}

/// Stub implementation for getApplicationSupportDirectory on web
/// This function should not be called on web platform
Future<Directory> getApplicationSupportDirectory() async {
  throw UnsupportedError(
    'getApplicationSupportDirectory is not supported on web platform',
  );
}

/// Stub implementation for getTemporaryDirectory on web
/// This function should not be called on web platform
Future<Directory> getTemporaryDirectory() async {
  throw UnsupportedError(
    'getTemporaryDirectory is not supported on web platform',
  );
}

/// Stub implementation for getExternalStorageDirectory on web
/// This function should not be called on web platform
Future<Directory?> getExternalStorageDirectory() async {
  throw UnsupportedError(
    'getExternalStorageDirectory is not supported on web platform',
  );
}
