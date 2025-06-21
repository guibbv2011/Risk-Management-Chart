import 'package:flutter/foundation.dart';
import 'storage_interface.dart';
import 'sdb_trade_storage.dart';

/// Simple factory class for creating storage implementations
class StorageFactory {
  /// Create a trade storage instance using IndexedDB/SQLite
  static TradeStorage createTradeStorage() {
    debugPrint('Creating IndexedDB/SQLite trade storage');
    return SdbTradeStorage();
  }
}

/// Custom exception for storage factory operations
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
