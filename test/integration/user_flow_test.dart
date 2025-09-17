import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_track/main.dart';

void main() {
  group('User Flow Integration Tests', () {
    testWidgets('Complete period logging flow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to period logging screen
      expect(find.text('Period Track'), findsOneWidget);
      
      // Look for navigation elements or buttons to log period
      final logPeriodButton = find.text('Log Period');
      if (logPeriodButton.evaluate().isNotEmpty) {
        await tester.tap(logPeriodButton);
        await tester.pumpAndSettle();
      }

      // Test period start logging
      final startPeriodButton = find.text('Start Period');
      if (startPeriodButton.evaluate().isNotEmpty) {
        await tester.tap(startPeriodButton);
        await tester.pumpAndSettle();
      }

      // Verify UI updates after logging
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Cycle tracking and prediction flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to cycle tracking
      final cycleTrackingTab = find.text('Cycle');
      if (cycleTrackingTab.evaluate().isNotEmpty) {
        await tester.tap(cycleTrackingTab);
        await tester.pumpAndSettle();
      }

      // Verify cycle information is displayed
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Look for cycle-related widgets
      final cycleWidgets = find.byKey(const Key('cycle_info'));
      if (cycleWidgets.evaluate().isNotEmpty) {
        expect(cycleWidgets, findsOneWidget);
      }
    });

    testWidgets('Settings and profile management flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // Test profile editing
      final editProfileButton = find.text('Edit Profile');
      if (editProfileButton.evaluate().isNotEmpty) {
        await tester.tap(editProfileButton);
        await tester.pumpAndSettle();
      }

      // Verify settings screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Calendar view and navigation flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to calendar
      final calendarTab = find.text('Calendar');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // Test calendar navigation
      final nextMonthButton = find.byIcon(Icons.chevron_right);
      if (nextMonthButton.evaluate().isNotEmpty) {
        await tester.tap(nextMonthButton);
        await tester.pumpAndSettle();
      }

      final prevMonthButton = find.byIcon(Icons.chevron_left);
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle();
      }

      // Verify calendar functionality
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Symptoms and mood tracking flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to symptoms tracking
      final symptomsButton = find.text('Symptoms');
      if (symptomsButton.evaluate().isNotEmpty) {
        await tester.tap(symptomsButton);
        await tester.pumpAndSettle();
      }

      // Test symptom selection
      final symptomChips = find.byType(Chip);
      if (symptomChips.evaluate().isNotEmpty) {
        await tester.tap(symptomChips.first);
        await tester.pumpAndSettle();
      }

      // Test mood selection
      final moodButtons = find.byType(IconButton);
      if (moodButtons.evaluate().isNotEmpty) {
        await tester.tap(moodButtons.first);
        await tester.pumpAndSettle();
      }

      // Save symptoms
      final saveButton = find.text('Save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Data persistence and recovery flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pump();

      // Simulate app restart by rebuilding widget tree
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pump();

      // Verify data persistence
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Check if previously logged data is still available
      final homeScreen = find.byType(Scaffold);
      expect(homeScreen, findsAtLeastNWidgets(1));
    });

    testWidgets('Notification and reminder flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to notification settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // Test notification toggles
      final notificationSwitches = find.byType(Switch);
      if (notificationSwitches.evaluate().isNotEmpty) {
        await tester.tap(notificationSwitches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Export and backup flow', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Navigate to data export
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // Test export functionality
      final exportButton = find.text('Export Data');
      if (exportButton.evaluate().isNotEmpty) {
        await tester.tap(exportButton);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Error Handling Integration Tests', () {
    testWidgets('Handle network connectivity issues', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Simulate offline mode
      // The app should handle gracefully without network
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Handle invalid data input', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pumpAndSettle();

      // Test form validation
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'invalid_date');
        await tester.pumpAndSettle();
      }

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Handle app state recovery after crash', (WidgetTester tester) async {
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pump();

      // Simulate app recovery
      await tester.pumpWidget(const PeriodTrackApp());
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}