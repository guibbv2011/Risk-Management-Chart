
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

class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'StorageException: $message';
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class RepositoryException extends AppException {
  const RepositoryException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'RepositoryException: $message';
}

class ServiceException extends AppException {
  const ServiceException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ServiceException: $message';
}

class ErrorHandler {
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
  }

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

  T get dataOrThrow {
    if (isSuccess) {
      return data!;
    }
    throw error;
  }

  T dataOr(T defaultValue) {
    return isSuccess ? data! : defaultValue;
  }

  ErrorResult<U> map<U>(U Function(T data) transform) {
    if (isSuccess) {
      try {
        return ErrorResult.success(transform(data as T));
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

class ValidationRules {
  static double validateAccountBalance(double? value) {
    return ErrorHandler.validateNumeric(
      'Account balance',
      value,
      min: 0.0,
      customMessage: 'Account balance must be a positive number',
    );
  }

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

  static double validateLossPercentage(double? value) {
    return ErrorHandler.validateNumeric(
      'Loss percentage per trade',
      value,
      min: 0.0,
      max: 100.0,
      customMessage: 'Loss percentage must be between 0 and 100',
    );
  }

  static double validateTradeResult(double? value) {
    return ErrorHandler.validateNumeric(
      'Trade result',
      value,
      customMessage: 'Trade result must be a valid number',
    );
  }
}
