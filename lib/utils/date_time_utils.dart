
class DateTimeUtils {
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static DateTime fromIso8601(String dateTimeString) {
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      rethrow;
    }
  }

  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }

  static DateTime now() {
    return DateTime.now();
  }

  static bool isWithinRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(microseconds: 1))) &&
        date.isBefore(end.add(const Duration(microseconds: 1)));
  }

  static bool isWithinDateRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  static String formatForDisplay(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatForFileName(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

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

  static DateTime startOfWeek(DateTime dateTime) {
    final daysFromMonday = dateTime.weekday - 1;
    return startOfDay(dateTime.subtract(Duration(days: daysFromMonday)));
  }

  static DateTime endOfWeek(DateTime dateTime) {
    final daysToSunday = 7 - dateTime.weekday;
    return endOfDay(dateTime.add(Duration(days: daysToSunday)));
  }

  static DateTime startOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  static DateTime endOfMonth(DateTime dateTime) {
    final nextMonth = dateTime.month == 12
        ? DateTime(dateTime.year + 1, 1, 1)
        : DateTime(dateTime.year, dateTime.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  static DateTime startOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 1, 1);
  }

  static DateTime endOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 12, 31, 23, 59, 59, 999);
  }

  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  static int hoursBetween(DateTime start, DateTime end) {
    return end.difference(start).inHours;
  }

  static int minutesBetween(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startWeek = startOfWeek(now);
    final endWeek = endOfWeek(now);
    return isWithinRange(date, startWeek, endWeek);
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
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

  static Map<String, String> createTimestamps() {
    final now = getCurrentTimestamp();
    return {'created_at': now, 'updated_at': now};
  }

  static Map<String, String> updateTimestamp(Map<String, dynamic> existing) {
    return {
      'created_at': existing['created_at'] as String,
      'updated_at': getCurrentTimestamp(),
    };
  }

  static bool isValidDateRange(DateTime start, DateTime end) {
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

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

  static DateTime? tryParseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      final formats = [
        RegExp(r'^\d{4}-\d{2}-\d{2}$'), 
        RegExp(r'^\d{2}/\d{2}/\d{4}$'), 
        RegExp(r'^\d{2}-\d{2}-\d{4}$'), 
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
                return DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              } else {
                return DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
              }
            }
          } catch (e) {
            rethrow;
          }
        }
      }

      return null;
    }
  }
}

extension DateTimeExtensions on DateTime {
  String toIso() => DateTimeUtils.toIso8601(this);

  bool get isToday => DateTimeUtils.isToday(this);

  bool get isYesterday => DateTimeUtils.isYesterday(this);

  bool get isThisWeek => DateTimeUtils.isThisWeek(this);

  bool get isThisMonth => DateTimeUtils.isThisMonth(this);

  bool get isThisYear => DateTimeUtils.isThisYear(this);

  DateTime get startOfDay => DateTimeUtils.startOfDay(this);

  DateTime get endOfDay => DateTimeUtils.endOfDay(this);

  DateTime get startOfWeek => DateTimeUtils.startOfWeek(this);

  DateTime get endOfWeek => DateTimeUtils.endOfWeek(this);

  DateTime get startOfMonth => DateTimeUtils.startOfMonth(this);

  DateTime get endOfMonth => DateTimeUtils.endOfMonth(this);

  String get relativeTime => DateTimeUtils.getRelativeTime(this);

  String get displayFormat => DateTimeUtils.formatForDisplay(this);

  String get fileNameFormat => DateTimeUtils.formatForFileName(this);
}
