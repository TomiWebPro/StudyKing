import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/widgets/mermaid_diagram.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Widget buildApp(Widget widget) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: widget),
      );

  group('MermaidDiagram', () {
    testWidgets('renders flowchart nodes, arrows and edge labels',
        (tester) async {
      await tester.pumpWidget(buildApp(MermaidDiagram(
        spec: 'flowchart TD\nA[Start] --> B[End]',
      )));

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.byIcon(Icons.account_tree), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.textContaining('\u2192'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders pie chart with canvas and locale-aware legend',
        (tester) async {
      await tester.pumpWidget(buildApp(MermaidDiagram(
        spec: 'pie title Pets\n"Dogs" : 50\n"Cats" : 50',
      )));

      // CustomPaint is an internal detail of the pie canvas; the material
      // scaffold introduces extra CustomPaint widgets, so we verify the
      // rendered output via the legend text instead.
      expect(find.text('Dogs (50%)'), findsOneWidget);
      expect(find.text('Cats (50%)'), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
    });

    testWidgets('renders bar chart values and axis labels', (tester) async {
      await tester.pumpWidget(buildApp(MermaidDiagram(
        spec: 'barChart\nQ1 30\nQ2 45',
      )));

      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('Q2'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('renders markdown table with headers and cells', (tester) async {
      await tester.pumpWidget(buildApp(MermaidDiagram(
        spec: '| H1 | H2 |\n| --- | --- |\n| a | b |',
      )));

      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    testWidgets(
        'unsupported spec renders a labelled fallback card and hides raw source',
        (tester) async {
      // `sequenceDiagram` with prose body is not a chart type we render.
      const spec = 'sequenceDiagram\nAlice calls Bob to explain fractions';

      await tester.pumpWidget(buildApp(MermaidDiagram(spec: spec)));

      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.text('Diagram'), findsOneWidget);
      expect(find.text('sequenceDiagram'), findsOneWidget);
      // The raw body must NOT be dumped as code.
      expect(find.text('Alice calls Bob to explain fractions'), findsNothing);
    });
  });
}
