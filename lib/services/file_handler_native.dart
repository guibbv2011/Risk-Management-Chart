import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'file_handler.dart';

class NativeFileHandler implements FileHandler {
  @override
  bool get isSupported => !kIsWeb;

  @override
  Future<bool> saveFile(String fileName, String data) async {
    try {
      final directory = await _getDownloadDirectory();
      final file = File(path.join(directory.path, fileName));

      await file.writeAsString(data);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> pickAndReadFile() async {
    try {
      final directory = await _getDownloadDirectory();

      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        return null;
      }

      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      final latestFile = files.first;

      return await latestFile.readAsString();
    } catch (e) {
      rethrow;
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
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
            rethrow;
          }
          return await getApplicationDocumentsDirectory();

        case TargetPlatform.iOS:
          return await getApplicationDocumentsDirectory();

        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
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
            rethrow;
          }
          return await getApplicationSupportDirectory();

        default:
          return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<bool> saveFileToPath(String filePath, String data) async {
    try {
      final file = File(filePath);

      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsString(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> readFileFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

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
      return [];
    }
  }

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
      return {
        'name': path.basename(file.path),
        'path': file.path,
        'error': e.toString(),
      };
    }
  }
}

FileHandler createFileHandler() {
  return NativeFileHandler();
}
