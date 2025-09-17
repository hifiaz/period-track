import 'dart:math';

import '../models/period.dart';
import '../models/user.dart';

class PredictionService {
  // Calculate average cycle length from historical data
  static int calculateAverageCycleLength(List<Period> periods) {
    if (periods.length < 2) return 28; // Default cycle length
    
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    List<int> cycleLengths = [];
    for (int i = 1; i < periods.length; i++) {
      final cycleLength = periods[i].startDate.difference(periods[i - 1].startDate).inDays;
      if (cycleLength >= 21 && cycleLength <= 35) { // Valid cycle length range
        cycleLengths.add(cycleLength);
      }
    }
    
    if (cycleLengths.isEmpty) return 28;
    
    final sum = cycleLengths.reduce((a, b) => a + b);
    return (sum / cycleLengths.length).round();
  }

  // Calculate average period length from historical data
  static int calculateAveragePeriodLength(List<Period> periods) {
    if (periods.isEmpty) return 5; // Default period length
    
    final completedPeriods = periods.where((p) => p.endDate != null).toList();
    if (completedPeriods.isEmpty) return 5;
    
    final lengths = completedPeriods.map((p) => p.length).toList();
    final sum = lengths.reduce((a, b) => a + b);
    return (sum / lengths.length).round();
  }

  // Predict next period date
  static DateTime? predictNextPeriod(List<Period> periods, User user) {
    if (periods.isEmpty) return null;
    
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    final lastPeriod = periods.first;
    
    final avgCycleLength = calculateAverageCycleLength(periods);
    return lastPeriod.startDate.add(Duration(days: avgCycleLength));
  }

  // Predict multiple future periods
  static List<DateTime> predictFuturePeriods(List<Period> periods, User user, int monthsAhead) {
    final nextPeriod = predictNextPeriod(periods, user);
    if (nextPeriod == null) return [];
    
    final avgCycleLength = calculateAverageCycleLength(periods);
    final futurePeriods = <DateTime>[];
    
    DateTime currentPrediction = nextPeriod;
    final endDate = DateTime.now().add(Duration(days: monthsAhead * 30));
    
    while (currentPrediction.isBefore(endDate)) {
      futurePeriods.add(currentPrediction);
      currentPrediction = currentPrediction.add(Duration(days: avgCycleLength));
    }
    
    return futurePeriods;
  }

  // Predict ovulation date
  static DateTime? predictOvulation(List<Period> periods, User user) {
    final nextPeriod = predictNextPeriod(periods, user);
    if (nextPeriod == null) return null;
    
    // Ovulation typically occurs 14 days before the next period
    return nextPeriod.subtract(const Duration(days: 14));
  }

  // Calculate fertility window
  static Map<String, DateTime?> calculateFertilityWindow(List<Period> periods, User user) {
    final ovulationDate = predictOvulation(periods, user);
    if (ovulationDate == null) {
      return {'start': null, 'end': null};
    }
    
    // Fertility window: 5 days before ovulation + ovulation day + 1 day after
    return {
      'start': ovulationDate.subtract(const Duration(days: 5)),
      'end': ovulationDate.add(const Duration(days: 1)),
    };
  }

  // Get cycle phase for a specific date
  static String getCyclePhase(DateTime date, List<Period> periods, User user) {
    if (periods.isEmpty) return 'Unknown';
    
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    
    // Find the most recent period before or on the given date
    Period? relevantPeriod;
    for (final period in periods) {
      if (period.startDate.isBefore(date.add(const Duration(days: 1)))) {
        relevantPeriod = period;
        break;
      }
    }
    
    if (relevantPeriod == null) return 'Unknown';
    
    final daysSinceStart = date.difference(relevantPeriod.startDate).inDays + 1;
    final avgPeriodLength = calculateAveragePeriodLength(periods);
    final avgCycleLength = calculateAverageCycleLength(periods);
    
    if (daysSinceStart <= avgPeriodLength) {
      return 'Menstrual';
    } else if (daysSinceStart <= 13) {
      return 'Follicular';
    } else if (daysSinceStart <= 15) {
      return 'Ovulation';
    } else if (daysSinceStart <= avgCycleLength) {
      return 'Luteal';
    } else {
      return 'Pre-menstrual';
    }
  }

  // Calculate cycle regularity
  static Map<String, dynamic> calculateCycleRegularity(List<Period> periods) {
    if (periods.length < 3) {
      return {
        'regularity': 'Insufficient data',
        'variance': 0.0,
        'isRegular': false,
      };
    }
    
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));
    
    List<int> cycleLengths = [];
    for (int i = 1; i < periods.length; i++) {
      final cycleLength = periods[i].startDate.difference(periods[i - 1].startDate).inDays;
      cycleLengths.add(cycleLength);
    }
    
    final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance = cycleLengths.map((length) => (length - average) * (length - average)).reduce((a, b) => a + b) / cycleLengths.length;
    final standardDeviation = sqrt(variance);
    
    String regularity;
    bool isRegular;
    
    if (standardDeviation <= 2) {
      regularity = 'Very Regular';
      isRegular = true;
    } else if (standardDeviation <= 4) {
      regularity = 'Regular';
      isRegular = true;
    } else if (standardDeviation <= 7) {
      regularity = 'Somewhat Irregular';
      isRegular = false;
    } else {
      regularity = 'Irregular';
      isRegular = false;
    }
    
    return {
      'regularity': regularity,
      'variance': variance,
      'standardDeviation': standardDeviation,
      'isRegular': isRegular,
      'averageLength': average.round(),
    };
  }

  // Predict period end date
  static DateTime? predictPeriodEnd(Period period, List<Period> periods) {
    if (period.endDate != null) return period.endDate;
    
    final avgPeriodLength = calculateAveragePeriodLength(periods);
    return period.startDate.add(Duration(days: avgPeriodLength - 1));
  }

  // Calculate pregnancy probability
  static double calculatePregnancyProbability(DateTime date, List<Period> periods, User user) {
    final fertilityWindow = calculateFertilityWindow(periods, user);
    final start = fertilityWindow['start'];
    final end = fertilityWindow['end'];
    
    if (start == null || end == null) return 0.0;
    
    if (date.isBefore(start) || date.isAfter(end)) return 0.0;
    
    final ovulationDate = predictOvulation(periods, user);
    if (ovulationDate == null) return 0.0;
    
    final daysDifference = (date.difference(ovulationDate).inDays).abs();
    
    // Highest probability on ovulation day, decreasing as we move away
    if (daysDifference == 0) return 0.25; // 25% on ovulation day
    if (daysDifference == 1) return 0.20; // 20% one day before/after
    if (daysDifference == 2) return 0.15; // 15% two days before/after
    if (daysDifference <= 5) return 0.10; // 10% within fertility window
    
    return 0.0;
  }

  // Get insights based on cycle data
  static List<String> generateInsights(List<Period> periods, User user) {
    final insights = <String>[];
    
    if (periods.length < 2) {
      insights.add('Track more cycles to get personalized insights');
      return insights;
    }
    
    final regularity = calculateCycleRegularity(periods);
    final avgCycleLength = calculateAverageCycleLength(periods);
    final avgPeriodLength = calculateAveragePeriodLength(periods);
    
    // Cycle regularity insights
    if (regularity['isRegular']) {
      insights.add('Your cycles are ${regularity['regularity'].toLowerCase()} with an average length of ${avgCycleLength} days');
    } else {
      insights.add('Your cycles are ${regularity['regularity'].toLowerCase()}. Consider tracking symptoms to identify patterns');
    }
    
    // Period length insights
    if (avgPeriodLength < 3) {
      insights.add('Your periods are shorter than average. This is usually normal but mention it to your doctor if you\'re concerned');
    } else if (avgPeriodLength > 7) {
      insights.add('Your periods are longer than average. Consider discussing this with your healthcare provider');
    } else {
      insights.add('Your period length of ${avgPeriodLength} days is within the normal range');
    }
    
    // Cycle length insights
    if (avgCycleLength < 21) {
      insights.add('Your cycles are shorter than typical. This could be normal for you, but consider consulting a healthcare provider');
    } else if (avgCycleLength > 35) {
      insights.add('Your cycles are longer than typical. This might be normal for you, but worth discussing with a doctor');
    }
    
    return insights;
  }
}