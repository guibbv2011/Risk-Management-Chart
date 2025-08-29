# Web Storage Troubleshooting Guide

## Quick Fix for Data Not Persisting

If your data isn't saving between browser sessions, follow these steps:

### 1. Check Private Mode
**Problem:** Data doesn't save in private/incognito mode
**Solution:** Open the app in normal browsing mode

### 2. Enable Browser Storage
**Chrome:**
- Settings → Privacy and security → Site Settings → Cookies and site data
- Make sure "Allow sites to save and read cookie data" is enabled

**Firefox:**
- Settings → Privacy & Security → Cookies and Site Data
- Select "Standard" or "Custom" (not "Strict")

**Safari:**
- Preferences → Privacy → Cookies and website data
- Select "Allow from websites I visit"

### 3. Check Storage Status
1. Go to **Settings → Debug Tools → Storage Status**
2. Click **"Check Status"** to see what's working
3. If it shows "Private Mode: YES" - exit private browsing

### 4. Try Data Recovery
1. In Settings → Debug Tools, click **"Try Recovery"**
2. This will attempt to restore any backed-up data
3. Refresh the app if recovery succeeds

### 5. Manual Recovery Steps
If the above doesn't work:

1. **Export your current data** (if any exists)
2. **Clear browser data** for this site
3. **Refresh the page**
4. **Import your data** back

### 6. Browser-Specific Issues

**Chrome/Edge:** Usually works well
**Firefox:** May need to enable cookies in private windows
**Safari:** Limited support - try Chrome or Firefox instead
**Mobile browsers:** Use desktop version when possible

### 7. Prevention Tips

- **Don't use private/incognito mode** for this app
- **Export data regularly** as backup
- **Enable cookies and site data** in browser settings
- **Bookmark the app** for easy access

### 8. Emergency Backup

The app automatically creates backups in multiple locations:
- Browser local storage
- SharedPreferences
- Session storage

Use the "Try Recovery" button to restore from these backups.

### Still Having Issues?

1. Try a different browser (Chrome recommended)
2. Check if your antivirus is blocking storage
3. Make sure JavaScript is enabled
4. Clear browser cache and cookies, then try again

---

**Remember:** Always export your data regularly as a backup!