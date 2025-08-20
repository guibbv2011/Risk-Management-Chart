import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/trade.dart';
import '../model/risk_management.dart';
import 'error_handling.dart';
import 'date_time_utils.dart';

class ServiceUtils {
  static bool get isWeb => kIsWeb;
  static bool get isNative => !kIsWeb;
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;

  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Web Platform';
    } else {
      return 'Native Platform';
    }
  }

  static Map<String, dynamic> createBackupData({
    required List<Trade> trades,
    required RiskManagement riskSettings,
    String? version,
  }) {
    return {
      'version': version ?? '1.0.0',
      'timestamp': DateTimeUtils.getCurrentTimestamp(),
      'platform': getPlatformInfo(),
      'riskSettings': riskSettings.toJson(),
      'trades': trades.map((trade) => trade.toJson()).toList(),
      'metadata': {
        'totalTrades': trades.length,
        'exportedAt': DateTimeUtils.getCurrentTimestamp(),
        'platform': kIsWeb ? 'web' : 'native',
      },
    };
  }

  static bool validateBackupData(Map<String, dynamic> data) {
    try {
      final requiredFields = ['version', 'timestamp', 'riskSettings', 'trades'];
      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          return false;
        }
      }

      final riskSettings = data['riskSettings'] as Map<String, dynamic>?;
      if (riskSettings == null) {
        return false;
      }

      final riskRequiredFields = [
        'accountBalance',
        'maxDrawdown',
        'lossPerTradePercentage',
      ];
      for (final field in riskRequiredFields) {
        if (!riskSettings.containsKey(field)) {
          return false;
        }
      }

      final trades = data['trades'] as List?;
      if (trades == null) {
        return false;
      }

      for (final trade in trades) {
        if (trade is! Map<String, dynamic>) {
          return false;
        }
        if (!trade.containsKey('result') || !trade.containsKey('timestamp')) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static ErrorResult<Map<String, dynamic>> parseBackupData(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!validateBackupData(data)) {
        return ErrorResult.error(
          ValidationException('Invalid backup data structure'),
        );
      }

      return ErrorResult.success(data);
    } catch (e, stackTrace) {
      return ErrorResult.error(e, stackTrace);
    }
  }

  static ErrorResult<List<Trade>> backupDataToTrades(
    Map<String, dynamic> backupData,
  ) {
    try {
      final tradesData = backupData['trades'] as List;
      final trades = <Trade>[];

      for (final tradeData in tradesData) {
        final trade = Trade.fromJson(tradeData as Map<String, dynamic>);
        trades.add(trade);
      }

      return ErrorResult.success(trades);
    } catch (e, stackTrace) {
      return ErrorResult.error(e, stackTrace);
    }
  }

  static ErrorResult<RiskManagement> backupDataToRiskSettings(
    Map<String, dynamic> backupData,
  ) {
    try {
      final riskData = backupData['riskSettings'] as Map<String, dynamic>;
      final riskSettings = RiskManagement.fromJson(riskData);
      return ErrorResult.success(riskSettings);
    } catch (e, stackTrace) {
      return ErrorResult.error(e, stackTrace);
    }
  }

  static String generateBackupFileName({
    String prefix = 'risk_management_backup',
    DateTime? timestamp,
  }) {
    final date = timestamp ?? DateTime.now();
    return '${prefix}_${DateTimeUtils.formatForFileName(date)}.json';
  }

  static String formatJsonForExport(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Map<String, dynamic> sanitizeForStorage(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        continue; 
      }

      if (value is Map<String, dynamic>) {
        final nestedSanitized = sanitizeForStorage(value);
        if (nestedSanitized.isNotEmpty) {
          sanitized[key] = nestedSanitized;
        }
      } else if (value is List) {
        final sanitizedList = <dynamic>[];
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final sanitizedItem = sanitizeForStorage(item);
            if (sanitizedItem.isNotEmpty) {
              sanitizedList.add(sanitizedItem);
            }
          } else if (item != null) {
            sanitizedList.add(item);
          }
        }
        if (sanitizedList.isNotEmpty) {
          sanitized[key] = sanitizedList;
        }
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  static bool hasStoredData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return false;
    }

    final riskSettings = data['riskSettings'] as Map<String, dynamic>?;
    if (riskSettings != null && riskSettings.isNotEmpty) {
      return true;
    }

    final trades = data['trades'] as List?;
    if (trades != null && trades.isNotEmpty) {
      return true;
    }

    return false;
  }

  static Map<String, dynamic> mergeBackupData(
    List<Map<String, dynamic>> backupSources,
  ) {
    if (backupSources.isEmpty) {
      return {};
    }

    if (backupSources.length == 1) {
      return backupSources.first;
    }

    final sortedSources = List<Map<String, dynamic>>.from(backupSources);
    sortedSources.sort((a, b) {
      final timestampA = a['timestamp'] as String?;
      final timestampB = b['timestamp'] as String?;

      if (timestampA == null && timestampB == null) return 0;
      if (timestampA == null) return 1;
      if (timestampB == null) return -1;

      try {
        final dateA = DateTimeUtils.fromIso8601(timestampA);
        final dateB = DateTimeUtils.fromIso8601(timestampB);
        return dateB.compareTo(dateA); 
      } catch (e) {
        return 0;
      }
    });

    final merged = Map<String, dynamic>.from(sortedSources.first);

    final allTrades = <Map<String, dynamic>>[];
    final seenTrades = <String>{};

    for (final source in sortedSources) {
      final trades = source['trades'] as List?;
      if (trades != null) {
        for (final trade in trades) {
          if (trade is Map<String, dynamic>) {
            final tradeKey = '${trade['timestamp']}_${trade['result']}';
            if (!seenTrades.contains(tradeKey)) {
              allTrades.add(trade);
              seenTrades.add(tradeKey);
            }
          }
        }
      }
    }

    merged['trades'] = allTrades;
    merged['metadata'] = {
      ...merged['metadata'] as Map<String, dynamic>? ?? {},
      'mergedFrom': sortedSources.length,
      'mergedAt': DateTimeUtils.getCurrentTimestamp(),
    };

    return merged;
  }

  static Map<String, dynamic> createMinimalBackup({
    required List<Trade> trades,
    required RiskManagement riskSettings,
  }) {
    return {
      'version': '1.0.0-minimal',
      'timestamp': DateTimeUtils.getCurrentTimestamp(),
      'riskSettings': {
        'accountBalance': riskSettings.accountBalance,
        'maxDrawdown': riskSettings.maxDrawdown,
        'lossPerTradePercentage': riskSettings.lossPerTradePercentage,
        'currentBalance': riskSettings.currentBalance,
        'isDynamicMaxDrawdown': riskSettings.isDynamicMaxDrawdown,
      },
      'trades': trades
          .map(
            (trade) => {
              'result': trade.result,
              'timestamp': DateTimeUtils.toIso8601(trade.timestamp),
            },
          )
          .toList(),
    };
  }

  static void logServiceOperation(
    String serviceName,
    String operation,
    bool success, {
    String? additionalInfo,
    dynamic error,
  }) {
    final status = success ? '✓' : '✗';
    final buffer = StringBuffer('[$serviceName] $status $operation');

    if (additionalInfo != null) {
      buffer.write(' | $additionalInfo');
    }

    if (!success && error != null) {
      buffer.write(' | Error: $error');
    }

  }

  static Future<ErrorResult<T>> safeServiceOperation<T>(
    String serviceName,
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      logServiceOperation(
        serviceName,
        operationName,
        true,
        additionalInfo: 'Starting',
      );

      final result = await operation();

      logServiceOperation(
        serviceName,
        operationName,
        true,
        additionalInfo: 'Completed',
      );

      return ErrorResult.success(result);
    } catch (e, stackTrace) {
      logServiceOperation(serviceName, operationName, false, error: e);

      return ErrorResult.error(e, stackTrace);
    }
  }

  static Future<T> retryOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    var delay = initialDelay;
    Exception? lastException;

    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (i < maxRetries - 1) {
          await Future.delayed(delay);
          delay *= 2; 
        }
      }
    }

    throw lastException!;
  }

  static int estimateStorageSize(Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      return jsonString.length;
    } catch (e) {
      return 0;
    }
  }

  static String formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  static Map<String, dynamic> createServiceStatusReport({
    required String serviceName,
    required bool isInitialized,
    required bool hasData,
    Map<String, dynamic>? additionalInfo,
  }) {
    return {
      'serviceName': serviceName,
      'isInitialized': isInitialized,
      'hasData': hasData,
      'timestamp': DateTimeUtils.getCurrentTimestamp(),
      'platform': getPlatformInfo(),
      ...additionalInfo ?? {},
    };
  }
}

class ServiceInitializationHelper {
  static const Duration _initializationTimeout = Duration(seconds: 30);

  static Future<ErrorResult<T>> initializeService<T>(
    String serviceName,
    Future<T> Function() initializer,
  ) async {
    try {

      final result = await initializer().timeout(_initializationTimeout);

      return ErrorResult.success(result);
    } on TimeoutException {
      final error = ServiceException(
        'Service initialization timeout after ${_initializationTimeout.inSeconds}s',
        code: 'INITIALIZATION_TIMEOUT',
      );
      return ErrorResult.error(error);
    } catch (e, stackTrace) {
      return ErrorResult.error(e, stackTrace);
    }
  }

  static Future<Map<String, ErrorResult<dynamic>>> initializeServices(
    Map<String, Future<dynamic> Function()> services,
  ) async {
    final results = <String, ErrorResult<dynamic>>{};

    final futures = services.entries.map((entry) async {
      final serviceName = entry.key;
      final initializer = entry.value;
      final result = await initializeService(serviceName, initializer);
      return MapEntry(serviceName, result);
    });

    final completedResults = await Future.wait(futures);

    for (final entry in completedResults) {
      results[entry.key] = entry.value;
    }

    return results;
  }
}
