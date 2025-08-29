# Local Storage Implementation

This document describes the comprehensive local storage implementation for the Risk Management app, which works across Android, iOS, Linux, Windows, and Web platforms.

## Overview

The app uses a multi-layered storage architecture that separates configuration data from trade data, ensuring optimal performance and platform compatibility.

### Storage Technologies Used

- **SharedPreferences**: For configuration data (risk settings)
- **SQLite**: For trade data storage
- **Platform-specific adapters**: For cross-platform compatibility

## Architecture

### Storage Interfaces

#### ConfigStorage
```dart
abstract class ConfigStorage {
  Future<void> saveRiskSettings(RiskManagement riskSettings);
  Future<RiskManagement?> loadRiskSettings();
  Future<void> clearRiskSettings();
  Future<bool> hasRiskSettings();
}
```

#### TradeStorage
```dart
abstract class TradeStorage {
  Future<void> initializeDatabase();
  Future<List<Trade>> getAllTrades();
  Future<Trade> saveTrade(Trade trade);
  Future<Trade> updateTrade(Trade trade);
  Future<void> deleteTrade(int id);
  Future<Trade?> getTradeById(int id);
  Future<void> clearAllTrades();
  Future<List<Trade>> getTradesByDateRange(DateTime start, DateTime end);
  Future<int> getTradesCount();
  Future<List<Trade>> getRecentTrades({int limit = 10});
  Future<List<Map<String, dynamic>>> exportTrades();
  Future<void> importTrades(List<Map<String, dynamic>> tradesData);
  Future<void> close();
}
```

### Implementation Classes

#### SharedPreferencesConfigStorage
- Stores risk management settings as JSON in SharedPreferences
- Handles data migration between app versions
- Provides error handling for corrupted data
- Works on all platforms (Android, iOS, Web, Desktop)

#### SqliteTradeStorage
- Uses SQLite database for trade data storage
- Supports complex queries and indexing for performance
- Handles platform-specific database paths
- Includes data export/import functionality

#### AppStorageImpl
- Combines both config and trade storage
- Provides unified interface for all storage operations
- Manages initialization and cleanup

## Platform Support

### Android & iOS
- Uses native SQLite implementation
- Stores data in app's documents directory
- Full SQLite feature support

### Windows & Linux
- Uses `sqflite_common_ffi` for SQLite support
- Stores data in application support directory
- Full SQLite feature support

### Web
- Uses `sqflite_common_ffi_web` for IndexedDB backend
- Stores data in browser's IndexedDB
- Full SQLite API compatibility through WebAssembly

### macOS
- Uses FFI implementation for consistency
- Stores data in application support directory
- Full SQLite feature support

## Database Schema

### Trades Table
```sql
CREATE TABLE trades (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  result REAL NOT NULL,
  timestamp TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_trades_timestamp ON trades(timestamp);
CREATE INDEX idx_trades_result ON trades(result);
```

## Data Models

### RiskManagement Settings
```json
{
  "maxDrawdown": 1000.0,
  "lossPerTradePercentage": 5.0,
  "accountBalance": 10000.0,
  "currentBalance": 10000.0,
  "isDynamicMaxDrawdown": false
}
```

### Trade Data
```json
{
  "id": 1,
  "result": 150.50,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Usage Examples

### Initialize Storage
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize platform-specific storage
  await StorageInitializer.initialize();
  
  // Initialize app storage
  await AppStorageManager.initialize();
  
  runApp(MyApp());
}
```

### Save/Load Risk Settings
```dart
final storage = AppStorageManager.instance.config;

// Save settings
final riskSettings = RiskManagement(
  maxDrawdown: 1000.0,
  lossPerTradePercentage: 5.0,
  accountBalance: 10000.0,
  currentBalance: 10000.0,
);
await storage.saveRiskSettings(riskSettings);

// Load settings
final savedSettings = await storage.loadRiskSettings();
```

### Trade Operations
```dart
final storage = AppStorageManager.instance.trades;

// Add a trade
final trade = Trade(id: 0, result: 150.50);
final savedTrade = await storage.saveTrade(trade);

// Get all trades
final allTrades = await storage.getAllTrades();

// Get trade statistics
final count = await storage.getTradesCount();
final recentTrades = await storage.getRecentTrades(limit: 10);
```

## Data Persistence

### What Gets Saved
- **Risk Settings**: Max drawdown, loss percentage, account balance, dynamic settings
- **Trade Data**: All trade results with timestamps
- **App State**: Current balance, calculated from trade history

### What Doesn't Get Saved
- **UI State**: Chart zoom level, selected tabs
- **Temporary Data**: Error messages, loading states
- **Calculated Values**: Statistics are computed from stored data

## Data Migration

### Version Management
- App version is stored with settings
- Migration logic handles version changes
- Graceful fallback to defaults for corrupted data

### Future Migrations
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add new columns or tables
    await db.execute('ALTER TABLE trades ADD COLUMN category TEXT');
  }
  // Handle future schema changes
}
```

## Backup & Restore

### Export Data
```dart
final data = await AppStorageManager.instance.exportAllData();
// Returns JSON with all settings and trades
{
  "version": "1.0.0",
  "exportDate": "2024-01-15T10:30:00.000Z",
  "riskSettings": { ... },
  "trades": [ ... ]
}
```

### Import Data
```dart
await AppStorageManager.instance.importAllData(backupData);
// Clears existing data and imports from backup
```

## Error Handling

### Storage Initialization Errors
- App shows initialization screen
- Retry mechanism available
- Option to continue without storage (in-memory only)

### Data Corruption
- Settings: Fall back to defaults
- Trades: Attempt recovery, clear if necessary
- User notification of data issues

### Platform-Specific Issues
- Web: Handle quota exceeded errors
- Mobile: Handle storage permission issues
- Desktop: Handle file system access issues

## Performance Considerations

### Caching Strategy
- Trade data is cached in memory after first load
- Cache is invalidated on data changes
- Selective loading for large datasets

### Database Optimization
- Indexes on frequently queried columns
- Batch operations for bulk inserts
- Connection pooling and proper cleanup

### Memory Management
- Limit cached trade data size
- Lazy loading for historical data
- Proper disposal of database connections

## Security Considerations

### Data Protection
- No sensitive data stored (only trading results)
- Platform-specific storage encryption (iOS/Android)
- No network transmission of stored data

### Access Control
- App-sandboxed storage locations
- No shared storage with other apps
- Proper file permissions on desktop platforms

## Testing Strategy

### Unit Tests
- Storage interface implementations
- Data serialization/deserialization
- Error handling scenarios

### Integration Tests
- Cross-platform compatibility
- Data migration scenarios
- Performance under load

### Platform-Specific Tests
- Web IndexedDB functionality
- Desktop file system access
- Mobile storage permissions

## Troubleshooting

### Common Issues

#### Storage Initialization Fails
- Check platform-specific dependencies
- Verify file system permissions
- Clear app data/cache

#### Data Not Persisting
- Verify storage is properly initialized
- Check for storage quota limits (web)
- Ensure proper cleanup/disposal

#### Performance Issues
- Check database indexes
- Monitor cache size
- Profile memory usage

### Debug Information
The settings screen provides storage debug information:
- Configuration status
- Trade count
- Storage keys
- App version

## Future Enhancements

### Planned Features
- **Cloud Sync**: Optional cloud backup/sync
- **Data Compression**: Compress large trade datasets
- **Encryption**: Optional local data encryption
- **Advanced Export**: CSV/Excel export formats

### Scalability Improvements
- **Partitioning**: Split large trade datasets
- **Archiving**: Move old trades to archive storage
- **Streaming**: Stream large datasets instead of loading all

## Dependencies

```yaml
dependencies:
  shared_preferences: ^2.2.2    # Config storage
  sqflite: ^2.3.0              # Mobile SQLite
  sqflite_common_ffi: ^2.3.0   # Desktop SQLite
  sqflite_common_ffi_web: ^0.4.2+2  # Web SQLite
  path_provider: ^2.1.1        # File system paths
  path: ^1.8.3                 # Path utilities
```

## Conclusion

This local storage implementation provides a robust, cross-platform solution for persisting risk management data. The modular architecture allows for easy testing, maintenance, and future enhancements while ensuring data integrity and performance across all supported platforms.