import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/gradient_container.dart';
import 'package:studyking/core/widgets/metric_card.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(child: child),
      ),
    ),
  );
}

void main() {
  group('MetricCard', () {
    testWidgets('renders icon, value, and label', (tester) async {
      await tester.pumpWidget(wrapApp(
        const MetricCard(
          icon: Icons.star,
          value: '95%',
          label: 'Accuracy',
          accent: Colors.amber,
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
    });

    testWidgets('renders with different accent color', (tester) async {
      await tester.pumpWidget(wrapApp(
        const MetricCard(
          icon: Icons.check_circle,
          value: '42',
          label: 'Completed',
          accent: Colors.green,
        ),
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('includes GradientContainer', (tester) async {
      await tester.pumpWidget(wrapApp(
        const MetricCard(
          icon: Icons.access_time,
          value: '10h',
          label: 'Study Time',
          accent: Colors.blue,
        ),
      ));

      expect(find.byType(GradientContainer), findsOneWidget);
    });

    testWidgets('displays icon with accent color', (tester) async {
      await tester.pumpWidget(wrapApp(
        const MetricCard(
          icon: Icons.trending_up,
          value: '80%',
          label: 'Trend',
          accent: Colors.teal,
        ),
      ));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, equals(Colors.teal));
    });

    testWidgets('displays value with accent color', (tester) async {
      await tester.pumpWidget(wrapApp(
        const MetricCard(
          icon: Icons.school,
          value: '100',
          label: 'Questions',
          accent: Colors.orange,
        ),
      ));

      final valueText = tester.widget<Text>(find.text('100'));
      final style = valueText.style;
      expect(style?.color, equals(Colors.orange));
      expect(style?.fontWeight, equals(FontWeight.bold));
    });
  });
}
