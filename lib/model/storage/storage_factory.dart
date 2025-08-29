import 'storage_interface.dart';
import 'sdb_trade_storage.dart';

class StorageFactory {
  static TradeStorage createTradeStorage() {
    return SdbTradeStorage();
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
