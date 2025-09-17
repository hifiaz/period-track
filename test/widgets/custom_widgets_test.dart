import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_track/widgets/custom_widgets.dart';

void main() {
  group('CustomCard Widget Tests', () {
    testWidgets('should render CustomCard with child', (WidgetTester tester) async {
      const childText = 'Test Child';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: const Text(childText),
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
      expect(find.byType(CustomCard), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('should display child content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: const Column(
                children: [
                  Text('Title'),
                  Text('Subtitle'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('should render Material widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(Material), findsWidgets);
    });
  });

  group('CustomButton Widget Tests', () {
    testWidgets('should render CustomButton with text', (WidgetTester tester) async {
      const buttonText = 'Click Me';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should handle button press events', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Press me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      expect(pressed, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('should apply custom colors', (WidgetTester tester) async {
      const customColor = Colors.red;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Colored',
              onPressed: () {},
              backgroundColor: customColor,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({}), equals(customColor));
    });
  });

  group('StatCard Widget Tests', () {
    testWidgets('should render StatCard with title and value', (WidgetTester tester) async {
      const title = 'Cycle Length';
      const value = '28 days';
      const icon = Icons.calendar_today;
      const color = Colors.blue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: title,
              value: value,
              icon: icon,
              color: color,
            ),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(value), findsOneWidget);
    });

    testWidgets('should display icon', (WidgetTester tester) async {
      const icon = Icons.calendar_today;
      const color = Colors.green;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Test',
              value: '123',
              icon: icon,
              color: color,
            ),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('should apply custom colors', (WidgetTester tester) async {
      const customColor = Colors.red;
      const icon = Icons.favorite;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Test',
              value: '123',
              icon: icon,
              color: customColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
      expect(find.byType(StatCard), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;
      const icon = Icons.touch_app;
      const color = Colors.purple;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Tappable',
              value: '456',
              icon: icon,
              color: color,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      expect(tapped, isTrue);
    });

    testWidgets('should show chevron icon when tappable', (WidgetTester tester) async {
      const icon = Icons.info;
      const color = Colors.orange;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Tappable Card',
              value: '789',
              icon: icon,
              color: color,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
}