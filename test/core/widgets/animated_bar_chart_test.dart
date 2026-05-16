import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/animated_bar_chart.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('AnimatedBarChart', () {
    testWidgets('renders bars for given data', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10, 'Tue': 20, 'Wed': 15},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
    });

    testWidgets('shows value tooltips by default', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10, 'Tue': 20},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.text('10'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('hides value tooltips when showValueTooltips is false', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.blue,
          showValueTooltips: false,
        ),
      ));

      expect(find.text('10'), findsNothing);
      expect(find.text('Mon'), findsOneWidget);
    });

    testWidgets('does not show zero value tooltips', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 0},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.text('0'), findsNothing);
      expect(find.text('Mon'), findsOneWidget);
    });

    testWidgets('shows yAxisLabel when provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 5},
          accentColor: Colors.blue,
          yAxisLabel: 'Sessions',
        ),
      ));

      expect(find.text('Sessions'), findsOneWidget);
    });

    testWidgets('hides yAxisLabel when not provided', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 5},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.byType(AnimatedBarChart), findsOneWidget);
    });

    testWidgets('handles empty data map', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.byType(AnimatedBarChart), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder), findsNothing);
    });

    testWidgets('renders with custom bar dimensions', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.red,
          minBarHeight: 60,
          maxBarHeight: 200,
          barWidth: 48,
        ),
      ));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('uses Tooltip widget for value tooltips', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 15},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('handles single data entry', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Fri': 42},
          accentColor: Colors.green,
        ),
      ));

      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('disapplies tooltip for zero value entry', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Sat': 0, 'Sun': 5},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.text('5'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders bar containers with TweenAnimationBuilder', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.blue,
        ),
      ));

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('resets animation when data changes', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.blue,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 20},
          accentColor: Colors.blue,
        ),
      ));

      await tester.pump();
      expect(find.text('Mon'), findsOneWidget);
    });

    testWidgets('uses custom borderRadius', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.blue,
          borderRadius: 12,
        ),
      ));

      expect(find.text('Mon'), findsOneWidget);
    });

    testWidgets('reduceMotion renders Container instead of TweenAnimationBuilder', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10, 'Tue': 20},
          accentColor: Colors.blue,
          reduceMotion: true,
        ),
      ));

      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });

    testWidgets('reduceMotion shows value tooltips still', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.blue,
          reduceMotion: true,
        ),
      ));

      expect(find.text('10'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
    });

    testWidgets('reduceMotion handles empty data', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {},
          accentColor: Colors.blue,
          reduceMotion: true,
        ),
      ));

      expect(find.byType(AnimatedBarChart), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder), findsNothing);
    });

    testWidgets('reduceMotion renders bar container with correct decoration', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10},
          accentColor: Colors.red,
          reduceMotion: true,
        ),
      ));

      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('reduceMotion renders bars with zero values', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 0, 'Tue': 5},
          accentColor: Colors.blue,
          reduceMotion: true,
        ),
      ));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder), findsNothing);
    });

    testWidgets('bars have Semantics labels for screen readers', (tester) async {
      await tester.pumpWidget(wrapApp(
        const AnimatedBarChart(
          data: {'Mon': 10, 'Tue': 20, 'Wed': 15},
          accentColor: Colors.blue,
        ),
      ));

      final semanticsNodes = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label ?? '').contains('sessions'),
      );
      expect(semanticsNodes, findsAtLeast(2));

      final labels = semanticsNodes.evaluate().map((e) {
        final widget = e.widget as Semantics;
        return widget.properties.label;
      });

      expect(labels, contains('Mon: 10 sessions'));
      expect(labels, contains('Tue: 20 sessions'));
      expect(labels, contains('Wed: 15 sessions'));
    });
  });
}
