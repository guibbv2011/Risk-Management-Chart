import 'package:flutter/foundation.dart';

/// Custom exception types for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AppException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    return buffer.toString();
  }
}

/// Storage-specific exception
class StorageException extends AppException {
  const StorageException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );

  @override
  String toString() => 'StorageException: $message';
}

/// Validation-specific exception
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );

  @override
  String toString() => 'ValidationException: $message';
}

/// Repository-specific exception
class RepositoryException extends AppException {
  const RepositoryException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );

  @override
  String toString() => 'RepositoryException: $message';
}

/// Service-specific exception
class ServiceException extends AppException {
  const ServiceException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         message,
         code: code,
         originalError: originalError,
         stackTrace: stackTrace,
       );

  @override
  String toString() => 'ServiceException: $message';
}

/// Utility class for consistent error handling patterns
class ErrorHandler {
  /// Log error with consistent formatting
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    String? additionalInfo,
  }) {
    final buffer = StringBuffer('[$context] Error: $error');

    if (additionalInfo != null) {
      buffer.write(' | Info: $additionalInfo');
    }

    debugPrint(buffer.toString());

    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Handle storage operations with consistent error handling
  static Future<T> handleStorageOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final contextInfo = context != null ? '$context - ' : '';
      final errorMessage =
          '${contextInfo}Failed to $operationName: ${e.toString()}';

      logError('Storage', e, stackTrace: stackTrace, additionalInfo: context);

      throw StorageException(
        errorMessage,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle repository operations with consistent error handling
  static Future<T> handleRepositoryOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final contextInfo = context != null ? '$context - ' : '';
      final errorMessage =
          '${contextInfo}Failed to $operationName: ${e.toString()}';

      logError(
        'Repository',
        e,
        stackTrace: stackTrace,
        additionalInfo: context,
      );

      // Re-throw storage exceptions as-is
      if (e is StorageException) {
        rethrow;
      }

      throw RepositoryException(
        errorMessage,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle service operations with consistent error handling
  static Future<T> handleServiceOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final contextInfo = context != null ? '$context - ' : '';
      final errorMessage =
          '${contextInfo}Failed to $operationName: ${e.toString()}';

      logError('Service', e, stackTrace: stackTrace, additionalInfo: context);

      // Re-throw known exceptions as-is
      if (e is AppException) {
        rethrow;
      }

      throw ServiceException(
        errorMessage,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Validate input with consistent error handling
  static T validateInput<T>(
    String fieldName,
    T? value, {
    bool allowNull = false,
    String? customMessage,
  }) {
    if (!allowNull && value == null) {
      throw ValidationException(
        customMessage ?? '$fieldName cannot be null',
        code: 'NULL_VALUE',
      );
    }

    return value!;
  }

  /// Validate numeric input
  static double validateNumeric(
    String fieldName,
    dynamic value, {
    double? min,
    double? max,
    String? customMessage,
  }) {
    if (value == null) {
      throw ValidationException(
        customMessage ?? '$fieldName cannot be null',
        code: 'NULL_VALUE',
      );
    }

    double numValue;
    try {
      numValue = (value as num).toDouble();
    } catch (e) {
      throw ValidationException(
        customMessage ?? '$fieldName must be a valid number',
        code: 'INVALID_NUMBER',
        originalError: e,
      );
    }

    if (min != null && numValue < min) {
      throw ValidationException(
        customMessage ?? '$fieldName must be at least $min',
        code: 'VALUE_TOO_LOW',
      );
    }

    if (max != null && numValue > max) {
      throw ValidationException(
        customMessage ?? '$fieldName must be at most $max',
        code: 'VALUE_TOO_HIGH',
      );
    }

    return numValue;
  }

  /// Validate string input
  static String validateString(
    String fieldName,
    String? value, {
    int? minLength,
    int? maxLength,
    bool allowEmpty = false,
    String? customMessage,
  }) {
    if (value == null) {
      throw ValidationException(
        customMessage ?? '$fieldName cannot be null',
        code: 'NULL_VALUE',
      );
    }

    if (!allowEmpty && value.isEmpty) {
      throw ValidationException(
        customMessage ?? '$fieldName cannot be empty',
        code: 'EMPTY_VALUE',
      );
    }

    if (minLength != null && value.length < minLength) {
      throw ValidationException(
        customMessage ?? '$fieldName must be at least $minLength characters',
        code: 'VALUE_TOO_SHORT',
      );
    }

    if (maxLength != null && value.length > maxLength) {
      throw ValidationException(
        customMessage ?? '$fieldName must be at most $maxLength characters',
        code: 'VALUE_TOO_LONG',
      );
    }

    return value;
  }

  /// Create a safe operation wrapper that doesn't throw
  static Future<ErrorResult<T>> safeOperation<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return ErrorResult.success(result);
    } catch (e, stackTrace) {
      if (context != null) {
        logError(context, e, stackTrace: stackTrace);
      }
      return ErrorResult.error(e, stackTrace);
    }
  }

  /// Format error message consistently
  static String formatErrorMessage(
    String operation,
    dynamic error, {
    String? context,
  }) {
    final buffer = StringBuffer();

    if (context != null) {
      buffer.write('[$context] ');
    }

    buffer.write('Failed to $operation');

    if (error is AppException) {
      buffer.write(': ${error.message}');
    } else {
      buffer.write(': ${error.toString()}');
    }

    return buffer.toString();
  }
}

/// Result wrapper for operations that may fail
class ErrorResult<T> {
  final T? data;
  final dynamic error;
  final StackTrace? stackTrace;
  final bool isSuccess;

  const ErrorResult._({
    this.data,
    this.error,
    this.stackTrace,
    required this.isSuccess,
  });

  factory ErrorResult.success(T data) {
    return ErrorResult._(data: data, isSuccess: true);
  }

  factory ErrorResult.error(dynamic error, [StackTrace? stackTrace]) {
    return ErrorResult._(
      error: error,
      stackTrace: stackTrace,
      isSuccess: false,
    );
  }

  /// Get data or throw error
  T get dataOrThrow {
    if (isSuccess) {
      return data!;
    }
    throw error;
  }

  /// Get data or return default value
  T dataOr(T defaultValue) {
    return isSuccess ? data! : defaultValue;
  }

  /// Transform the data if successful
  ErrorResult<U> map<U>(U Function(T data) transform) {
    if (isSuccess) {
      try {
        return ErrorResult.success(transform(data!));
      } catch (e, stackTrace) {
        return ErrorResult.error(e, stackTrace);
      }
    }
    return ErrorResult.error(error, stackTrace);
  }

  @override
  String toString() {
    return isSuccess ? 'Success($data)' : 'Error($error)';
  }
}

/// Common validation rules
class ValidationRules {
  /// Validate account balance
  static double validateAccountBalance(double? value) {
    return ErrorHandler.validateNumeric(
      'Account balance',
      value,
      min: 0.0,
      customMessage: 'Account balance must be a positive number',
    );
  }

  /// Validate max drawdown
  static double validateMaxDrawdown(double? value, double accountBalance) {
    final validated = ErrorHandler.validateNumeric(
      'Max drawdown',
      value,
      min: 0.0,
      customMessage: 'Max drawdown must be a positive number',
    );

    if (validated > accountBalance) {
      throw ValidationException(
        'Max drawdown cannot exceed account balance',
        code: 'DRAWDOWN_TOO_HIGH',
      );
    }

    return validated;
  }

  /// Validate loss percentage per trade
  static double validateLossPercentage(double? value) {
    return ErrorHandler.validateNumeric(
      'Loss percentage per trade',
      value,
      min: 0.0,
      max: 100.0,
      customMessage: 'Loss percentage must be between 0 and 100',
    );
  }

  /// Validate trade result
  static double validateTradeResult(double? value) {
    return ErrorHandler.validateNumeric(
      'Trade result',
      value,
      customMessage: 'Trade result must be a valid number',
    );
  }
}
