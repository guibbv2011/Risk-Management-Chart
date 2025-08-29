# Web Persistence Debugging Guide

## Overview
This guide helps you verify and debug data persistence issues in the Risk Management web application. Use this when data isn't saving between browser sessions.

## 🔍 Quick Diagnosis Steps

### 1. Check Console Logs on Startup
When you open the web app, look for these key messages in the browser console (F12):

```
🔍 Starting comprehensive data check...
Startup storage scan: true/false
Primary storage has data: true/false
✅ Data refreshed - X trades loaded, Current balance: $X.XX
✅ Loaded saved risk settings - Balance: $X.XX, Max DD: $X.XX
```

**Good Signs:**
- `Startup storage scan: true`
- `Primary storage has data: true`
- `✅ Loaded saved risk settings`
- `✅ Data refreshed - X trades loaded`

**Bad Signs:**
- `❌ No data found in primary or backup storage`
- `❌ No recoverable data found`
- `❌ Failed to load saved risk settings`

### 2. Use Built-in Diagnostics
1. Go to **Settings → Storage Status**
2. Click **"Check Status"** for comprehensive report
3. Look for this information:

```
=== COMPREHENSIVE DATA CHECK ===
Platform: web
Has Any Data: true/false

=== STORAGE SOURCES ===
SHAREDPREFERENCES:
  Available: YES/NO
  Risk Settings: FOUND/NOT FOUND
  Backup Data: FOUND/NOT FOUND

WEBSTORAGE:
  Available: YES/NO
  Web Data: FOUND/NOT FOUND
```

### 3. Manual Browser Storage Check
Open browser developer tools (F12) and check:

**Application/Storage Tab:**
- **Local Storage** → Look for keys like `risk_settings`, `backup_data`
- **Session Storage** → Look for backup data
- **IndexedDB** → Look for `risk_management` database

## 🔧 Common Issues and Solutions

### Issue 1: Private/Incognito Mode
**Symptoms:**
- Console shows: "Private Mode: YES (Data won't persist)"
- Data resets every session

**Solution:**
- Exit private/incognito browsing mode
- Use normal browser window

### Issue 2: Blocked Browser Storage
**Symptoms:**
- Console shows: "LocalStorage: BLOCKED"
- "SharedPreferences: ERROR"

**Solutions:**
1. **Chrome/Edge:**
   - Settings → Privacy and security → Site Settings
   - Cookies and site data → "Allow sites to save and read cookie data"

2. **Firefox:**
   - Settings → Privacy & Security
   - Select "Standard" (not "Strict")

3. **Safari:**
   - Preferences → Privacy
   - Uncheck "Block all cookies"

### Issue 3: Storage Quota Exceeded
**Symptoms:**
- Console shows storage errors
- App works but doesn't save

**Solutions:**
- Clear browser data for other sites
- Export your data first as backup
- Use browser storage management tools

### Issue 4: JavaScript Disabled
**Symptoms:**
- App doesn't work at all
- No console messages

**Solution:**
- Enable JavaScript in browser settings
- Disable script-blocking extensions for this site

## 🧪 Testing Data Persistence

### Test 1: Basic Save/Load
1. Add a few trades
2. Change max drawdown setting
3. **Check console for:** `✅ Trade added to database successfully`
4. Refresh the page (F5)
5. **Verify:** Data should reload automatically

### Test 2: Storage Locations
1. Open browser dev tools (F12)
2. Application/Storage → Local Storage
3. **Should see keys:**
   - `risk_settings`
   - `backup_data`
   - `flutter.*` keys

### Test 3: Recovery System
1. Go to Settings → Storage Status
2. Click **"Try Recovery"**
3. **Should see:** Success message if backup data exists
4. **Check console for:** Recovery attempt messages

### Test 4: Cross-Session Persistence
1. Add trades and change settings
2. **Close entire browser** (not just tab)
3. Reopen browser and navigate to app
4. **Verify:** All data should be restored

## 🛠️ Advanced Debugging

### Console Commands for Manual Testing
Open browser console (F12) and try these:

```javascript
// Check what's in localStorage
Object.keys(localStorage).filter(key => 
  key.includes('risk') || key.includes('backup') || key.includes('flutter')
)

// Check localStorage data
localStorage.getItem('risk_settings')
localStorage.getItem('backup_data')

// Check storage quota
navigator.storage.estimate().then(estimate => {
  console.log('Used:', estimate.usage, 'Available:', estimate.quota);
});

// Test storage write
try {
  localStorage.setItem('test', 'value');
  localStorage.removeItem('test');
  console.log('✅ Storage write works');
} catch(e) {
  console.log('❌ Storage write failed:', e);
}
```

### Reading Console Logs
Look for these specific patterns:

**Successful Startup:**
```
🔍 Starting comprehensive data check...
✅ Found risk settings in SharedPreferences
Primary storage has data: true
✅ Data refreshed - 5 trades loaded, Current balance: $10,250.50
```

**Recovery Needed:**
```
⚠️ No primary data but backup data found, restoring...
✅ Data successfully restored from backup
```

**Problem Indicators:**
```
❌ No data found in primary or backup storage
❌ SharedPreferences recovery failed: DOMException
❌ LocalStorage: BLOCKED
```

## 🔄 Recovery Procedures

### Automatic Recovery
The app automatically attempts recovery on startup:
1. Checks primary storage
2. Checks backup locations
3. Restores from best available source
4. Updates primary storage

### Manual Recovery
If automatic recovery fails:
1. Go to **Settings → Storage Status**
2. Click **"Check Status"** to see what data exists
3. Click **"Try Recovery"** to force restoration
4. **Copy the report** for troubleshooting

### Emergency Export/Import
If all else fails:
1. If any data is visible, immediately **export it**
2. Clear browser storage completely
3. Refresh the app
4. **Import the exported data**

## 📊 Interpreting Diagnostic Reports

### Good Report Example:
```
=== COMPREHENSIVE DATA CHECK ===
Platform: web
Has Any Data: true

SHAREDPREFERENCES:
  Available: YES
  Risk Settings: FOUND
  Backup Data: FOUND
  Total Keys: 15

=== App Data Status ===
Has Stored Data: true
Trades Count: 5
Has Config: true
```

### Problem Report Example:
```
=== COMPREHENSIVE DATA CHECK ===
Platform: web
Has Any Data: false

SHAREDPREFERENCES:
  Available: YES
  Risk Settings: NOT FOUND
  Backup Data: NOT FOUND
  Total Keys: 2

LocalStorage: BLOCKED
Private Mode: YES (Data won't persist)
```

## 🌐 Browser-Specific Issues

### Chrome/Chromium
- **Best compatibility**
- Issues: Extensions blocking storage
- Solution: Disable privacy extensions for this site

### Firefox
- **Good compatibility**
- Issues: Strict privacy settings
- Solution: Add site to exceptions list

### Safari
- **Limited compatibility**
- Issues: Restrictive storage policies
- Solution: Use Chrome or Firefox instead

### Edge
- **Good compatibility**
- Same solutions as Chrome

## 📝 Troubleshooting Checklist

**Before Reporting Issues:**
- [ ] Checked browser console for error messages
- [ ] Verified not in private/incognito mode
- [ ] Ran Settings → Storage Status → "Check Status"
- [ ] Tried "Try Recovery" button
- [ ] Tested in different browser
- [ ] Exported data as backup

**Information to Include:**
- Browser type and version
- Operating system
- Console error messages
- Storage status report
- Steps that reproduce the issue

## 🔧 Developer Debug Mode

For developers, add this to see all storage operations:
```javascript
// Enable verbose logging
localStorage.setItem('debug_storage', 'true');
```

This will show detailed console output for every storage operation.

## 🚨 Emergency Data Recovery

If you lose data:
1. **Don't refresh the page** immediately
2. Open dev tools and check localStorage
3. Copy any found data manually
4. Try the recovery button
5. Export any recovered data immediately

## 📞 Getting Help

When asking for help, provide:
1. Browser console output (full)
2. Storage status report (from app)
3. Browser and OS versions
4. Specific steps that cause the problem
5. Whether it works in other browsers

---

**Remember:** The app creates multiple backups automatically. Even if the main storage fails, recovery is usually possible!