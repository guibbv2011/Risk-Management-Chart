# Troubleshooting Guide - Local Storage

## 🔍 Common Issues and Solutions

### Web Platform Issues

#### Issue: "Continue without local storage" on web
**Symptoms:**
- App shows initialization screen with storage error
- "Continue without local storage" button appears
- Console shows IndexedDB or storage initialization errors

**Solutions:**
1. **Check Browser Compatibility**
   ```
   Supported browsers:
   - Chrome 86+
   - Firefox 79+
   - Safari 14+
   - Edge 86+
   ```

2. **Enable Third-party Cookies**
   - Chrome: Settings → Privacy → Cookies → Allow all cookies
   - Firefox: Settings → Privacy → Custom → Cookies → Accept cookies
   - Safari: Preferences → Privacy → Uncheck "Prevent cross-site tracking"

3. **Clear Browser Storage**
   ```
   Chrome: F12 → Application → Storage → Clear storage
   Firefox: F12 → Storage → Clear all
   Safari: Develop → Empty Caches
   ```

4. **Check Browser Console**
   ```
   Look for errors like:
   - "QuotaExceededError"
   - "SecurityError" 
   - "InvalidStateError"
   ```

#### Issue: Export doesn't download file on web
**Symptoms:**
- Export button shows success message
- No file download occurs
- Browser blocks download

**Solutions:**
1. **Check Download Settings**
   - Ensure downloads are enabled in browser
   - Check if download location is accessible
   - Disable popup blockers for the app

2. **Browser Permissions**
   - Allow downloads from the app domain
   - Check if automatic downloads are blocked

3. **Try Different Browser**
   - Test in Chrome, Firefox, or Safari
   - Some browsers handle blob downloads differently

#### Issue: Import file picker doesn't open on web
**Symptoms:**
- Import button doesn't show file picker
- Console shows file API errors

**Solutions:**
1. **HTTPS Requirement**
   - File APIs require HTTPS in production
   - Use `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` for local testing

2. **Browser Support**
   - Ensure File API is supported
   - Check browser compatibility

### Mobile Platform Issues

#### Issue: Database initialization fails on Android
**Symptoms:**
- App crashes on startup
- "Failed to initialize database" error
- Storage permission errors

**Solutions:**
1. **Check Storage Permissions**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

2. **Clear App Data**
   - Settings → Apps → Risk Management → Storage → Clear Data
   - Uninstall and reinstall app

3. **Check Available Storage**
   - Ensure device has sufficient free storage
   - Try moving app to internal storage

#### Issue: Export/Import files not found on mobile
**Symptoms:**
- Export shows success but file not found
- Import can't find exported files

**Solutions:**
1. **Check File Locations**
   ```
   Android: /storage/emulated/0/Download/
   iOS: App Documents directory (accessible via Files app)
   ```

2. **File Manager Access**
   - Use device file manager to locate exported files
   - Check Downloads folder or Documents folder

3. **App Permissions**
   - Grant file access permissions when prompted
   - Check app permissions in device settings

### Desktop Platform Issues

#### Issue: SQLite FFI initialization fails
**Symptoms:**
- "Failed to initialize storage" on Windows/Linux/macOS
- Missing SQLite libraries error

**Solutions:**
1. **Install SQLite Dependencies**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install sqlite3 libsqlite3-dev
   
   # macOS
   brew install sqlite3
   
   # Windows
   # SQLite is usually bundled with Flutter
   ```

2. **Path Issues**
   - Ensure app has write permissions to chosen directory
   - Try running as administrator (Windows) or with sudo (Linux)

3. **Directory Access**
   ```
   Check if these directories are accessible:
   - Windows: %APPDATA%/[AppName]
   - macOS: ~/Library/Application Support/[AppName]
   - Linux: ~/.local/share/[AppName]
   ```

### Data Import/Export Issues

#### Issue: Import fails with "Invalid backup file format"
**Symptoms:**
- Import file picker works but validation fails
- "Invalid backup file format" error message

**Solutions:**
1. **Check File Format**
   ```json
   Valid backup file should contain:
   {
     "version": "1.0.0",
     "exportDate": "2024-01-15T10:30:00.000Z",
     "riskSettings": { ... },
     "trades": [ ... ]
   }
   ```

2. **File Encoding**
   - Ensure file is saved as UTF-8
   - Check for BOM (Byte Order Mark) issues

3. **File Size Limits**
   - Large files (>50MB) may cause issues
   - Try exporting smaller date ranges

#### Issue: Exported data appears incomplete
**Symptoms:**
- Export succeeds but missing trades or settings
- File size smaller than expected

**Solutions:**
1. **Check Data Consistency**
   - Verify all trades are saved before export
   - Check if database is corrupted

2. **Storage Sync Issues**
   - Wait a moment after adding trades before export
   - Force refresh in settings before export

3. **Memory Issues**
   - Large datasets may cause memory issues
   - Try clearing cache and retry

## 🛠️ Debug Tools

### Browser Developer Console
```javascript
// Check IndexedDB status
indexedDB.databases().then(console.log);

// Check storage quota
navigator.storage.estimate().then(console.log);

// Check if storage is persistent
navigator.storage.persisted().then(console.log);
```

### Flutter Debug Commands
```bash
# Run with verbose logging
flutter run --verbose

# Web debug mode
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080

# Check for issues
flutter doctor -v
flutter analyze
```

### Storage Debug Information
Access the settings screen → Storage Information section to check:
- Has Config: true/false
- Trades Count: number
- App Version: version string
- Config Keys: list of stored keys

## 📞 Getting Help

### Log Collection
When reporting issues, include:
1. **Platform Information**
   - Operating system and version
   - Browser type and version (for web)
   - Device model (for mobile)

2. **Error Messages**
   - Full error message from console
   - Screenshot of error screen
   - Steps to reproduce

3. **Storage Debug Info**
   - Storage information from settings screen
   - Browser storage quota (for web)
   - Available device storage (for mobile)

### Debug Mode Information
Enable debug mode to see:
- Platform detection results
- Storage initialization steps
- Database path information
- File operation results

### Common Error Codes
- `StorageException`: General storage error
- `QuotaExceededError`: Browser storage limit reached
- `SecurityError`: Permission or security restriction
- `InvalidStateError`: Database in invalid state
- `FileSystemException`: File system access error

## 🔄 Recovery Procedures

### Complete Reset
If all else fails:
1. **Clear all app data**
   - Web: Clear browser storage
   - Mobile: Clear app data in settings
   - Desktop: Delete app data directory

2. **Reinstall app** (mobile only)
   - Uninstall from device
   - Reinstall from app store

3. **Reset to defaults**
   - Use "Clear All Data" in settings
   - Start fresh with default settings

### Data Recovery
If you have backup files:
1. **Manual import**
   - Use import function in settings
   - Select your backup JSON file

2. **Partial recovery**
   - Extract trades from backup file
   - Manually re-enter critical data

Remember: Always keep backup files in a safe location!