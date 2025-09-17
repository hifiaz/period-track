import 'package:intl/intl.dart';

class DateUtils {
  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get the start of the day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of the day (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Calculate days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Add days to a date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtract days from a date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Get the first day of the month
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the last day of the month
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Format date for display
  static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Format date for short display
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  /// Format date for calendar
  static String formatDateCalendar(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Get relative date string (Today, Yesterday, etc.)
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = startOfDay(now);
    final targetDate = startOfDay(date);
    
    final difference = daysBetween(targetDate, today);
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else if (difference > 0 && difference <= 7) {
      return '$difference days ago';
    } else if (difference < 0 && difference >= -7) {
      return 'In ${-difference} days';
    } else {
      return formatDate(date);
    }
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Get week start (Monday)
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Get week end (Sunday)
  static DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  /// Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Get short day name
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Parse date from string
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get age from birth date
  static int? calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Get dates in range
  static List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = startOfDay(start);
    final endDate = startOfDay(end);
    
    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }

  /// Get business days between dates (excluding weekends)
  static int getBusinessDaysBetween(DateTime start, DateTime end) {
    int businessDays = 0;
    var current = startOfDay(start);
    final endDate = startOfDay(end);
    
    while (current.isBefore(endDate) || isSameDay(current, endDate)) {
      if (current.weekday < 6) { // Monday = 1, Sunday = 7
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return businessDays;
  }

  /// Check if date is weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Get quarter of year
  static int getQuarter(DateTime date) {
    return ((date.month - 1) / 3).floor() + 1;
  }

  /// Get days in month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Check if year is leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}