import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'file_handler.dart';

/// Native file handler for mobile and desktop platforms
class NativeFileHandler implements FileHandler {
  @override
  bool get isSupported => !kIsWeb;

  @override
  Future<bool> saveFile(String fileName, String data) async {
    try {
      // Get appropriate directory based on platform
      final directory = await _getDownloadDirectory();
      final file = File(path.join(directory.path, fileName));

      // Write data to file
      await file.writeAsString(data);

      debugPrint('File saved: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('Native file save failed: $e');
      return false;
    }
  }

  @override
  Future<String?> pickAndReadFile() async {
    try {
      // For now, we'll read from the downloads directory
      // In a production app, you'd use file_picker package
      final directory = await _getDownloadDirectory();

      // List JSON files in directory
      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        debugPrint('No JSON files found in downloads directory');
        return null;
      }

      // For simplicity, take the most recent file
      // In production, you'd show a file picker dialog
      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      final latestFile = files.first;

      debugPrint('Reading file: ${latestFile.path}');
      return await latestFile.readAsString();
    } catch (e) {
      debugPrint('Native file pick failed: $e');
      rethrow;
    }
  }

  /// Get appropriate download directory for the platform
  Future<Directory> _getDownloadDirectory() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          // Try external storage first, fallback to app directory
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              final downloadDir = Directory(
                path.join(externalDir.path, 'Download'),
              );
              if (!await downloadDir.exists()) {
                await downloadDir.create(recursive: true);
              }
              return downloadDir;
            }
          } catch (e) {
            debugPrint('External storage not available: $e');
          }
          // Fallback to app documents directory
          return await getApplicationDocumentsDirectory();

        case TargetPlatform.iOS:
          // iOS uses documents directory
          return await getApplicationDocumentsDirectory();

        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
          // Desktop platforms use downloads folder if available
          try {
            final homeDir =
                Platform.environment['HOME'] ??
                Platform.environment['USERPROFILE'] ??
                '';
            if (homeDir.isNotEmpty) {
              final downloadDir = Directory(path.join(homeDir, 'Downloads'));
              if (await downloadDir.exists()) {
                return downloadDir;
              }
            }
          } catch (e) {
            debugPrint('Downloads folder not accessible: $e');
          }
          // Fallback to app support directory
          return await getApplicationSupportDirectory();

        default:
          // Fallback for other platforms
          return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugPrint('Error getting download directory: $e');
      // Final fallback
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Save file to specific path (for advanced usage)
  Future<bool> saveFileToPath(String filePath, String data) async {
    try {
      final file = File(filePath);

      // Create directory if it doesn't exist
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsString(data);
      debugPrint('File saved to specific path: $filePath');
      return true;
    } catch (e) {
      debugPrint('Failed to save file to path: $e');
      return false;
    }
  }

  /// Read file from specific path
  Future<String?> readFileFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }

      return await file.readAsString();
    } catch (e) {
      debugPrint('Failed to read file from path: $e');
      return null;
    }
  }

  /// List available backup files
  Future<List<File>> listBackupFiles() async {
    try {
      final directory = await _getDownloadDirectory();

      return directory
          .listSync()
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.json') &&
                path.basename(file.path).startsWith('risk_management_backup_'),
          )
          .toList();
    } catch (e) {
      debugPrint('Failed to list backup files: $e');
      return [];
    }
  }

  /// Get file info
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final stat = await file.stat();
      return {
        'name': path.basename(file.path),
        'path': file.path,
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'created': stat.accessed.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Failed to get file info: $e');
      return {
        'name': path.basename(file.path),
        'path': file.path,
        'error': e.toString(),
      };
    }
  }
}

/// Factory function to create native file handler
FileHandler createFileHandler() {
  return NativeFileHandler();
}
