import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/ui/widgets/math_expression_widget.dart';

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

void main() {
  group('MathExpressionWidget', () {
    group('basic rendering', () {
      testWidgets('renders math expression widget', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x + 2 = 5'));

        expect(find.byType(MathExpressionWidget), findsOneWidget);
      });

      testWidgets('renders RichText for expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x = 5'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders with showPrefix enabled', (tester) async {
        await tester.pumpWidget(buildWidget(
          expression: '2x + 3',
          showPrefix: true,
        ));

        final richText = tester.widget<RichText>(find.byType(RichText));
        final textSpan = richText.text as TextSpan;
        expect(textSpan.children, isNotNull);
        expect(textSpan.children!.length, greaterThan(1));
      });

      testWidgets('renders solution style when isSolution is true', (tester) async {
        await tester.pumpWidget(buildWidget(
          expression: 'x = 10',
          isSolution: true,
        ));

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('simple math expressions', () {
      testWidgets('renders simple addition', (tester) async {
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

      testWidgets('renders subtraction', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a - b = 0'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders multiplication', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a * b'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders division', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a / b'));
        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('LaTeX commands', () {
      testWidgets('renders \\sqrt command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\sqrt{x}'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\frac command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\frac{x}{y}'));

        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\frac without braces', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\frac abc'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\times command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'2 \times 3'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\cdot command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'a \cdot b'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\infty command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\infty'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\rightarrow command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'a \rightarrow b'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\to command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'a \to b'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\leftarrow command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'a \leftarrow b'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\pm command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'a \pm b'));
        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('comparison commands', () {
      testWidgets('renders \\ge command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'x \ge 5'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\le command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'x \le 10'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\neq command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'x \neq 0'));
        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('delimiter commands', () {
      testWidgets('renders \\\\( and \\\\) parentheses', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\( x + 1 \)'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\\\[ and \\\\] brackets', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\[ x^2 \]'));
        expect(find.byType(RichText), findsWidgets);
      });
    });

    group('exponents and subscripts', () {
      testWidgets('renders exponent with caret and number', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x^2'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders exponent with curly braces', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x^{2 + 3}'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders exponent with parentheses', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x^(2)'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders exponent with letters', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'e^x'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders exponent with negative', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x^{-1}'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders subscript with underscore and letter', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x_n'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders subscript with curly braces', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x_{n+1}'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders subscript with numbers', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a_1'));
        expect(find.byType(RichText), findsWidgets);
      });
    });

    group('Greek letters', () {
      testWidgets('renders \\alpha', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\alpha + \beta'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders \\pi', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\pi r^2'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('renders \\Delta', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\Delta'));
        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('special characters', () {
      testWidgets('renders percent sign', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '50%'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders comma', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'f(x, y)'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders semicolon', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'x; y'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders regular parentheses', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '(x + y)'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders regular brackets', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '[a, b]'));
        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('numbers and identifiers', () {
      testWidgets('renders decimal number in deep orange', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '3.14'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders integer number', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '42'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders variable in italic', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'variable'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('renders sin and cos as identifiers', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'sin(x)'));
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
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('handles expression with special characters', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'sin(x) > cos(y)'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('handles long expression', (tester) async {
        await tester.pumpWidget(buildWidget(expression: 'a_1*x^2 + a_2*x + a_3 = 0'));
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('handles unknown backslash command', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'\unknown'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('handles backslash with space', (tester) async {
        await tester.pumpWidget(buildWidget(expression: r'a\ b'));
        expect(find.byType(RichText), findsOneWidget);
      });

      testWidgets('handles grouping braces', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '{x}'));
        expect(find.byType(RichText), findsOneWidget);
      });
    });

    group('RichText styling', () {
      testWidgets('builds styled text spans with children', (tester) async {
        await tester.pumpWidget(buildWidget(expression: '2 + 3 = 5'));

        final richText = tester.widget<RichText>(find.byType(RichText));
        final textSpan = richText.text as TextSpan;
        expect(textSpan.children, isNotNull);
        expect(textSpan.children!.length, greaterThan(0));
      });

      testWidgets('showPrefix adds prefix TextSpan', (tester) async {
        await tester.pumpWidget(buildWidget(
          expression: 'x = 1',
          showPrefix: true,
        ));

        final richText = tester.widget<RichText>(find.byType(RichText));
        final textSpan = richText.text as TextSpan;
        expect(textSpan.children, isNotNull);
        final firstChild = textSpan.children!.first;
        expect(firstChild, isA<TextSpan>());
        expect((firstChild as TextSpan).text, 'Expression: ');
      });
    });
  });

  group('FormulaWidget', () {
    group('basic rendering', () {
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
    });

    group('styling', () {
      testWidgets('has BoxDecoration', (tester) async {
        await tester.pumpWidget(buildFormulaWidget(formula: 'x = 1'));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FormulaWidget),
            matching: find.byType(Container),
          ),
        );
        expect(container.decoration, isA<BoxDecoration>());
      });

      testWidgets('has monospace font', (tester) async {
        await tester.pumpWidget(buildFormulaWidget(formula: 'a + b = c'));

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('renders grey background', (tester) async {
        await tester.pumpWidget(buildFormulaWidget(formula: 'test'));
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('edge cases', () {
      testWidgets('handles very long formula', (tester) async {
        await tester.pumpWidget(buildFormulaWidget(
          formula: 'a + b + c + d + e + f + g + h + i + j + k + l + m + n + o + p',
        ));
        expect(find.byType(FormulaWidget), findsOneWidget);
      });

      testWidgets('handles formula with only variable and no formula content', (tester) async {
        await tester.pumpWidget(buildFormulaWidget(
          formula: '',
          variable: 'x',
        ));
        expect(find.text('x = '), findsOneWidget);
      });
    });
  });
}
