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

List<InlineSpan> _getSpans(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.byType(RichText));
  final textSpan = richText.text as TextSpan;
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
  });
}
