import 'package:flutter_test/flutter_test.dart';
import 'package:period_track/models/period.dart';

void main() {
  group('Period Model Tests', () {
    late Period testPeriod;

    setUp(() {
      testPeriod = Period(
        id: 'test-period',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        flow: 3, // Medium flow
        symptoms: ['cramps', 'bloating', 'headache'],
        notes: 'Heavy flow on day 2',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 5),
      );
    });

    test('should create period with correct properties', () {
      expect(testPeriod.id, equals('test-period'));
      expect(testPeriod.startDate, equals(DateTime(2024, 1, 1)));
      expect(testPeriod.endDate, equals(DateTime(2024, 1, 5)));
      expect(testPeriod.flow, equals(3));
      expect(testPeriod.symptoms, contains('cramps'));
      expect(testPeriod.symptoms, contains('bloating'));
      expect(testPeriod.symptoms, contains('headache'));
      expect(testPeriod.notes, equals('Heavy flow on day 2'));
    });

    test('should calculate period length correctly', () {
      expect(testPeriod.length, equals(5)); // Jan 1-5 = 5 days
    });

    test('should identify ongoing period correctly', () {
      expect(testPeriod.isOngoing, isFalse);

      final ongoingPeriod = Period(
        id: 'ongoing',
        startDate: DateTime(2024, 1, 1),
        flow: 2,
        symptoms: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(ongoingPeriod.isOngoing, isTrue);
      expect(ongoingPeriod.length, equals(1)); // Default to 1 day when ongoing
    });

    test('should handle different flow intensities', () {
      final lightPeriod = Period(
        id: 'light',
        startDate: DateTime(2024, 1, 1),
        flow: 1,
        symptoms: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(lightPeriod.flow, equals(1));

      final heavyPeriod = Period(
        id: 'heavy',
        startDate: DateTime(2024, 1, 1),
        flow: 5,
        symptoms: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      expect(heavyPeriod.flow, equals(5));
    });

    test('should convert to and from JSON correctly', () {
      final json = testPeriod.toJson();
      final fromJson = Period.fromJson(json);

      expect(fromJson.id, equals(testPeriod.id));
      expect(fromJson.startDate, equals(testPeriod.startDate));
      expect(fromJson.endDate, equals(testPeriod.endDate));
      expect(fromJson.flow, equals(testPeriod.flow));
      expect(fromJson.symptoms, equals(testPeriod.symptoms));
      expect(fromJson.notes, equals(testPeriod.notes));
      expect(fromJson.createdAt, equals(testPeriod.createdAt));
      expect(fromJson.updatedAt, equals(testPeriod.updatedAt));
    });

    test('should handle period without notes', () {
      final periodWithoutNotes = Period(
        id: 'no-notes',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 3),
        flow: 2,
        symptoms: ['fatigue'],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 3),
      );

      expect(periodWithoutNotes.notes, isNull);
      expect(periodWithoutNotes.symptoms, contains('fatigue'));
    });

    test('should handle empty symptoms list', () {
      final periodWithoutSymptoms = Period(
        id: 'no-symptoms',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 4),
        flow: 3,
        symptoms: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 4),
      );

      expect(periodWithoutSymptoms.symptoms, isEmpty);
      expect(periodWithoutSymptoms.length, equals(4));
    });

    test('should handle single day period', () {
      final singleDayPeriod = Period(
        id: 'single-day',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 1),
        flow: 1,
        symptoms: [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(singleDayPeriod.length, equals(1));
      expect(singleDayPeriod.isOngoing, isFalse);
    });
  });
}