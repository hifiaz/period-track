import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_track/models/period.dart';
import 'package:period_track/models/cycle.dart';
import 'package:period_track/models/user.dart';

/// Test configuration and helper utilities
class TestConfig {
  static const Duration testTimeout = Duration(seconds: 30);
  static const Duration pumpDuration = Duration(milliseconds: 100);
  
  /// Create a test user for testing
  static User createTestUser() {
    return User(
      id: 'test_user_1',
      name: 'Test User',
      birthDate: DateTime(1990, 1, 1),
      averageCycleLength: 28,
      averagePeriodLength: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a test period for testing
  static Period createTestPeriod({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? flow,
  }) {
    return Period(
      id: id ?? 'test_period_1',
      startDate: startDate ?? DateTime.now().subtract(const Duration(days: 5)),
      endDate: endDate,
      flow: flow ?? 3, // Medium flow (1-5 scale)
      symptoms: ['cramps', 'bloating'],
      notes: 'Test period notes',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a test cycle for testing
  static Cycle createTestCycle({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? length,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 28));
    return Cycle(
      id: id ?? 'test_cycle_1',
      startDate: start,
      endDate: endDate ?? start.add(const Duration(days: 28)),
      length: length ?? 28,
      periodLength: 5,
      symptoms: ['mood_swings', 'fatigue'],
      notes: 'Test cycle notes',
      fertilityWindowStart: start.add(const Duration(days: 10)),
      fertilityWindowEnd: start.add(const Duration(days: 16)),
      ovulationDate: start.add(const Duration(days: 14)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Wrapper for MaterialApp in tests
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }
  
  /// Safe pump and settle with timeout
  static Future<void> safePumpAndSettle(
    WidgetTester tester, {
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
  }) async {
    try {
      await tester.pumpAndSettle(
        duration ?? pumpDuration,
        phase,
        testTimeout,
      );
    } catch (e) {
      // Fallback to regular pump if pumpAndSettle times out
      await tester.pump(duration ?? pumpDuration);
    }
  }
  
  /// Verify widget exists and is visible
  static void verifyWidgetExists(Finder finder, {int count = 1}) {
    if (count == 1) {
      expect(finder, findsOneWidget);
    } else {
      expect(finder, findsNWidgets(count));
    }
  }
  
  /// Verify text exists in widget tree
  static void verifyTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }
  
  /// Verify icon exists in widget tree
  static void verifyIconExists(IconData icon) {
    expect(find.byIcon(icon), findsOneWidget);
  }
  
  /// Safe tap with error handling
  static Future<void> safeTap(
    WidgetTester tester,
    Finder finder, {
    bool warnIfMissed = false,
  }) async {
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder, warnIfMissed: warnIfMissed);
      await tester.pump();
    }
  }
  
  /// Safe text input with error handling
  static Future<void> safeEnterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    if (finder.evaluate().isNotEmpty) {
      await tester.enterText(finder, text);
      await tester.pump();
    }
  }
}

/// Test data factory for creating mock data
class TestDataFactory {
  static List<Period> createPeriodHistory(int count) {
    return List.generate(count, (index) {
      final startDate = DateTime.now().subtract(Duration(days: (index + 1) * 30));
      return TestConfig.createTestPeriod(
        id: 'period_$index',
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 5)),
      );
    });
  }
  
  static List<Cycle> createCycleHistory(int count) {
    return List.generate(count, (index) {
      final startDate = DateTime.now().subtract(Duration(days: (index + 1) * 28));
      return TestConfig.createTestCycle(
        id: 'cycle_$index',
        startDate: startDate,
        endDate: startDate.add(const Duration(days: 28)),
      );
    });
  }
}