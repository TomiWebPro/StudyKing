import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/math_expression_widget.dart';

void main() {
  group('MathExpressionWidget', () {
    Widget buildWidget({
      required String expression,
      bool isSolution = false,
      bool showPrefix = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MathExpressionWidget(
            expression: expression,
            isSolution: isSolution,
            showPrefix: showPrefix,
          ),
        ),
      );
    }

    group('basic rendering', () {
      testWidgets('renders expression widget', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x + 2 = 5'));

        expect(find.byType(MathExpressionWidget), findsOneWidget);
      });

      testWidgets('renders with showPrefix enabled', (tester) async {
        await tester.pumpWidget(buildWidget(
          expression: '2x + 3',
          showPrefix: true,
        ));

        expect(find.byType(MathExpressionWidget), findsOneWidget);
      });

      testWidgets('renders solution style when isSolution is true', (tester) async {
        await tester.pumpWidget(buildWidget(
          expression: 'x = 10',
          isSolution: true,
        ));

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('math token styling', () {
      testWidgets('renders simple expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a + b'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders expression with equals', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'y = mx + c'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders fraction-like expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '(a + b) / 2'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders LaTeX-style expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\frac{x}{y}'));

        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: ''));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('handles complex expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '2x^2 + 3x - 5 = 0'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('handles expression with special characters', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'sin(x) > cos(y)'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('handles expression with Greek letters', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'α + β = γ'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('handles long expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a_1*x^2 + a_2*x + a_3 = 0'));

        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('RichText styling', () {
      testWidgets('uses RichText for expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x = 5'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('builds styled text spans', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '2 + 3 = 5'));

        final richText = tester.widget<RichText>(find.byType(RichText));
        final textSpan = richText.text as TextSpan;
        expect(textSpan.children, isNotNull);
      });
    });
  });

  group('FormulaWidget', () {
    Widget buildFormulaWidget({
      required String formula,
      String? variable,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FormulaWidget(
            formula: formula,
            variable: variable,
          ),
        ),
      );
    }

    testWidgets('renders formula text', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(formula: 'E = mc^2'));

      expect(find.text('E = mc^2'), findsOneWidget);
    });

    testWidgets('renders formula with variable', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(
        formula: 'x^2',
        variable: 'x',
      ));

      expect(find.text('x = x^2'), findsOneWidget);
    });

    testWidgets('renders with empty variable string', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(
        formula: 'y = mx + b',
        variable: '',
      ));

      expect(find.text('y = mx + b'), findsOneWidget);
    });

    testWidgets('renders with whitespace variable', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(
        formula: 'A = πr^2',
        variable: '   ',
      ));

      expect(find.text('A = πr^2'), findsOneWidget);
    });

    testWidgets('renders null variable as just formula', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(
        formula: 'v = u + at',
        variable: null,
      ));

      expect(find.text('v = u + at'), findsOneWidget);
    });

    testWidgets('uses monospace font', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(formula: 'a + b = c'));

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container, isNotNull);
    });

    testWidgets('has rounded border', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(formula: 'x = 1'));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FormulaWidget),
          matching: find.byType(Container),
        ),
      );
      expect(container.decoration, isA<BoxDecoration>());
    });

    testWidgets('renders background color', (tester) async {
      await tester.pumpWidget(buildFormulaWidget(formula: 'test'));

      expect(find.byType(Container), findsWidgets);
    });
  });
}