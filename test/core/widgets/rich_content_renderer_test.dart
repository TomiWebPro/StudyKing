import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/rich_content_renderer.dart';

void main() {
  group('RichContentRenderer', () {
    testWidgets('renders plain text without math delimiters', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(content: 'Hello World'),
        ),
      ));

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders empty text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(content: ''),
        ),
      ));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders inline math with dollar signs', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(content: r'The equation is $x^2$'),
        ),
      ));

      expect(find.textContaining('The equation is'), findsOneWidget);
    });

    testWidgets('renders display math with double dollar signs',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: r'Display: $$\frac{1}{2}$$ equation'),
        ),
      ));

      expect(find.textContaining('Display:'), findsOneWidget);
    });

    testWidgets('handles multiple math expressions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: r'First $x$ and second $y$'),
        ),
      ));

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('handles text with only math', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(content: r'$x^2 + y^2 = z^2$'),
        ),
      ));

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('applies custom text style', (tester) async {
      const style = TextStyle(fontSize: 20, color: Colors.red);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
            content: 'Styled text',
            textStyle: style,
          ),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.style?.fontSize, equals(20));
      expect(richText.text.style?.color, equals(Colors.red));
    });

    testWidgets('handles escaped dollar signs', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: r'Price is \$5 and equation is $x$'),
        ),
      ));

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('handles unmatched dollar signs gracefully', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: r'Odd number of $ dollar signs'),
        ),
      ));

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('handles complex LaTeX expressions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: r'$\int_0^1 x^2 dx = \frac{1}{3}$'),
        ),
      ));

      expect(find.byType(Wrap), findsOneWidget);
    });
  });
}
