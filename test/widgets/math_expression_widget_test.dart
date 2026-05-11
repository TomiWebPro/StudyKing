import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/math_expression_widget.dart';

void main() {
  group('MathExpressionWidget', () {
    testWidgets('renders expression text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'x + y = z',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders complex math expression', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: r'$\frac{a}{b} + \sqrt{x}$',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('shows prefix when showPrefix is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'x^2 + y^2',
              showPrefix: true,
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('does not show prefix when showPrefix is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'a + b',
              showPrefix: false,
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('shows solution container when isSolution is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'x = 5',
              isSolution: true,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('does not show solution container when isSolution is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'x + y',
              isSolution: false,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders LaTeX-like expression with parentheses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: r'\(a + b\)',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders expression with brackets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: r'\[a \times b\]',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders with variables', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'f(x) = x^2',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders with operators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: 'a > b and c < d',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders empty expression', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: '',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders with isSolution and showPrefix together', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: '2x + 1',
              isSolution: true,
              showPrefix: true,
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders simple number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathExpressionWidget(
              expression: '42',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });
  });

  group('FormulaWidget', () {
    testWidgets('renders formula', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaWidget(
              formula: 'E = mc^2',
            ),
          ),
        ),
      );

      expect(find.text('E = mc^2'), findsOneWidget);
    });

    testWidgets('renders formula with variable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaWidget(
              formula: 'F = ma',
              variable: 'F',
            ),
          ),
        ),
      );

      expect(find.text('F = F = ma'), findsOneWidget);
    });

    testWidgets('renders formula with empty variable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaWidget(
              formula: 'x + y',
              variable: '',
            ),
          ),
        ),
      );

      expect(find.text('x + y'), findsOneWidget);
    });

    testWidgets('renders formula with whitespace variable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaWidget(
              formula: 'a + b',
              variable: '   ',
            ),
          ),
        ),
      );

      expect(find.text('a + b'), findsOneWidget);
    });
  });
}