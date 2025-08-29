import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'file_handler_web.dart' if (dart.library.io) 'file_handler_native.dart';

abstract class FileHandler {
  Future<bool> saveFile(String fileName, String data);

  Future<String?> pickAndReadFile();

  bool get isSupported;
}

class FileHandlerFactory {
  static FileHandler create() {
    return createFileHandler();
  }
}

class ExportData {
  final String version;
  final DateTime exportDate;
  final Map<String, dynamic>? riskSettings;
  final List<Map<String, dynamic>> trades;
  final Map<String, dynamic> metadata;

  ExportData({
    required this.version,
    required this.exportDate,
    this.riskSettings,
    required this.trades,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportDate': exportDate.toIso8601String(),
      'riskSettings': riskSettings,
      'trades': trades,
      'metadata': {
        ...metadata,
        'platform': kIsWeb ? 'web' : 'native',
        'tradeCount': trades.length,
      },
    };
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      version: json['version'] as String,
      exportDate: DateTime.parse(json['exportDate'] as String),
      riskSettings: json['riskSettings'] as Map<String, dynamic>?,
      trades: (json['trades'] as List).cast<Map<String, dynamic>>(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  static ExportData fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ExportData.fromJson(json);
  }
}

class FileService {
  final FileHandler _fileHandler;

  FileService() : _fileHandler = FileHandlerFactory.create();

  bool get isSupported => _fileHandler.isSupported;

  Future<bool> exportData(ExportData data) async {
    if (!isSupported) {
      throw UnsupportedError('File operations not supported on this platform');
    }

    try {
      final fileName = _generateExportFileName(data.exportDate);
      final jsonString = data.toJsonString();

      return await _fileHandler.saveFile(fileName, jsonString);
    } catch (e) {
      return false;
    }
  }

  Future<ExportData?> importData() async {
    if (!isSupported) {
      throw UnsupportedError('File operations not supported on this platform');
    }

    try {
      final jsonString = await _fileHandler.pickAndReadFile();
      if (jsonString == null) {
        return null; 
      }

      return ExportData.fromJsonString(jsonString);
    } catch (e) {
      rethrow;
    }
  }

  String _generateExportFileName(DateTime exportDate) {
    final timestamp = exportDate.toIso8601String().split('T')[0];
    return 'risk_management_backup_$timestamp.json';
  }

  bool validateImportData(ExportData data) {
    try {
      if (data.version.isEmpty) {
        return false;
      }

      if (data.trades.isNotEmpty) {
        for (final trade in data.trades) {
          if (!trade.containsKey('result') || !trade.containsKey('timestamp')) {
            return false;
          }
        }
      }

      if (data.riskSettings != null) {
        final required = [
          'maxDrawdown',
          'lossPerTradePercentage',
          'accountBalance',
        ];
        for (final key in required) {
          if (!data.riskSettings!.containsKey(key)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> getExportPreview(ExportData data) {
    return {
      'version': data.version,
      'exportDate': data.exportDate.toIso8601String(),
      'hasRiskSettings': data.riskSettings != null,
      'tradeCount': data.trades.length,
      'platform': data.metadata['platform'] ?? 'unknown',
      'estimatedSize':
          '${(data.toJsonString().length / 1024).toStringAsFixed(1)} KB',
    };
  }
}
