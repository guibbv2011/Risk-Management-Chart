import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb.dart' as idb;
import 'package:idb_shim/idb_browser.dart' as idb_browser;
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../trade.dart';
import 'storage_interface.dart';
import '../../utils/error_handling.dart';
import '../../utils/date_time_utils.dart';

/// IndexedDB-based trade storage implementation
/// Uses IndexedDB on web and SQLite on native platforms through idb_sqflite
class SdbTradeStorage implements TradeStorage {
  static const String _databaseName = 'risk_management_idb';
  static const int _databaseVersion = 1;
  static const String _storeName = 'trades';

  idb.Database? _database;
  late idb.IdbFactory _factory;
  bool _isInitialized = false;

  /// Get database instance, creating it if necessary
  Future<idb.Database> get database async {
    if (!_isInitialized) {
      await initializeDatabase();
    }
    return _database!;
  }

  @override
  Future<void> initializeDatabase() async {
    if (_isInitialized) return;

    try {
      // Initialize the appropriate factory based on platform
      await _initializeFactory();

      // Get database path
      final path = await _getDatabasePath();

      // Open database with schema
      _database = await _factory.open(
        path,
        version: _databaseVersion,
        onUpgradeNeeded: _onUpgradeNeeded,
      );

      _isInitialized = true;
      debugPrint(
        'IndexedDB database initialized successfully on ${_getPlatformInfo()}',
      );
    } catch (e) {
      ErrorHandler.logError(
        'SdbTradeStorage',
        e,
        additionalInfo: 'Database initialization',
      );
      throw StorageException(
        'Failed to initialize IndexedDB database: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Initialize the appropriate IDB factory for the current platform
  Future<void> _initializeFactory() async {
    if (kIsWeb) {
      // Use web factory (IndexedDB)
      _factory = idb_browser.idbFactoryWeb;
      debugPrint('Using IndexedDB web factory');
    } else {
      // Initialize sqflite factory for native platforms
      if (Platform.isWindows || Platform.isLinux) {
        sqflite_ffi.sqfliteFfiInit();
        _factory = getIdbFactorySqflite(sqflite_ffi.databaseFactoryFfi);
      } else {
        // Use default sqflite factory for mobile
        _factory = getIdbFactorySqflite(sqflite.databaseFactory);
      }
      debugPrint('Using IndexedDB sqflite factory (SQLite)');
    }
  }

  /// Get the appropriate database path for the current platform
  Future<String> _getDatabasePath() async {
    if (kIsWeb) {
      // On web, just return the database name
      return _databaseName;
    }

    try {
      String directory;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          final documentsDir = await getApplicationDocumentsDirectory();
          directory = documentsDir.path;
          break;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
          final supportDir = await getApplicationSupportDirectory();
          directory = supportDir.path;
          break;
        default:
          final documentsDir = await getApplicationDocumentsDirectory();
          directory = documentsDir.path;
      }

      return join(directory, '$_databaseName.db');
    } catch (e) {
      debugPrint('Error getting database path: $e');
      // Fallback to current directory
      return '$_databaseName.db';
    }
  }

  /// Handle database version changes and schema creation
  void _onUpgradeNeeded(idb.VersionChangeEvent event) {
    final db = event.database;
    final oldVersion = event.oldVersion;

    if (oldVersion < 1) {
      // Create the trades object store
      final store = db.createObjectStore(
        _storeName,
        keyPath: 'id',
        autoIncrement: true,
      );

      // Create indexes for efficient querying
      store.createIndex('timestamp', 'timestamp', unique: false);
      store.createIndex('result', 'result', unique: false);

      debugPrint('IndexedDB stores and indexes created successfully');
    }
  }

  @override
  Future<List<Trade>> getAllTrades() async {
    return await ErrorHandler.handleStorageOperation(
      'get all trades',
      () async {
        final db = await database;
        final transaction = db.transaction(_storeName, 'readonly');
        final store = transaction.objectStore(_storeName);

        final List<Trade> trades = [];
        final cursorStream = store.openCursor();

        await for (final cursor in cursorStream) {
          trades.add(_tradeFromMap(cursor.value as Map<String, dynamic>));
          cursor.next();
        }

        await transaction.completed;

        // Sort by timestamp
        trades.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return trades;
      },
      context: 'SdbTradeStorage',
    );
  }

  @override
  Future<Trade> saveTrade(Trade trade) async {
    return await ErrorHandler.handleStorageOperation('save trade', () async {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);
      final timestamps = DateTimeUtils.createTimestamps();

      final tradeData = {
        'result': trade.result,
        'timestamp': DateTimeUtils.toIso8601(trade.timestamp),
        'created_at': timestamps['created_at'],
        'updated_at': timestamps['updated_at'],
      };

      final key = await store.add(tradeData);
      await transaction.completed;

      return trade.copyWith(id: key as int);
    }, context: 'SdbTradeStorage');
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    return await ErrorHandler.handleStorageOperation('update trade', () async {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);

      // Check if record exists
      final existing = await store.getObject(trade.id!);
      if (existing == null) {
        throw StorageException('Trade with id ${trade.id} not found');
      }

      final timestamps = DateTimeUtils.updateTimestamp(
        existing as Map<String, dynamic>,
      );
      final updatedData = {
        'id': trade.id,
        'result': trade.result,
        'timestamp': DateTimeUtils.toIso8601(trade.timestamp),
        'created_at': timestamps['created_at'],
        'updated_at': timestamps['updated_at'],
      };

      await store.put(updatedData);
      await transaction.completed;

      return trade;
    }, context: 'SdbTradeStorage');
  }

  @override
  Future<void> deleteTrade(int id) async {
    return await ErrorHandler.handleStorageOperation('delete trade', () async {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);

      final existing = await store.getObject(id);
      if (existing == null) {
        throw StorageException('Trade with id $id not found');
      }

      await store.delete(id);
      await transaction.completed;
    }, context: 'SdbTradeStorage');
  }

  @override
  Future<Trade?> getTradeById(int id) async {
    return await ErrorHandler.handleStorageOperation(
      'get trade by id',
      () async {
        final db = await database;
        final transaction = db.transaction(_storeName, 'readonly');
        final store = transaction.objectStore(_storeName);

        final data = await store.getObject(id);
        await transaction.completed;

        if (data == null) {
          return null;
        }

        return _tradeFromMap(data as Map<String, dynamic>);
      },
      context: 'SdbTradeStorage',
    );
  }

  @override
  Future<void> clearAllTrades() async {
    return await ErrorHandler.handleStorageOperation(
      'clear all trades',
      () async {
        final db = await database;
        final transaction = db.transaction(_storeName, 'readwrite');
        final store = transaction.objectStore(_storeName);

        await store.clear();
        await transaction.completed;
      },
      context: 'SdbTradeStorage',
    );
  }

  @override
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    return await ErrorHandler.handleStorageOperation(
      'get trades by date range',
      () async {
        final db = await database;
        final transaction = db.transaction(_storeName, 'readonly');
        final store = transaction.objectStore(_storeName);
        final index = store.index('timestamp');

        final range = idb.KeyRange.bound(
          DateTimeUtils.toIso8601(start),
          DateTimeUtils.toIso8601(end),
        );

        final List<Trade> trades = [];
        final cursorStream = index.openCursor(range: range);

        await for (final cursor in cursorStream) {
          trades.add(_tradeFromMap(cursor.value as Map<String, dynamic>));
          cursor.next();
        }

        await transaction.completed;

        // Sort by timestamp
        trades.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return trades;
      },
      context: 'SdbTradeStorage',
    );
  }

  @override
  Future<int> getTradesCount() async {
    try {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);

      final count = await store.count();
      await transaction.completed;

      return count;
    } catch (e) {
      throw StorageException('Failed to get trades count: ${e.toString()}');
    }
  }

  @override
  Future<List<Trade>> getRecentTrades({int limit = 10}) async {
    try {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);
      final index = store.index('timestamp');

      final List<Trade> trades = [];
      final cursorStream = index.openCursor(direction: 'prev');

      int count = 0;
      await for (final cursor in cursorStream) {
        if (count < limit) {
          trades.add(_tradeFromMap(cursor.value as Map<String, dynamic>));
          count++;
        }
        if (count >= limit) break;
        cursor.next();
      }

      await transaction.completed;

      return trades;
    } catch (e) {
      throw StorageException('Failed to get recent trades: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportTrades() async {
    try {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);

      final List<Map<String, dynamic>> trades = [];
      final cursorStream = store.openCursor();

      await for (final cursor in cursorStream) {
        trades.add(Map<String, dynamic>.from(cursor.value as Map));
        cursor.next();
      }

      await transaction.completed;

      return trades;
    } catch (e) {
      throw StorageException('Failed to export trades: ${e.toString()}');
    }
  }

  @override
  Future<void> importTrades(List<Map<String, dynamic>> tradesData) async {
    try {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);

      for (final tradeData in tradesData) {
        final now = DateTime.now().toIso8601String();
        final data = {
          'result': tradeData['result'],
          'timestamp': tradeData['timestamp'],
          'created_at': now,
          'updated_at': now,
        };

        await store.add(data);
      }

      await transaction.completed;
    } catch (e) {
      throw StorageException('Failed to import trades: ${e.toString()}');
    }
  }

  /// Get trade statistics using IndexedDB queries
  Future<Map<String, dynamic>> getTradeStatistics() async {
    try {
      final db = await database;
      final transaction = db.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);

      final List<double> results = [];
      final cursorStream = store.openCursor();

      await for (final cursor in cursorStream) {
        final data = cursor.value as Map<String, dynamic>;
        final result = (data['result'] as num).toDouble();
        results.add(result);
        cursor.next();
      }

      await transaction.completed;

      if (results.isEmpty) {
        return {
          'total_trades': 0,
          'total_pnl': 0.0,
          'win_count': 0,
          'loss_count': 0,
          'avg_win': 0.0,
          'avg_loss': 0.0,
          'worst_loss': 0.0,
          'best_win': 0.0,
        };
      }

      final wins = results.where((r) => r > 0).toList();
      final losses = results.where((r) => r < 0).toList();

      return {
        'total_trades': results.length,
        'total_pnl': results.fold(0.0, (sum, r) => sum + r),
        'win_count': wins.length,
        'loss_count': losses.length,
        'avg_win': wins.isEmpty
            ? 0.0
            : wins.fold(0.0, (sum, r) => sum + r) / wins.length,
        'avg_loss': losses.isEmpty
            ? 0.0
            : losses.fold(0.0, (sum, r) => sum + r) / losses.length,
        'worst_loss': losses.isEmpty
            ? 0.0
            : losses.reduce((a, b) => a < b ? a : b),
        'best_win': wins.isEmpty ? 0.0 : wins.reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      throw StorageException('Failed to get trade statistics: ${e.toString()}');
    }
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }

  /// Convert IndexedDB map to Trade object
  Trade _tradeFromMap(Map<String, dynamic> data) {
    return Trade(
      id: data['id'] as int?,
      result: (data['result'] as num).toDouble(),
      timestamp: DateTimeUtils.fromIso8601(data['timestamp'] as String),
    );
  }

  /// Get platform information for debugging
  String _getPlatformInfo() {
    if (kIsWeb) {
      return 'Web (IndexedDB)';
    } else {
      return '${Platform.operatingSystem} (SQLite via IndexedDB API)';
    }
  }
}
