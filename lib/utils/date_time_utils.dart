import 'package:flutter/foundation.dart';

/// Utility class for consistent date/time operations
class DateTimeUtils {
  /// Convert DateTime to ISO8601 string (commonly used format)
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parse DateTime from ISO8601 string with error handling
  static DateTime fromIso8601(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      debugPrint('Failed to parse datetime: $dateTimeString - $e');
      rethrow;
    }
  }

  /// Get current timestamp as ISO8601 string
  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }

  /// Get current DateTime
  static DateTime now() {
    return DateTime.now();
  }

  /// Check if a DateTime is within a date range (inclusive)
  static bool isWithinRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(microseconds: 1))) &&
        date.isBefore(end.add(const Duration(microseconds: 1)));
  }

  /// Check if a DateTime is within a date range with day precision
  static bool isWithinDateRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  /// Format DateTime for display (human-readable)
  static String formatForDisplay(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format DateTime for file names (safe characters only)
  static String formatForFileName(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get start of day
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime dateTime) {
    final daysFromMonday = dateTime.weekday - 1;
    return startOfDay(dateTime.subtract(Duration(days: daysFromMonday)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime dateTime) {
    final daysToSunday = 7 - dateTime.weekday;
    return endOfDay(dateTime.add(Duration(days: daysToSunday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime dateTime) {
    final nextMonth = dateTime.month == 12
        ? DateTime(dateTime.year + 1, 1, 1)
        : DateTime(dateTime.year, dateTime.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  /// Get start of year
  static DateTime startOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 12, 31, 23, 59, 59, 999);
  }

  /// Calculate days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Calculate hours between two dates
  static int hoursBetween(DateTime start, DateTime end) {
    return end.difference(start).inHours;
  }

  /// Calculate minutes between two dates
  static int minutesBetween(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if a date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Check if a date is in the current week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startWeek = startOfWeek(now);
    final endWeek = endOfWeek(now);
    return isWithinRange(date, startWeek, endWeek);
  }

  /// Check if a date is in the current month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if a date is in the current year
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  /// Get relative time description (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future time
      final futureDiff = dateTime.difference(now);
      if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} day${futureDiff.inDays == 1 ? '' : 's'}';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} hour${futureDiff.inHours == 1 ? '' : 's'}';
      } else if (futureDiff.inMinutes > 0) {
        return 'in ${futureDiff.inMinutes} minute${futureDiff.inMinutes == 1 ? '' : 's'}';
      } else {
        return 'in a few seconds';
      }
    } else {
      // Past time
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    }
  }

  /// Create database timestamp records
  static Map<String, String> createTimestamps() {
    final now = getCurrentTimestamp();
    return {'created_at': now, 'updated_at': now};
  }

  /// Update timestamp record
  static Map<String, String> updateTimestamp(Map<String, dynamic> existing) {
    return {
      'created_at': existing['created_at'] as String,
      'updated_at': getCurrentTimestamp(),
    };
  }

  /// Validate date range
  static bool isValidDateRange(DateTime start, DateTime end) {
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

  /// Get safe date range (ensure start <= end)
  static (DateTime start, DateTime end) getSafeDateRange(
    DateTime date1,
    DateTime date2,
  ) {
    if (date1.isBefore(date2)) {
      return (date1, date2);
    } else {
      return (date2, date1);
    }
  }

  /// Parse date from various formats with fallback
  static DateTime? tryParseDate(String dateString) {
    try {
      // Try ISO8601 first
      return DateTime.parse(dateString);
    } catch (e) {
      // Try common formats
      final formats = [
        RegExp(r'^\d{4}-\d{2}-\d{2}$'), // YYYY-MM-DD
        RegExp(r'^\d{2}/\d{2}/\d{4}$'), // MM/DD/YYYY
        RegExp(r'^\d{2}-\d{2}-\d{4}$'), // MM-DD-YYYY
      ];

      for (final format in formats) {
        if (format.hasMatch(dateString)) {
          try {
            if (dateString.contains('/')) {
              final parts = dateString.split('/');
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
            } else if (dateString.contains('-') && dateString.length == 10) {
              final parts = dateString.split('-');
              if (parts[0].length == 4) {
                // YYYY-MM-DD
                return DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              } else {
                // MM-DD-YYYY
                return DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
              }
            }
          } catch (e) {
            debugPrint('Failed to parse date format: $dateString - $e');
          }
        }
      }

      debugPrint('Unsupported date format: $dateString');
      return null;
    }
  }
}

/// Extension methods for DateTime to add convenience methods
extension DateTimeExtensions on DateTime {
  /// Convert to ISO8601 string
  String toIso() => DateTimeUtils.toIso8601(this);

  /// Check if this date is today
  bool get isToday => DateTimeUtils.isToday(this);

  /// Check if this date is yesterday
  bool get isYesterday => DateTimeUtils.isYesterday(this);

  /// Check if this date is in the current week
  bool get isThisWeek => DateTimeUtils.isThisWeek(this);

  /// Check if this date is in the current month
  bool get isThisMonth => DateTimeUtils.isThisMonth(this);

  /// Check if this date is in the current year
  bool get isThisYear => DateTimeUtils.isThisYear(this);

  /// Get start of day
  DateTime get startOfDay => DateTimeUtils.startOfDay(this);

  /// Get end of day
  DateTime get endOfDay => DateTimeUtils.endOfDay(this);

  /// Get start of week
  DateTime get startOfWeek => DateTimeUtils.startOfWeek(this);

  /// Get end of week
  DateTime get endOfWeek => DateTimeUtils.endOfWeek(this);

  /// Get start of month
  DateTime get startOfMonth => DateTimeUtils.startOfMonth(this);

  /// Get end of month
  DateTime get endOfMonth => DateTimeUtils.endOfMonth(this);

  /// Get relative time description
  String get relativeTime => DateTimeUtils.getRelativeTime(this);

  /// Format for display
  String get displayFormat => DateTimeUtils.formatForDisplay(this);

  /// Format for file names
  String get fileNameFormat => DateTimeUtils.formatForFileName(this);
}
