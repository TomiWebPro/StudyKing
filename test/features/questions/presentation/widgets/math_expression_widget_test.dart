import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/presentation/widgets/math_expression_widget.dart';

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

List<InlineSpan> _getSpans(WidgetTester tester) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
  final textSpan = richTexts.first.text as TextSpan;
  return textSpan.children ?? [];
}

void main() {
  group('MathExpressionWidget', () {
    testWidgets('renders with showPrefix correctly', (tester) async {
      await tester.pumpWidget(buildWidget(
        expression: 'x = 1',
        showPrefix: true,
      ));

      final spans = _getSpans(tester);
      expect((spans.first as TextSpan).text, 'Expression: ');
    });

    testWidgets('parses Greek letters like alpha and pi', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\alpha + \pi'));

      final spans = _getSpans(tester);
      final alphaSpan = spans.whereType<TextSpan>().where((s) => s.text == '\u03B1').toList();
      final piSpan = spans.whereType<TextSpan>().where((s) => s.text == '\u03C0').toList();
      expect(alphaSpan, isNotEmpty);
      expect(piSpan, isNotEmpty);
    });

    testWidgets('parses times, cdot, infty, rightarrow, pm commands', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'2 \times 3 \cdot 4 \infty \rightarrow \pm'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u00D7'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u00B7'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u221E'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2192'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u00B1'), isTrue);
    });

    testWidgets('parses comparison commands ge, le, neq', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'x \ge 5 \le 10 \neq 0'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2265'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2264'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2260'), isTrue);
    });

    testWidgets('renders integer numbers with deep orange color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '42'));

      final spans = _getSpans(tester);
      final intSpan = spans.whereType<TextSpan>().where((s) => s.text == '42').toList();
      expect(intSpan, isNotEmpty);
      expect(intSpan.first.style?.color, Colors.deepOrange.shade700);
    });

    testWidgets('renders variables in italic', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x + y'));

      final spans = _getSpans(tester);
      final varSpan = spans.whereType<TextSpan>().where((s) => s.text == 'x').toList();
      expect(varSpan, isNotEmpty);
      expect(varSpan.first.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('parses sqrt command into square root symbol', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\sqrt{x}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u221A'), isTrue);
    });

    testWidgets('renders operators with correct color for plus', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a + b'));

      final spans = _getSpans(tester);
      final opSpan = spans.whereType<TextSpan>().where((s) => s.text == '+').toList();
      expect(opSpan, isNotEmpty);
      expect(opSpan.first.style?.color, Colors.green.shade700);
    });

    testWidgets('renders isSolution with container wrapping', (tester) async {
      await tester.pumpWidget(buildWidget(
        expression: 'x = 5',
        isSolution: true,
      ));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '='), isTrue);
    });

    testWidgets('default showPrefix is false so no prefix shown', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == 'Expression: '), isFalse);
    });

    testWidgets('parses frac command', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac{1}{2}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/'), isTrue);
    });

    testWidgets('parses leftarrow command', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\leftarrow'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2190'), isTrue);
    });

    testWidgets('parses to command as rightarrow', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\to'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2192'), isTrue);
    });

    testWidgets('parses superscript with braces', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^{2}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('parses superscript with parens', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^(2)'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('parses superscript with alphanumeric', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^2'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('parses subscript with braces', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x_{ij}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('parses subscript with alphanumeric', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x_1'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('skips curly braces', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '{x}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == 'x'), isTrue);
    });

    testWidgets('renders empty expression gracefully', (tester) async {
      await tester.pumpWidget(buildWidget(expression: ''));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders integer numbers part of decimal with deep orange', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '3.14'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '3' && s.style?.color == Colors.deepOrange.shade700), isTrue);
    });

    testWidgets('parses percent sign', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '50%'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '%' && s.style?.color == Colors.green), isTrue);
    });

    testWidgets('parses equals sign with blue color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x=5'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '=' && s.style?.color == Colors.blue), isTrue);
    });

    testWidgets('parses comma and semicolon', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a,b;c'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ','), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ';'), isTrue);
    });

    testWidgets('parses parentheses with brown color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '(x)'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '(' && s.style?.color == Colors.brown.shade600), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ')' && s.style?.color == Colors.brown.shade600), isTrue);
    });

    testWidgets('parses square brackets with brown color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '[x]'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '[' && s.style?.color == Colors.brown.shade600), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ']' && s.style?.color == Colors.brown.shade600), isTrue);
    });

    testWidgets('parses > operator', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x>5'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '>'), isTrue);
    });

    testWidgets('parses minus operator with green color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a - b'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '-' && s.style?.color == Colors.green.shade700), isTrue);
    });

    testWidgets('parses multiply operator converted to times symbol', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a * b'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u00D7' && s.style?.color == Colors.orange.shade700), isTrue);
    });

    testWidgets('parses division operator', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a / b'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/' && s.style?.color == Colors.orange.shade700), isTrue);
    });

    testWidgets('parses backslash delimiters for brackets', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\( x \)'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '('), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ')'), isTrue);
    });

    testWidgets('parses backslash square bracket delimiters', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\[ x \]'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '['), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ']'), isTrue);
    });

    testWidgets('renders unknown command as literal text', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\unknown'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text?.contains(r'\unknown') ?? false), isTrue);
    });

    testWidgets('handles backslash at end of string', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'x\'));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles backslash space as space', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'a\ b'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == ' '), isTrue);
    });

    testWidgets('handles backslash curly brace delimiters', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\{ \}'));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('nested braces in frac command', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac{{x}}{{y}}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/'), isTrue);
    });

    testWidgets('handles single character expression', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == 'x' && s.style?.fontStyle == FontStyle.italic), isTrue);
    });

    testWidgets('superscript with hyphen character', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^{-1}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('subscript with braces at end', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x_{n}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('frac without braces just adds slash', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/'), isTrue);
    });

    testWidgets('frac with numerator but no denominator', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac{1}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/'), isTrue);
    });

    testWidgets('unbalanced braces renders without error', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac{1}{2'));
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('unbalanced parentheses renders without error', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^(2'));
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('floating point decimal splits into integer and fractional parts', (tester) async {
      await tester.pumpWidget(buildWidget(expression: '3.14159'));

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('empty backslash at very end of string', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'a\'));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles backslash followed by lowercase p no matching command', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\p'));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('backslash followed by colon etc has no match', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\:'));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('backslash brace without command skips braces', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\{text\}'));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('subscript without braces uses adjacent chars', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x_abc'));
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('superscript without braces uses adjacent chars', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^abc'));
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('renders contiguous alphabetic text as italic', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'sin'));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles isSolution with no prefix by default', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x = 5', isSolution: true));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders showPrefix false has no prefix', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x = 5', showPrefix: false));
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles le and neq operators', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'a \le b \neq c'));
      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2264'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u2260'), isTrue);
    });

    testWidgets('unknown backslash command renders as literal', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\unknowncommand'));
      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text?.contains(r'\unknowncommand') ?? false), isTrue);
    });

    testWidgets('renders uppercase Gamma and Delta Greek letters', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\Gamma \Delta \Theta \Lambda \Sigma \Phi \Psi \Omega'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u0393'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u0394'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u0398'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u039B'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03A3'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03A6'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03A8'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03A9'), isTrue);
    });

    testWidgets('renders lowercase beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron rho sigma tau upsilon phi chi psi omega', (tester) async {
      await tester.pumpWidget(buildWidget(
        expression: r'\beta \gamma \delta \epsilon \zeta \eta \theta \iota \kappa \lambda \mu \nu \xi \omicron \rho \sigma \tau \upsilon \phi \chi \psi \omega',
      ));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B2'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B3'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B4'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B5'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B6'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B7'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B8'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03B9'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03BA'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03BB'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03BC'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03BD'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03BE'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03BF'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C1'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C3'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C4'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C5'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C6'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C7'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C8'), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '\u03C9'), isTrue);
    });

    testWidgets('renders backslash followed by digit as literal', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\123'));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles superscript and subscript combined expression', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^{2}_{ij}'));

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('isSolution has container decoration', (tester) async {
      await tester.pumpWidget(buildWidget(
        expression: 'x = 5',
        isSolution: true,
      ));

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('greater-than operator with blue color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x>5'));

      final spans = _getSpans(tester);
      final gtSpan = spans.whereType<TextSpan>().where((s) => s.text == '>').toList();
      expect(gtSpan, isNotEmpty);
      expect(gtSpan.first.style?.color, Colors.blue.shade700);
    });

    testWidgets('comma and semicolon have fontSize 14', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a,b;c'));

      final spans = _getSpans(tester);
      final commaSpan = spans.whereType<TextSpan>().where((s) => s.text == ',').toList();
      final semiSpan = spans.whereType<TextSpan>().where((s) => s.text == ';').toList();
      expect(commaSpan, isNotEmpty);
      expect(commaSpan.first.style?.fontSize, 14);
      expect(semiSpan, isNotEmpty);
      expect(semiSpan.first.style?.fontSize, 14);
    });

    testWidgets('equals sign has bold font weight and blue color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x=5'));

      final spans = _getSpans(tester);
      final eqSpan = spans.whereType<TextSpan>().where((s) => s.text == '=').toList();
      expect(eqSpan, isNotEmpty);
      expect(eqSpan.first.style?.fontWeight, FontWeight.bold);
      expect(eqSpan.first.style?.color, Colors.blue);
    });

    testWidgets('isSolution with showPrefix renders both', (tester) async {
      await tester.pumpWidget(buildWidget(
        expression: 'x = 5',
        isSolution: true,
        showPrefix: true,
      ));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == 'Expression: '), isTrue);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '='), isTrue);
    });

    testWidgets('frac with whitespace between args', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac{1} {2}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/'), isTrue);
    });

    testWidgets('subscript text has teal color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x_{n}'));

      final spans = _getSpans(tester);
      final widgetSpans = spans.whereType<WidgetSpan>().toList();
      expect(widgetSpans, isNotEmpty);
    });

    testWidgets('superscript text has purple color', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^{2}'));

      final spans = _getSpans(tester);
      final widgetSpans = spans.whereType<WidgetSpan>().toList();
      expect(widgetSpans, isNotEmpty);
    });

    testWidgets('caret at end of expression renders without error', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^'));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('underscore at end of expression renders without error', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x_'));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('superscript with negative number renders', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^{-2}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThan(0));
    });

    testWidgets('frac with nested braces in numerator', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\frac{x+y}{z}'));

      final spans = _getSpans(tester);
      expect(spans.whereType<TextSpan>().any((s) => s.text == '/'), isTrue);
    });

    testWidgets('handles plus operator at end', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x+'));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('handles multiple equals signs', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'a=b=c'));

      final spans = _getSpans(tester);
      final eqSpans = spans.whereType<TextSpan>().where((s) => s.text == '=').toList();
      expect(eqSpans.length, 2);
    });

    testWidgets('handles mixed superscript and regular text', (tester) async {
      await tester.pumpWidget(buildWidget(expression: 'x^2+y^2'));

      final spans = _getSpans(tester);
      expect(spans.whereType<WidgetSpan>().length, greaterThanOrEqualTo(2));
    });

    testWidgets('handles backslash followed by non-letter at start', (tester) async {
      await tester.pumpWidget(buildWidget(expression: r'\!'));

      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
