import 'dart:math';
import '../models/period.dart';
import 'date_utils.dart' as date_utils;

class CycleUtils {
  /// Calculate cycle length from periods
  static int calculateCycleLength(List<Period> periods) {
    if (periods.length < 2) return 28; // Default cycle length
    
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    final cycleLengths = <int>[];
    for (int i = 1; i < periods.length; i++) {
      final length = date_utils.DateUtils.daysBetween(
        periods[i - 1].startDate,
        periods[i].startDate,
      );
      if (length > 0 && length <= 45) { // Valid cycle length range
        cycleLengths.add(length);
      }
    }
    
    if (cycleLengths.isEmpty) return 28;
    
    // Calculate average
    final sum = cycleLengths.reduce((a, b) => a + b);
    return (sum / cycleLengths.length).round();
  }

  /// Calculate average period length
  static int calculatePeriodLength(List<Period> periods) {
    if (periods.isEmpty) return 5; // Default period length
    
    final lengths = periods
        .where((p) => p.endDate != null)
        .map((p) => date_utils.DateUtils.daysBetween(p.startDate, p.endDate!) + 1)
        .where((length) => length > 0 && length <= 10) // Valid period length range
        .toList();
    
    if (lengths.isEmpty) return 5;
    
    final sum = lengths.reduce((a, b) => a + b);
    return (sum / lengths.length).round();
  }

  /// Predict next period date
  static DateTime predictNextPeriod(List<Period> periods, int averageCycleLength) {
    if (periods.isEmpty) {
      return DateTime.now().add(Duration(days: averageCycleLength));
    }
    
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    final lastPeriod = periods.first;
    
    return lastPeriod.startDate.add(Duration(days: averageCycleLength));
  }

  /// Predict multiple future periods
  static List<DateTime> predictFuturePeriods(
    List<Period> periods,
    int averageCycleLength,
    int count,
  ) {
    final predictions = <DateTime>[];
    var nextDate = predictNextPeriod(periods, averageCycleLength);
    
    for (int i = 0; i < count; i++) {
      predictions.add(nextDate);
      nextDate = nextDate.add(Duration(days: averageCycleLength));
    }
    
    return predictions;
  }

  /// Calculate ovulation date
  static DateTime? calculateOvulationDate(DateTime periodStart, int cycleLength) {
    // Ovulation typically occurs 14 days before the next period
    final ovulationDay = cycleLength - 14;
    if (ovulationDay <= 0) return null;
    
    return periodStart.add(Duration(days: ovulationDay));
  }

  /// Calculate fertility window
  static Map<String, DateTime?> calculateFertilityWindow(
    DateTime periodStart,
    int cycleLength,
  ) {
    final ovulation = calculateOvulationDate(periodStart, cycleLength);
    if (ovulation == null) {
      return {'start': null, 'end': null, 'ovulation': null};
    }
    
    // Fertility window: 5 days before ovulation + ovulation day + 1 day after
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));
    
    return {
      'start': fertileStart,
      'end': fertileEnd,
      'ovulation': ovulation,
    };
  }

  /// Get current cycle phase
  static String getCurrentCyclePhase(
    DateTime periodStart,
    int cycleLength,
    DateTime currentDate,
  ) {
    final dayInCycle = date_utils.DateUtils.daysBetween(periodStart, currentDate) + 1;
    
    if (dayInCycle <= 0) return 'Unknown';
    if (dayInCycle > cycleLength) return 'Late';
    
    final ovulationDay = cycleLength - 14;
    
    if (dayInCycle <= 5) {
      return 'Menstrual';
    } else if (dayInCycle <= ovulationDay - 3) {
      return 'Follicular';
    } else if (dayInCycle <= ovulationDay + 1) {
      return 'Ovulation';
    } else {
      return 'Luteal';
    }
  }

  /// Calculate cycle regularity score (0-100)
  static int calculateRegularityScore(List<Period> periods) {
    if (periods.length < 3) return 0;
    
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    final cycleLengths = <int>[];
    for (int i = 1; i < periods.length; i++) {
      final length = date_utils.DateUtils.daysBetween(
        periods[i - 1].startDate,
        periods[i].startDate,
      );
      if (length > 0 && length <= 45) {
        cycleLengths.add(length);
      }
    }
    
    if (cycleLengths.length < 2) return 0;
    
    // Calculate standard deviation
    final mean = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance = cycleLengths
        .map((length) => pow(length - mean, 2))
        .reduce((a, b) => a + b) / cycleLengths.length;
    final standardDeviation = sqrt(variance);
    
    // Convert to score (lower deviation = higher score)
    final maxDeviation = 7.0; // 7 days deviation = 0% regularity
    final score = max(0, 100 - (standardDeviation / maxDeviation * 100));
    
    return score.round();
  }

  /// Check if period is late
  static bool isPeriodLate(
    List<Period> periods,
    int averageCycleLength,
    DateTime currentDate,
  ) {
    if (periods.isEmpty) return false;
    
    final expectedDate = predictNextPeriod(periods, averageCycleLength);
    final daysLate = date_utils.DateUtils.daysBetween(expectedDate, currentDate);
    
    return daysLate > 3; // Consider late after 3 days
  }

  /// Get days until next period
  static int getDaysUntilNextPeriod(
    List<Period> periods,
    int averageCycleLength,
    DateTime currentDate,
  ) {
    final nextPeriod = predictNextPeriod(periods, averageCycleLength);
    return date_utils.DateUtils.daysBetween(currentDate, nextPeriod);
  }

  /// Check if date is in period
  static bool isDateInPeriod(DateTime date, List<Period> periods) {
    return periods.any((period) {
      final start = date_utils.DateUtils.startOfDay(period.startDate);
      final end = period.endDate != null
          ? date_utils.DateUtils.endOfDay(period.endDate!)
          : date_utils.DateUtils.endOfDay(period.startDate.add(const Duration(days: 5)));
      
      return date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
             date.isBefore(end.add(const Duration(milliseconds: 1)));
    });
  }

  /// Check if date is in fertility window
  static bool isDateInFertilityWindow(
    DateTime date,
    List<Period> periods,
    int averageCycleLength,
  ) {
    for (final period in periods) {
      final fertility = calculateFertilityWindow(period.startDate, averageCycleLength);
      final start = fertility['start'];
      final end = fertility['end'];
      
      if (start != null && end != null) {
        if (date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            date.isBefore(end.add(const Duration(milliseconds: 1)))) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Check if date is ovulation day
  static bool isOvulationDay(
    DateTime date,
    List<Period> periods,
    int averageCycleLength,
  ) {
    for (final period in periods) {
      final ovulation = calculateOvulationDate(period.startDate, averageCycleLength);
      if (ovulation != null && date_utils.DateUtils.isSameDay(date, ovulation)) {
        return true;
      }
    }
    
    return false;
  }

  /// Generate cycle insights
  static List<String> generateCycleInsights(
    List<Period> periods,
    int averageCycleLength,
    int averagePeriodLength,
  ) {
    final insights = <String>[];
    
    if (periods.isEmpty) {
      insights.add('Start tracking your periods to get personalized insights!');
      return insights;
    }
    
    // Regularity insight
    final regularityScore = calculateRegularityScore(periods);
    if (regularityScore >= 80) {
      insights.add('Your cycles are very regular! This makes predictions more accurate.');
    } else if (regularityScore >= 60) {
      insights.add('Your cycles are fairly regular with some variation.');
    } else {
      insights.add('Your cycles show some irregularity. Consider tracking symptoms for better insights.');
    }
    
    // Cycle length insight
    if (averageCycleLength < 21) {
      insights.add('Your cycles are shorter than average. Consider consulting a healthcare provider.');
    } else if (averageCycleLength > 35) {
      insights.add('Your cycles are longer than average. This can be normal but worth discussing with a doctor.');
    } else {
      insights.add('Your cycle length is within the normal range.');
    }
    
    // Period length insight
    if (averagePeriodLength < 3) {
      insights.add('Your periods are quite short. This can be normal but worth monitoring.');
    } else if (averagePeriodLength > 7) {
      insights.add('Your periods are longer than average. Consider tracking flow intensity.');
    } else {
      insights.add('Your period length is within the normal range.');
    }
    
    // Next period prediction
    final daysUntilNext = getDaysUntilNextPeriod(periods, averageCycleLength, DateTime.now());
    if (daysUntilNext <= 3) {
      insights.add('Your next period is expected within the next few days.');
    } else if (daysUntilNext <= 7) {
      insights.add('Your next period is expected within a week.');
    }
    
    return insights;
  }

  /// Calculate cycle statistics
  static Map<String, dynamic> calculateCycleStatistics(List<Period> periods) {
    if (periods.isEmpty) {
      return {
        'totalCycles': 0,
        'averageCycleLength': 28,
        'shortestCycle': 0,
        'longestCycle': 0,
        'regularityScore': 0,
        'totalDaysTracked': 0,
      };
    }
    
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    final cycleLengths = <int>[];
    for (int i = 1; i < periods.length; i++) {
      final length = date_utils.DateUtils.daysBetween(
        periods[i - 1].startDate,
        periods[i].startDate,
      );
      if (length > 0 && length <= 45) {
        cycleLengths.add(length);
      }
    }
    
    final totalDaysTracked = periods.isNotEmpty
        ? date_utils.DateUtils.daysBetween(periods.first.startDate, DateTime.now())
        : 0;
    
    return {
      'totalCycles': cycleLengths.length,
      'averageCycleLength': cycleLengths.isNotEmpty
          ? (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length).round()
          : 28,
      'shortestCycle': cycleLengths.isNotEmpty ? cycleLengths.reduce(min) : 0,
      'longestCycle': cycleLengths.isNotEmpty ? cycleLengths.reduce(max) : 0,
      'regularityScore': calculateRegularityScore(periods),
      'totalDaysTracked': totalDaysTracked,
    };
  }
}