import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import '../../view_model/risk_management_view_model.dart';
import '../../model/storage/app_storage.dart';
import '../../services/file_handler.dart';
import '../../services/simple_persistence_fix.dart';

class SettingsScreen extends StatefulWidget {
  final RiskManagementViewModel viewModel;

  const SettingsScreen({super.key, required this.viewModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SignalsMixin {
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _storageInfo;
  late final FileService _fileService;

  @override
  void initState() {
    super.initState();
    _fileService = FileService();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final info = await AppStorageManager.instance.getStorageInfo();
      setState(() {
        _storageInfo = info;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load storage info: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurpleAccent,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_statusMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  _buildSectionHeader('Storage Information'),
                  _buildStorageInfoCard(),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Risk Settings'),
                  _buildRiskSettingsCard(),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Debug Tools'),
                  _buildDebugCard(),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Data Management'),
                  _buildDataManagementCard(),

                  const SizedBox(height: 24),

                  _buildSectionHeader('Backup & Restore'),
                  _buildBackupRestoreCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStorageInfoCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Storage Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.deepPurpleAccent,
                  ),
                  onPressed: _loadStorageInfo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_storageInfo != null) ...[
              _buildInfoRow(
                'Has Config',
                _storageInfo!['hasConfig']?.toString() ?? 'Unknown',
              ),
              _buildInfoRow(
                'Trades Count',
                _storageInfo!['tradesCount']?.toString() ?? '0',
              ),
              _buildInfoRow(
                'App Version',
                _storageInfo!['appVersion'] ?? 'Not set',
              ),
              if (_storageInfo!['configKeys'] != null)
                _buildInfoRow(
                  'Config Keys',
                  '${(_storageInfo!['configKeys'] as List).length} keys',
                ),
            ] else
              const Text(
                'Unable to load storage information',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSettingsCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Current Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Watch((_) {
              final settings = widget.viewModel.riskSettings.value;
              return Column(
                children: [
                  _buildInfoRow(
                    'Max Drawdown',
                    '\$${settings.maxDrawdown.toStringAsFixed(2)}',
                  ),
                  _buildInfoRow(
                    'Loss Per Trade',
                    '${settings.lossPerTradePercentage.toStringAsFixed(2)}%',
                  ),
                  _buildInfoRow(
                    'Account Balance',
                    '\$${settings.accountBalance.toStringAsFixed(2)}',
                  ),
                  _buildInfoRow(
                    'Current Balance',
                    '\$${settings.currentBalance.toStringAsFixed(2)}',
                  ),
                  _buildInfoRow(
                    'Dynamic Max DD',
                    settings.isDynamicMaxDrawdown ? 'Enabled' : 'Disabled',
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Data Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Warning: These actions cannot be undone!',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearTrades,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Trades'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllData,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupRestoreCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.backup, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Backup & Restore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _fileService.isSupported
                  ? 'Export your data for backup or import from a previous backup.'
                  : 'File operations are not fully supported on this platform.',
              style: TextStyle(
                color: _fileService.isSupported ? Colors.grey : Colors.orange,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fileService.isSupported ? _exportData : null,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fileService.isSupported ? _importData : null,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Import Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      disabledForegroundColor: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirm = await _showConfirmDialog(
      'Reset Settings',
      'Are you sure you want to reset all settings to defaults? This will not affect your trade data.',
    );

    if (confirm) {
      try {
        await widget.viewModel.resetToDefaults();
        await _loadStorageInfo();
        _showSuccessMessage('Settings reset to defaults successfully');
      } catch (e) {
        _showErrorMessage('Failed to reset settings: ${e.toString()}');
      }
    }
  }

  Future<void> _clearTrades() async {
    final confirm = await _showConfirmDialog(
      'Clear All Trades',
      'Are you sure you want to delete all trades? This action cannot be undone.',
    );

    if (confirm) {
      try {
        await widget.viewModel.clearAllTrades();
        await _loadStorageInfo();
        _showSuccessMessage('All trades cleared successfully');
      } catch (e) {
        _showErrorMessage('Failed to clear trades: ${e.toString()}');
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await _showConfirmDialog(
      'Clear All Data',
      'Are you sure you want to delete ALL data including settings and trades? This action cannot be undone.',
    );

    if (confirm) {
      try {
        await widget.viewModel.clearAllStoredData();
        await _loadStorageInfo();
        _showSuccessMessage('All data cleared successfully');
      } catch (e) {
        _showErrorMessage('Failed to clear all data: ${e.toString()}');
      }
    }
  }

  Future<void> _exportData() async {
    if (!_fileService.isSupported) {
      _showErrorMessage('File operations not supported on this platform');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Preparing export...';
      });

      final rawData = await AppStorageManager.instance.exportAllData();

      final exportData = ExportData(
        version: rawData['version'] as String,
        exportDate: DateTime.parse(rawData['exportDate'] as String),
        riskSettings: rawData['riskSettings'] as Map<String, dynamic>?,
        trades: (rawData['trades'] as List).cast<Map<String, dynamic>>(),
        metadata: {'appName': 'Risk Management', 'platform': 'Flutter'},
      );

      setState(() {
        _statusMessage = 'Saving file...';
      });

      final success = await _fileService.exportData(exportData);

      if (success) {
        final preview = _fileService.getExportPreview(exportData);
        _showSuccessMessage(
          'Data exported successfully!\n'
          '• ${preview['tradeCount']} trades\n'
          '• ${preview['hasRiskSettings'] ? 'Settings included' : 'No settings'}\n'
          '• File size: ${preview['estimatedSize']}',
        );
      } else {
        _showErrorMessage('Failed to save export file');
      }
    } catch (e) {
      _showErrorMessage('Export failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  Future<void> _importData() async {
    if (!_fileService.isSupported) {
      _showErrorMessage('File operations not supported on this platform');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Selecting file...';
      });

      final exportData = await _fileService.importData();

      if (exportData == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Validating data...';
      });

      if (!_fileService.validateImportData(exportData)) {
        _showErrorMessage('Invalid backup file format');
        return;
      }

      final confirmed = await _showImportConfirmDialog(exportData);
      if (!confirmed) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Importing data...';
      });

      await AppStorageManager.instance.importAllData(exportData.toJson());

      await _loadStorageInfo();

      _showSuccessMessage(
        'Data imported successfully!\n'
        '• ${exportData.trades.length} trades imported\n'
        '• ${exportData.riskSettings != null ? 'Settings restored' : 'No settings imported'}',
      );
    } catch (e) {
      _showErrorMessage('Import failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Confirm',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessMessage(String message) {
    setState(() {
      _statusMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  Future<bool> _showImportConfirmDialog(ExportData exportData) async {
    final preview = _fileService.getExportPreview(exportData);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text(
              'Import Backup Data',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will replace all current data with the backup data:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Export Date', preview['exportDate']),
                _buildInfoRow('Version', preview['version']),
                _buildInfoRow('Trades', '${preview['tradeCount']}'),
                _buildInfoRow(
                  'Settings',
                  preview['hasRiskSettings'] ? 'Included' : 'Not included',
                ),
                _buildInfoRow('File Size', preview['estimatedSize']),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. All current data will be lost.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Import',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDebugCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Storage Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Check storage status and recover data if needed.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showStorageStatus,
                    icon: const Icon(Icons.info),
                    label: const Text('Check Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _attemptRecovery,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Recovery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startupData = await SimplePersistenceFix.checkStartupData();
      final status = await SimplePersistenceFix.getStorageStatus();

      final combinedReport = StringBuffer();
      combinedReport.writeln('=== COMPREHENSIVE DATA CHECK ===');
      combinedReport.writeln('Platform: ${startupData['platform']}');
      combinedReport.writeln('Has Any Data: ${startupData['hasAnyData']}');
      combinedReport.writeln('Check Time: ${startupData['timestamp']}');
      combinedReport.writeln('\n=== STORAGE SOURCES ===');

      final sources = startupData['sources'] as Map<String, dynamic>;
      for (final entry in sources.entries) {
        combinedReport.writeln('${entry.key.toUpperCase()}:');
        final source = entry.value as Map<String, dynamic>;
        if (source['available'] == true) {
          combinedReport.writeln('  Available: YES');
          if (source['hasRiskSettings'] == true) {
            combinedReport.writeln('  Risk Settings: FOUND');
          }
          if (source['hasBackup'] == true) {
            combinedReport.writeln('  Backup Data: FOUND');
          }
          if (source['hasData'] == true) {
            combinedReport.writeln('  Web Data: FOUND');
          }
          if (source['totalKeys'] != null) {
            combinedReport.writeln('  Total Keys: ${source['totalKeys']}');
          }
        } else {
          combinedReport.writeln('  Available: NO');
          if (source['error'] != null) {
            combinedReport.writeln('  Error: ${source['error']}');
          }
        }
        combinedReport.writeln('');
      }

      combinedReport.writeln('\n$status');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Status'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Text(
                  combinedReport.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: combinedReport.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report copied to clipboard')),
                  );
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Failed to check storage status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _attemptRecovery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recoveredData = await SimplePersistenceFix.tryRecoverData();

      if (recoveredData != null) {
        final restored = await SimplePersistenceFix.restoreData(recoveredData);
        if (restored) {
          _showSuccessMessage(
            'Data recovered successfully! Please refresh the app.',
          );
          await _loadStorageInfo();
        } else {
          _showErrorMessage('Failed to restore recovered data');
        }
      } else {
        _showErrorMessage('No recoverable data found');
      }
    } catch (e) {
      _showErrorMessage('Recovery failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
