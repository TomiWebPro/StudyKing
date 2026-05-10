import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/pages/shared_pdf_ui_page.dart';
import 'package:studyking/providers/llm_engine_provider.dart';
import 'package:studyking/services/batch_processor_service.dart';

void main() {
  group('PDFUploadCoordinator', () {
    late LLMAIEngineProvider engine;
    late BatchProcessingService batchService;

    setUp(() {
      engine = LLMAIEngineProvider();
      batchService = BatchProcessingService();
    });

    test('starts with default state', () {
      final coordinator = PDFUploadCoordinator(
        llmEngine: engine,
        batchProcessor: batchService,
      );

      expect(coordinator.hasActiveMaterial, isFalse);
      expect(coordinator.isProcessing, isFalse);
      expect(coordinator.uploadedPages, equals(0));
      expect(coordinator.completedPages, equals(0));
      expect(coordinator.totalCost, equals(0));
      expect(coordinator.isActive, isFalse);
      expect(coordinator.activeMaterial.materialId, isEmpty);
    });

    test('setCancelProcessing updates state', () {
      final coordinator = PDFUploadCoordinator(
        llmEngine: engine,
        batchProcessor: batchService,
      );

      coordinator.setCancelProcessing(true);
      expect(coordinator.cancelProcessing, isTrue);
      coordinator.setCancelProcessing(false);
      expect(coordinator.cancelProcessing, isFalse);
    });

    test('upload with empty list exits early', () async {
      final coordinator = PDFUploadCoordinator(
        llmEngine: engine,
        batchProcessor: batchService,
      );

      await coordinator.upload('material-1', 'math', 'Algebra', <String>[]);

      expect(coordinator.hasActiveMaterial, isFalse);
      expect(coordinator.isProcessing, isFalse);
      expect(coordinator.uploadedPages, equals(0));
      expect(coordinator.completedPages, equals(0));
      expect(coordinator.totalCost, equals(0));
    });

    test('isActive reflects currentBatch content', () {
      final coordinator = PDFUploadCoordinator(
        llmEngine: engine,
        batchProcessor: batchService,
      );

      expect(coordinator.isActive, isFalse);

      coordinator.currentBatch.addPage(
        content: 'page content',
        pageNumber: 1,
      );

      expect(coordinator.isActive, isTrue);
      expect(coordinator.currentBatch.countPages(), equals(1));
    });

    test('upload with invalid file path still completes safely', () async {
      final coordinator = PDFUploadCoordinator(
        llmEngine: engine,
        batchProcessor: batchService,
      );

      await coordinator.upload(
        'material-1',
        'science',
        'Physics Notes',
        <String>['/tmp/does-not-exist.pdf'],
      );

      expect(coordinator.hasActiveMaterial, isTrue);
      expect(coordinator.activeMaterial.materialId, equals('material-1'));
      expect(coordinator.isProcessing, isFalse);
      expect(coordinator.uploadedPages, equals(0));
      expect(coordinator.completedPages, equals(0));
    });

    test('cancelProcessing halts upload loop', () async {
      final coordinator = PDFUploadCoordinator(
        llmEngine: engine,
        batchProcessor: batchService,
      );

      coordinator.setCancelProcessing(true);
      await coordinator.upload(
        'material-2',
        'english',
        'Reading',
        <String>['/tmp/a.pdf', '/tmp/b.pdf'],
      );

      expect(coordinator.hasActiveMaterial, isTrue);
      expect(coordinator.activeMaterial.title, equals('Reading'));
      expect(coordinator.isProcessing, isFalse);
      expect(coordinator.uploadedPages, equals(0));
    });
  });
}
