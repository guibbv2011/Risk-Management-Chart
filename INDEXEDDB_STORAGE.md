# IndexedDB Storage Implementation Guide

This document explains the cross-platform storage implementation using `idb_sqflite` package that provides IndexedDB support on web and SQLite on native platforms.

## Overview

The Risk Management Flutter app uses a unified storage API that works seamlessly across all platforms:
- **Web**: Uses IndexedDB for persistent storage
- **Mobile/Desktop**: Uses SQLite through the same IndexedDB API interface

## Architecture

### Automatic Storage Selection

The implementation automatically selects the appropriate storage backend based on the platform:

```dart
// Factory automatically creates the right storage implementation
final storage = StorageFactory.createTradeStorage();
```

### Single Unified Implementation

- Uses IndexedDB on web browsers
- Uses SQLite on native platforms (mobile/desktop)
- Same API across all platforms
- Automatic platform detection
- No configuration needed
</text>

<old_text line=32>
## Key Components

### 1. SdbTradeStorage Class

Located at: `lib/model/storage/sdb_trade_storage.dart`

Main features:
- Implements `TradeStorage` interface
- Automatic platform detection
- Cross-platform database operations
- Efficient indexing and querying

### 2. Storage Factory

Located at: `lib/model/storage/storage_factory.dart`

Features:
- Storage type management
- Data migration between storage types
- Performance testing utilities
- Platform compatibility checks

### 3. Storage Demo Page

Located at: `lib/view/storage_demo_page.dart`

Development tool for:
- Testing different storage implementations
- Performance comparison
- Data migration testing
- Debugging storage operations

## Key Components

### 1. SdbTradeStorage Class

Located at: `lib/model/storage/sdb_trade_storage.dart`

Main features:
- Implements `TradeStorage` interface
- Automatic platform detection
- Cross-platform database operations
- Efficient indexing and querying

### 2. Storage Factory

Located at: `lib/model/storage/storage_factory.dart`

Features:
- Storage type management
- Data migration between storage types
- Performance testing utilities
- Platform compatibility checks

### 3. Storage Demo Page

Located at: `lib/view/storage_demo_page.dart`

Development tool for:
- Testing different storage implementations
- Performance comparison
- Data migration testing
- Debugging storage operations

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Cross-platform IndexedDB/SQLite storage
  idb_shim: ^2.5.0+1
  idb_sqflite: ^1.3.2+1
```

## Usage Examples

### Basic Setup

```dart
// Initialize storage (automatic platform detection)
await AppStorageManager.initialize();

// Get storage instance
final storage = AppStorageManager.instance.trades;
```

### Database Operations

```dart
// Save a trade
final trade = Trade(result: 150.0, timestamp: DateTime.now());
final savedTrade = await storage.saveTrade(trade);

// Get all trades
final trades = await storage.getAllTrades();

// Query by date range
final recentTrades = await storage.getTradesByDateRange(
  DateTime.now().subtract(Duration(days: 30)),
  DateTime.now(),
);

// Get statistics
final stats = await storage.getTradeStatistics();
```

### Platform-Specific Initialization

The storage automatically handles platform differences:

```dart
// Web: Uses IndexedDB
if (kIsWeb) {
  factory = idb_browser.idbFactoryWeb;
}

// Desktop: Uses SQLite with FFI
else if (Platform.isWindows || Platform.isLinux) {
  sqflite_ffi.sqfliteFfiInit();
  factory = getIdbFactorySqflite(sqflite_ffi.databaseFactoryFfi);
}

// Mobile: Uses native SQLite
else {
  factory = getIdbFactorySqflite(sqflite.databaseFactory);
}
```

## Database Schema

### Object Store Structure

**Store Name**: `trades`

**Fields**:
- `id` (auto-increment key)
- `result` (double) - Trade profit/loss
- `timestamp` (string, ISO 8601) - Trade execution time
- `created_at` (string, ISO 8601) - Record creation time  
- `updated_at` (string, ISO 8601) - Last update time

**Indexes**:
- `timestamp` - For date range queries
- `result` - For profit/loss filtering

### Database Versioning

```dart
static const int _databaseVersion = 1;

void _onUpgradeNeeded(idb.VersionChangeEvent event) {
  final db = event.database;
  
  if (event.oldVersion < 1) {
    // Create object store
    final store = db.createObjectStore(
      _storeName,
      keyPath: 'id',
      autoIncrement: true,
    );
    
    // Create indexes
    store.createIndex('timestamp', 'timestamp', unique: false);
    store.createIndex('result', 'result', unique: false);
  }
}
```

## Automatic Data Persistence

The system automatically:
- Saves all trades when added
- Loads existing data on app startup
- Maintains data across browser sessions (web)
- Stores data locally on device (mobile/desktop)

## Performance Benefits

### IndexedDB on Web
- **Persistent**: Data survives browser restarts
- **Asynchronous**: Non-blocking operations
- **Indexed**: Fast queries using indexes
- **Large capacity**: Much larger than localStorage
- **Transactional**: ACID compliance

### SQLite on Native Platforms
- **Fast**: Native database performance
- **Reliable**: Proven database engine
- **SQL support**: Complex queries
- **Cross-platform**: Works on all mobile/desktop platforms

## Data Persistence Features

### Automatic Save/Load
- All user data is automatically saved when modified
- Data is loaded automatically when the app starts
- No manual save/load operations required

### Cross-Platform Compatibility
- Same data format across all platforms
- Seamless experience when switching devices
- Import/export capabilities for data backup

## Error Handling

The implementation includes comprehensive error handling:

```dart
try {
  await storage.saveTrade(trade);
} on StorageException catch (e) {
  print('Storage error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Best Practices

1. **Data is automatically saved** - no manual save operations needed
2. **Platform detection is automatic** - works on all platforms
3. **Error handling is built-in** - storage operations are safe
4. **Data persists across sessions** - user data is never lost

## Troubleshooting

### Web Issues

**Problem**: IndexedDB not available
- **Cause**: Private browsing or browser restrictions
- **Solution**: Check browser settings, use standard browsing mode

**Problem**: Data not persisting
- **Cause**: Browser storage quota exceeded
- **Solution**: Clear browser data or implement storage quota management

### Native Issues

**Problem**: Database locked
- **Cause**: Multiple access attempts
- **Solution**: Implement proper connection management

**Problem**: Database file not found
- **Cause**: Path permissions or initialization issues
- **Solution**: Check file permissions and initialization order

## Conclusion

The IndexedDB storage implementation provides a unified, efficient, and reliable storage solution that works consistently across all Flutter platforms. It automatically handles platform differences and provides seamless data persistence without any configuration required.

Users can simply use the app normally, and all their data (trades, settings, etc.) will be automatically saved and restored when they return to the app.