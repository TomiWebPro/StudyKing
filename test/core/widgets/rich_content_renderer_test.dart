import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/widgets/mermaid_diagram.dart';
import 'package:studyking/core/widgets/rich_content_renderer.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _SpyLogger extends Logger {
  final List<String> warnMessages = [];
  final List<Object?> warnErrors = [];

  _SpyLogger() : super('RichContentRenderer');

  @override
  void w(String message, [Object? error, StackTrace? stack]) {
    warnMessages.add(message);
    warnErrors.add(error);
  }
}

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

    testWidgets(
        'fallback renders raw latex on parse error without throwing and logs via w',
        (tester) async {
      final spy = _SpyLogger();
      RichContentRenderer.testLogger = spy;
      addTearDown(() => RichContentRenderer.testLogger = null);

      const invalidLatex = r'\invalidcommand';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: 'test \$$invalidLatex\$ end'),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(invalidLatex), findsOneWidget);
      expect(spy.warnMessages, isNotEmpty);
      expect(spy.warnMessages.first, contains(invalidLatex));
    });

    testWidgets('fallback preserves monospace style and logs for display mode',
        (tester) async {
      final spy = _SpyLogger();
      RichContentRenderer.testLogger = spy;
      addTearDown(() => RichContentRenderer.testLogger = null);

      const invalidLatex = r'\unknown';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(
              content: 'before \$\$$invalidLatex\$\$ after'),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(invalidLatex), findsOneWidget);
      expect(spy.warnMessages, isNotEmpty);
      expect(spy.warnMessages.first, contains(invalidLatex));
    });

    testWidgets('valid latex does not trigger warning log', (tester) async {
      final spy = _SpyLogger();
      RichContentRenderer.testLogger = spy;
      addTearDown(() => RichContentRenderer.testLogger = null);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: RichContentRenderer(content: r'$\frac{1}{2}$'),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(spy.warnMessages, isEmpty);
    });
  });

  group('RichContentRenderer - Mermaid diagrams', () {
    Widget buildApp(String content) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: RichContentRenderer(content: content)),
        );

    testWidgets('renders mermaid flowchart fence as a diagram, not raw code',
        (tester) async {
      await tester.pumpWidget(buildApp(
        '```mermaid\nflowchart TD\nA[Start] --> B[End]\n```',
      ));

      expect(find.byType(MermaidDiagram), findsOneWidget);
      // The raw directive line must never appear as visible text.
      expect(find.text('flowchart TD'), findsNothing);
      // Parsed node labels are rendered as visible text.
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.byIcon(Icons.account_tree), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mermaid pie chart with canvas and locale-aware legend',
        (tester) async {
      await tester.pumpWidget(buildApp(
        '```mermaid\npie title Pets\n"Dogs" : 60\n"Cats" : 40\n```',
      ));

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
      expect(find.text('Dogs (60%)'), findsOneWidget);
      expect(find.text('Cats (40%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mermaid bar chart with axis labels and values',
        (tester) async {
      await tester.pumpWidget(buildApp(
        '```mermaid\nbarChart\nQ1 30\nQ2 45\n```',
      ));

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('Q2'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mermaid table with headers and cells', (tester) async {
      await tester.pumpWidget(buildApp(
        '```mermaid\n| H1 | H2 |\n| --- | --- |\n| a | b |\n```',
      ));

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unsupported mermaid spec shows fallback card, hides raw source',
        (tester) async {
      await tester.pumpWidget(buildApp(
        '```mermaid\nsequenceDiagram\nAlice calls Bob to explain fractions\n```',
      ));

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.text('Diagram'), findsOneWidget);
      // The hint (first meaningful line) is shown as a fallback descriptor.
      expect(find.text('sequenceDiagram'), findsOneWidget);
      // The raw body must not be dumped as code.
      expect(find.text('Alice calls Bob to explain fractions'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders text content around a mermaid fence', (tester) async {
      await tester.pumpWidget(buildApp(
        'Before the diagram.\n'
        '```mermaid\n'
        'flowchart LR\n'
        'A --> B\n'
        '```\n'
        'After the diagram.',
      ));

      expect(find.byType(MermaidDiagram), findsOneWidget);
      expect(find.text('Before the diagram.'), findsOneWidget);
      expect(find.text('After the diagram.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not treat non-mermaid code fence as a diagram',
        (tester) async {
      await tester.pumpWidget(buildApp(
        '```js\nconst x = 1;\n```',
      ));

      expect(find.byType(MermaidDiagram), findsNothing);
      expect(find.textContaining('const x = 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
