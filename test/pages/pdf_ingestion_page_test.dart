import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/pages/pdf_ingestion_page.dart' as simple_page;
import 'package:studyking/pages/shared_pdf_ui_page.dart' as shared_page;
import 'package:studyking/providers/llm_engine_provider.dart';

void main() {
  group('PDF ingestion pages', () {
    late LLMAIEngineProvider engine;

    setUp(() {
      engine = LLMAIEngineProvider();
    });

    testWidgets('simple PDFIngestionPage renders controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: simple_page.PDFIngestionPage(
            llmProvider: engine,
            pageProcessor: engine,
          ),
        ),
      );

      expect(find.text('PDF Ingestion Engine'), findsOneWidget);
      expect(find.text('Configure PDF Processing Settings'), findsOneWidget);
      expect(find.text('Select LLM Model'), findsOneWidget);
      expect(find.text('Batch Processing Settings'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('simple page shows upload dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: simple_page.PDFIngestionPage(
            llmProvider: engine,
            pageProcessor: engine,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.upload_file));
      await tester.pumpAndSettle();

      expect(find.text('Upload PDF Study Material'), findsOneWidget);
      expect(find.text('Select PDF file to process...'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Select PDF file to process...'), findsNothing);
    });

    testWidgets('shared PDFIngestionPage opens bottom sheet and snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: shared_page.PDFIngestionPage(
            llmProvider: engine,
            pageProcessor: engine,
          ),
        ),
      );

      expect(find.text('Upload PDF Study Material'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.upload));
      await tester.pumpAndSettle();

      expect(find.text('Pick PDF File'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);

      await tester.tap(find.text('Pick PDF File'));
      await tester.pump();
      expect(find.text('Please upload a PDF file'), findsOneWidget);

      await tester.tap(find.text('Take Photo'));
      await tester.pump();
      expect(find.text('Take Photo'), findsOneWidget);
    });
  });
}
