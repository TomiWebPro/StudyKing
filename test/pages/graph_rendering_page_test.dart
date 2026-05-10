import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/pages/graph_rendering_page.dart';
import 'package:studyking/providers/llm_engine_provider.dart';

void main() {
  group('GraphRenderingPage', () {
    late LLMAIEngineProvider engine;

    setUp(() {
      engine = LLMAIEngineProvider();
    });

    testWidgets('renders main sections and controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: GraphRenderingPage(llmProvider: engine)),
      );

      expect(find.text('Graph Renderer'), findsOneWidget);
      expect(find.text('Upload Data'), findsOneWidget);
      expect(find.text('Graph Type Detection'), findsOneWidget);
      expect(find.text('LLM Validation'), findsOneWidget);
      expect(find.text('Rendered Graph'), findsOneWidget);
      expect(find.text('Validate with LLM'), findsOneWidget);
      expect(find.text('Upload Data File'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(4));
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows upload dialog and dismisses it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: GraphRenderingPage(llmProvider: engine)),
      );

      await tester.tap(find.text('Upload Data File'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Data File'), findsNWidgets(2));
      expect(find.text('Choose file to upload...'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Choose file to upload...'), findsNothing);
    });
  });
}
