import 'package:flutter_test/flutter_test.dart';
import 'package:period_track/services/prediction_service.dart';
import 'package:period_track/models/period.dart';
import 'package:period_track/models/user.dart';

void main() {
  group('PredictionService Tests', () {
    late List<Period> testPeriods;
    late User testUser;

    setUp(() {
      testUser = User(
        id: 'test-user',
        name: 'Test User',
        averageCycleLength: 28,
        averagePeriodLength: 5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      testPeriods = [
        Period(
          id: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          flow: 3,
          symptoms: [],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 5),
        ),
        Period(
          id: '2',
          startDate: DateTime(2024, 1, 29),
          endDate: DateTime(2024, 2, 2),
          flow: 2,
          symptoms: [],
          createdAt: DateTime(2024, 1, 29),
          updatedAt: DateTime(2024, 2, 2),
        ),
        Period(
          id: '3',
          startDate: DateTime(2024, 2, 26),
          endDate: DateTime(2024, 3, 1),
          flow: 4,
          symptoms: [],
          createdAt: DateTime(2024, 2, 26),
          updatedAt: DateTime(2024, 3, 1),
        ),
      ];
    });

    test('should calculate average cycle length correctly', () {
      final avgLength = PredictionService.calculateAverageCycleLength(testPeriods);
      // Jan 1 to Jan 29 = 28 days, Jan 29 to Feb 26 = 28 days
      expect(avgLength, equals(28));
    });

    test('should return default cycle length for insufficient data', () {
      final singlePeriod = [testPeriods.first];
      final avgLength = PredictionService.calculateAverageCycleLength(singlePeriod);
      expect(avgLength, equals(28)); // Default
    });

    test('should calculate average period length correctly', () {
      final avgLength = PredictionService.calculateAveragePeriodLength(testPeriods);
      // All periods are 5 days long
      expect(avgLength, equals(5));
    });

    test('should return default period length for empty data', () {
      final avgLength = PredictionService.calculateAveragePeriodLength([]);
      expect(avgLength, equals(5)); // Default
    });

    test('should predict next period date correctly', () {
      final nextPeriod = PredictionService.predictNextPeriod(testPeriods, testUser);
      expect(nextPeriod, isNotNull);
      
      // Last period was Feb 26, next should be around Mar 25 (28 days later)
      final expectedDate = DateTime(2024, 3, 25);
      expect(nextPeriod!.day, equals(expectedDate.day));
      expect(nextPeriod.month, equals(expectedDate.month));
    });

    test('should return null for next period with no data', () {
      final nextPeriod = PredictionService.predictNextPeriod([], testUser);
      expect(nextPeriod, isNull);
    });

    test('should predict multiple future periods', () {
      final futurePeriods = PredictionService.predictFuturePeriods(testPeriods, testUser, 3);
      expect(futurePeriods, isNotEmpty);
      expect(futurePeriods.length, greaterThanOrEqualTo(2)); // At least 2-3 periods in 3 months
      
      // Check that periods are spaced correctly
      if (futurePeriods.length >= 2) {
        final daysBetween = futurePeriods[1].difference(futurePeriods[0]).inDays;
        expect(daysBetween, equals(28)); // Should match average cycle length
      }
    });

    test('should predict ovulation date correctly', () {
      final ovulationDate = PredictionService.predictOvulation(testPeriods, testUser);
      expect(ovulationDate, isNotNull);
      
      // Ovulation should be 14 days before next period
      final nextPeriod = PredictionService.predictNextPeriod(testPeriods, testUser);
      final expectedOvulation = nextPeriod!.subtract(const Duration(days: 14));
      expect(ovulationDate!.day, equals(expectedOvulation.day));
      expect(ovulationDate.month, equals(expectedOvulation.month));
    });

    test('should calculate fertility window correctly', () {
      final fertilityWindow = PredictionService.calculateFertilityWindow(testPeriods, testUser);
      expect(fertilityWindow['start'], isNotNull);
      expect(fertilityWindow['end'], isNotNull);
      
      final start = fertilityWindow['start']!;
      final end = fertilityWindow['end']!;
      
      // Fertility window should be 7 days long (5 before + ovulation + 1 after)
      final windowLength = end.difference(start).inDays + 1;
      expect(windowLength, equals(7));
    });

    test('should handle invalid cycle lengths', () {
      final invalidPeriods = [
        Period(
          id: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          flow: 3,
          symptoms: [],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 5),
        ),
        Period(
          id: '2',
          startDate: DateTime(2024, 1, 10), // Only 9 days apart - too short
          endDate: DateTime(2024, 1, 14),
          flow: 2,
          symptoms: [],
          createdAt: DateTime(2024, 1, 10),
          updatedAt: DateTime(2024, 1, 14),
        ),
      ];

      final avgLength = PredictionService.calculateAverageCycleLength(invalidPeriods);
      expect(avgLength, equals(28)); // Should return default for invalid cycles
    });

    test('should handle periods without end dates', () {
      final ongoingPeriods = [
        Period(
          id: '1',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          flow: 3,
          symptoms: [],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 5),
        ),
        Period(
          id: '2',
          startDate: DateTime(2024, 1, 29),
          // No end date - ongoing period
          flow: 2,
          symptoms: [],
          createdAt: DateTime(2024, 1, 29),
          updatedAt: DateTime(2024, 1, 29),
        ),
      ];

      final avgPeriodLength = PredictionService.calculateAveragePeriodLength(ongoingPeriods);
      expect(avgPeriodLength, equals(5)); // Should only count completed periods
    });

    test('should sort periods correctly before calculations', () {
      // Test with unsorted periods
      final unsortedPeriods = [
        testPeriods[2], // Feb 26
        testPeriods[0], // Jan 1
        testPeriods[1], // Jan 29
      ];

      final avgLength = PredictionService.calculateAverageCycleLength(unsortedPeriods);
      expect(avgLength, equals(28)); // Should still calculate correctly
    });
  });
}