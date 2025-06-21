import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../trade.dart';
import 'storage_interface.dart';
import 'web_storage_init.dart';
import '../../utils/error_handling.dart';
import '../../utils/date_time_utils.dart';

// Conditional import for path_provider
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'sqlite_web_stub.dart';

/// SQLite implementation for trade data storage
/// Works across Android, iOS, Linux, Windows (Web uses IndexedDB through sqflite_common_ffi_web)
class SqliteTradeStorage implements TradeStorage {
  static const String _databaseName = 'risk_management.db';
  static const int _databaseVersion = 1;
  static const String _tradesTable = 'trades';

  Database? _database;

  /// Get database instance, creating it if necessary
  Future<Database> get database async {
    _database ??= await _initializeDatabase();
    return _database!;
  }

  @override
  Future<void> initializeDatabase() async {
    // Ensure platform-specific storage is initialized
    await StorageInitializer.initialize();
    _database = await _initializeDatabase();
  }

  /// Initialize the database
  Future<Database> _initializeDatabase() async {
    return await ErrorHandler.handleStorageOperation(
      'initialize database',
      () async {
        String path;

        if (kIsWeb) {
          // For web, use a simple database name - sqflite_common_ffi_web handles the rest
          path = _databaseName;
          debugPrint('Web database path: $path');
        } else {
          // Get platform-specific path for native platforms
          path = await _getNativeDatabasePath();
          debugPrint('Native database path: $path');
        }

        final database = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );

        debugPrint(
          'Database opened successfully on ${StorageInitializer.getPlatformInfo()}',
        );
        return database;
      },
      context: 'SqliteTradeStorage',
    );
  }

  /// Get database path for native platforms (non-web)
  Future<String> _getNativeDatabasePath() async {
    try {
      // Use different strategies based on platform
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          try {
            final documentsDirectory = await getApplicationDocumentsDirectory();
            return join(documentsDirectory.path, _databaseName);
          } catch (e) {
            debugPrint('getApplicationDocumentsDirectory failed: $e');
            return join(await getDatabasesPath(), _databaseName);
          }

        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
          try {
            final supportDirectory = await getApplicationSupportDirectory();
            return join(supportDirectory.path, _databaseName);
          } catch (e) {
            debugPrint('getApplicationSupportDirectory failed: $e');
            return join(await getDatabasesPath(), _databaseName);
          }

        case TargetPlatform.fuchsia:
          return join(await getDatabasesPath(), _databaseName);
      }
    } catch (e) {
      // Final fallback
      debugPrint('All path methods failed, using database path: $e');
      return join(await getDatabasesPath(), _databaseName);
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tradesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result REAL NOT NULL,
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_trades_timestamp ON $_tradesTable(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_trades_result ON $_tradesTable(result)
    ''');

    debugPrint('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    // Handle future database migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE $_tradesTable ADD COLUMN new_column TEXT');
    }
  }

  @override
  Future<List<Trade>> getAllTrades() async {
    return await ErrorHandler.handleStorageOperation(
      'get all trades',
      () async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query(
          _tradesTable,
          orderBy: 'timestamp ASC',
        );

        return maps.map((map) => _tradeFromMap(map)).toList();
      },
      context: 'SqliteTradeStorage',
    );
  }

  @override
  Future<Trade> saveTrade(Trade trade) async {
    return await ErrorHandler.handleStorageOperation('save trade', () async {
      final db = await database;
      final timestamps = DateTimeUtils.createTimestamps();

      final id = await db.insert(_tradesTable, {
        'result': trade.result,
        'timestamp': DateTimeUtils.toIso8601(trade.timestamp),
        'created_at': timestamps['created_at'],
        'updated_at': timestamps['updated_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return trade.copyWith(id: id);
    }, context: 'SqliteTradeStorage');
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    return await ErrorHandler.handleStorageOperation('update trade', () async {
      final db = await database;
      final now = DateTimeUtils.getCurrentTimestamp();

      final count = await db.update(
        _tradesTable,
        {
          'result': trade.result,
          'timestamp': DateTimeUtils.toIso8601(trade.timestamp),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [trade.id],
      );

      if (count == 0) {
        throw StorageException('Trade with id ${trade.id} not found');
      }

      return trade;
    }, context: 'SqliteTradeStorage');
  }

  @override
  Future<void> deleteTrade(int id) async {
    return await ErrorHandler.handleStorageOperation('delete trade', () async {
      final db = await database;
      final count = await db.delete(
        _tradesTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw StorageException('Trade with id $id not found');
      }
    }, context: 'SqliteTradeStorage');
  }

  @override
  Future<Trade?> getTradeById(int id) async {
    return await ErrorHandler.handleStorageOperation(
      'get trade by id',
      () async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query(
          _tradesTable,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        if (maps.isEmpty) {
          return null;
        }

        return _tradeFromMap(maps.first);
      },
      context: 'SqliteTradeStorage',
    );
  }

  @override
  Future<void> clearAllTrades() async {
    return await ErrorHandler.handleStorageOperation(
      'clear all trades',
      () async {
        final db = await database;
        await db.delete(_tradesTable);
      },
      context: 'SqliteTradeStorage',
    );
  }

  @override
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end) async {
    return await ErrorHandler.handleStorageOperation(
      'get trades by date range',
      () async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query(
          _tradesTable,
          where: 'timestamp BETWEEN ? AND ?',
          whereArgs: [
            DateTimeUtils.toIso8601(start),
            DateTimeUtils.toIso8601(end),
          ],
          orderBy: 'timestamp ASC',
        );

        return maps.map((map) => _tradeFromMap(map)).toList();
      },
      context: 'SqliteTradeStorage',
    );
  }

  /// Get trade statistics directly from database
  Future<Map<String, dynamic>> getTradeStatistics() async {
    return await ErrorHandler.handleStorageOperation(
      'get trade statistics',
      () async {
        final db = await database;

        // Get basic counts and sums
        final List<Map<String, dynamic>> results = await db.rawQuery('''
          SELECT
            COUNT(*) as total_trades,
            SUM(result) as total_pnl,
            SUM(CASE WHEN result > 0 THEN 1 ELSE 0 END) as win_count,
            SUM(CASE WHEN result < 0 THEN 1 ELSE 0 END) as loss_count,
            AVG(CASE WHEN result > 0 THEN result ELSE NULL END) as avg_win,
            AVG(CASE WHEN result < 0 THEN result ELSE NULL END) as avg_loss,
            MIN(result) as worst_loss,
            MAX(result) as best_win
          FROM $_tradesTable
        ''');

        return results.first;
      },
      context: 'SqliteTradeStorage',
    );
  }

  /// Get trades count
  @override
  Future<int> getTradesCount() async {
    return await ErrorHandler.handleStorageOperation(
      'get trades count',
      () async {
        final db = await database;
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $_tradesTable',
        );
        return Sqflite.firstIntValue(result) ?? 0;
      },
      context: 'SqliteTradeStorage',
    );
  }

  /// Get recent trades
  @override
  Future<List<Trade>> getRecentTrades({int limit = 10}) async {
    return await ErrorHandler.handleStorageOperation(
      'get recent trades',
      () async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query(
          _tradesTable,
          orderBy: 'timestamp DESC',
          limit: limit,
        );

        return maps.map((map) => _tradeFromMap(map)).toList();
      },
      context: 'SqliteTradeStorage',
    );
  }

  /// Export trades to JSON format
  @override
  Future<List<Map<String, dynamic>>> exportTrades() async {
    return await ErrorHandler.handleStorageOperation('export trades', () async {
      final db = await database;
      return await db.query(_tradesTable, orderBy: 'timestamp ASC');
    }, context: 'SqliteTradeStorage');
  }

  /// Import trades from JSON format
  @override
  Future<void> importTrades(List<Map<String, dynamic>> tradesData) async {
    return await ErrorHandler.handleStorageOperation('import trades', () async {
      final db = await database;
      final batch = db.batch();

      for (final tradeData in tradesData) {
        final now = DateTimeUtils.getCurrentTimestamp();
        batch.insert(_tradesTable, {
          'result': tradeData['result'],
          'timestamp': tradeData['timestamp'],
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    }, context: 'SqliteTradeStorage');
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Convert database map to Trade object
  Trade _tradeFromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'] as int?,
      result: (map['result'] as num).toDouble(),
      timestamp: DateTimeUtils.fromIso8601(map['timestamp'] as String),
    );
  }
}
