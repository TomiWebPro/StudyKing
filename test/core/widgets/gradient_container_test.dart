import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/gradient_container.dart';

Widget wrapApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('GradientContainer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.blue,
          child: Text('Hello'),
        ),
      ));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('applies accent color', (tester) async {
      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.red,
          child: Text('Test'),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;

      expect(gradient.colors[0].toARGB32(), equals(Colors.red.withValues(alpha: 0.2).toARGB32()));
    });

    testWidgets('applies custom borderRadius', (tester) async {
      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.blue,
          borderRadius: 24,
          child: Text('Test'),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.borderRadius, equals(BorderRadius.circular(24)));
    });

    testWidgets('applies padding', (tester) async {
      const testPadding = EdgeInsets.all(32);

      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.blue,
          padding: EdgeInsets.all(32),
          child: Text('Test'),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, equals(testPadding));
    });

    testWidgets('uses default borderRadius of 12', (tester) async {
      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.blue,
          child: Text('Test'),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('renders child inside gradient container', (tester) async {
      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.green,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Text('Sized'),
          ),
        ),
      ));

      expect(find.text('Sized'), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('applies border with accent color', (tester) async {
      await tester.pumpWidget(wrapApp(
        const GradientContainer(
          accent: Colors.purple,
          child: Text('Border'),
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;

      expect(border.top.color.toARGB32(), equals(Colors.purple.withValues(alpha: 0.3).toARGB32()));
    });

    testWidgets('works in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: const GradientContainer(
              accent: Colors.blue,
              child: Text('Dark'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;

      expect(gradient.colors[0].toARGB32(), equals(Colors.blue.withValues(alpha: 0.3).toARGB32()));
    });
  });
}
