import 'package:flutter_test/flutter_test.dart';
import 'package:period_track/models/cycle.dart';

void main() {
  group('Cycle Model Tests', () {
    late Cycle testCycle;

    setUp(() {
      testCycle = Cycle(
        id: 'test-cycle',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 28),
        length: 28,
        periodLength: 5,
        symptoms: ['cramps', 'bloating'],
        fertilityWindowStart: DateTime(2024, 1, 12),
        fertilityWindowEnd: DateTime(2024, 1, 16),
        ovulationDate: DateTime(2024, 1, 14),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 28),
      );
    });

    test('should create cycle with correct properties', () {
      expect(testCycle.id, equals('test-cycle'));
      expect(testCycle.startDate, equals(DateTime(2024, 1, 1)));
      expect(testCycle.endDate, equals(DateTime(2024, 1, 28)));
      expect(testCycle.length, equals(28));
      expect(testCycle.periodLength, equals(5));
      expect(testCycle.symptoms, contains('cramps'));
      expect(testCycle.symptoms, contains('bloating'));
    });

    test('should identify if cycle is complete', () {
      expect(testCycle.isComplete, isTrue);
      
      final incompleteCycle = Cycle(
        id: 'incomplete',
        startDate: DateTime(2024, 2, 1),
        length: 28,
        periodLength: 5,
        symptoms: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(incompleteCycle.isComplete, isFalse);
    });

    test('should calculate cycle phase correctly', () {
      // Menstrual phase (days 1-5)
      expect(testCycle.getCyclePhase(DateTime(2024, 1, 3)), equals('Menstrual'));
      
      // Follicular phase (days 6-13)
      expect(testCycle.getCyclePhase(DateTime(2024, 1, 10)), equals('Follicular'));
      
      // Ovulation phase (days 14-15)
      expect(testCycle.getCyclePhase(DateTime(2024, 1, 14)), equals('Ovulation'));
      
      // Luteal phase (days 16+)
      expect(testCycle.getCyclePhase(DateTime(2024, 1, 20)), equals('Luteal'));
      
      // Previous cycle
      expect(testCycle.getCyclePhase(DateTime(2023, 12, 31)), equals('Previous Cycle'));
    });

    test('should identify fertility window correctly', () {
      // Inside fertility window
      expect(testCycle.isInFertilityWindow(DateTime(2024, 1, 14)), isTrue);
      
      // Outside fertility window
      expect(testCycle.isInFertilityWindow(DateTime(2024, 1, 5)), isFalse);
      expect(testCycle.isInFertilityWindow(DateTime(2024, 1, 25)), isFalse);
    });

    test('should convert to and from JSON correctly', () {
      final json = testCycle.toJson();
      final fromJson = Cycle.fromJson(json);
      
      expect(fromJson.id, equals(testCycle.id));
      expect(fromJson.startDate, equals(testCycle.startDate));
      expect(fromJson.endDate, equals(testCycle.endDate));
      expect(fromJson.length, equals(testCycle.length));
      expect(fromJson.periodLength, equals(testCycle.periodLength));
      expect(fromJson.symptoms, equals(testCycle.symptoms));
    });

    test('should handle cycle without fertility window', () {
      final cycleWithoutFertility = Cycle(
        id: 'no-fertility',
        startDate: DateTime(2024, 1, 1),
        length: 28,
        periodLength: 5,
        symptoms: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(cycleWithoutFertility.isInFertilityWindow(DateTime(2024, 1, 14)), isFalse);
    });
  });
}