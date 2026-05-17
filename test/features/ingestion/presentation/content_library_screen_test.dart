import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';

void main() {
  group('ContentLibraryScreen', () {
    test('Source model stores createdAt', () {
      final now = DateTime(2026, 5, 1);
      final source = Source(
        id: 'src1',
        title: 'Test',
        type: SourceType.pdf,
        processingStatus: 'completed',
        createdAt: now,
      );

      expect(source.createdAt, equals(now));
    });

    test('Source model createdAt defaults to null', () {
      final source = Source(
        id: 'src1',
        title: 'Test',
        type: SourceType.pdf,
      );

      expect(source.createdAt, isNull);
    });

    test('Source model copyWith preserves createdAt', () {
      final now = DateTime(2026, 5, 1);
      final source = Source(
        id: 'src1',
        title: 'Test',
        type: SourceType.pdf,
        createdAt: now,
      );

      final updated = source.copyWith(title: 'Updated');
      expect(updated.createdAt, equals(now));
    });

    test('Source model copyWith updates createdAt', () {
      final later = DateTime(2026, 6, 1);
      final source = Source(
        id: 'src1',
        title: 'Test',
        type: SourceType.pdf,
      );

      final updated = source.copyWith(createdAt: later);
      expect(updated.createdAt, equals(later));
    });

    test('Source toJson/fromJson roundtrip preserves createdAt', () {
      final now = DateTime(2026, 5, 1);
      final source = Source(
        id: 'src1',
        title: 'Test',
        type: SourceType.pdf,
        processingStatus: 'completed',
        createdAt: now,
      );

      final json = source.toJson();
      final restored = Source.fromJson(json);

      expect(restored.createdAt, isNotNull);
    });

    test('ProcessingStatus enum has all expected values', () {
      expect(ProcessingStatus.values, contains(ProcessingStatus.pending));
      expect(ProcessingStatus.values, contains(ProcessingStatus.extracting));
      expect(ProcessingStatus.values, contains(ProcessingStatus.classifying));
      expect(ProcessingStatus.values, contains(ProcessingStatus.generatingQuestions));
      expect(ProcessingStatus.values, contains(ProcessingStatus.validating));
      expect(ProcessingStatus.values, contains(ProcessingStatus.completed));
      expect(ProcessingStatus.values, contains(ProcessingStatus.failed));
    });
  });
}
