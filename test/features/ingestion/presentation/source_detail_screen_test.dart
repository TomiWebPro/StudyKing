import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';

void main() {
  group('Source model with createdAt', () {
    test('Source created with createdAt stores date', () {
      final now = DateTime(2026, 5, 15);
      final source = Source(
        id: 'src1',
        title: 'Test Doc',
        type: SourceType.pdf,
        processingStatus: 'completed',
        createdAt: now,
      );

      expect(source.createdAt, now);
    });

    test('Source fromJson restores createdAt', () {
      final json = {
        'id': 'src1',
        'title': 'Doc',
        'type': 'pdf',
        'processingStatus': 'completed',
        'createdAt': '2026-05-15T10:00:00.000',
      };

      final source = Source.fromJson(json);
      expect(source.createdAt, isNotNull);
    });

    test('Source toJson includes createdAt', () {
      final source = Source(
        id: 'src1',
        title: 'Doc',
        type: SourceType.pdf,
        processingStatus: 'completed',
        createdAt: DateTime(2026, 5, 15),
      );

      final json = source.toJson();
      expect(json['createdAt'], isNotNull);
    });

    test('Source copyWith preserves createdAt', () {
      final source = Source(
        id: 'src1',
        title: 'Original',
        type: SourceType.pdf,
        createdAt: DateTime(2026, 5, 15),
      );

      final updated = source.copyWith(title: 'Updated');
      expect(updated.createdAt, DateTime(2026, 5, 15));
    });
  });

  group('ProcessingStatus display', () {
    test('failed status name is "failed"', () {
      expect(ProcessingStatus.failed.name, 'failed');
    });

    test('completed status name is "completed"', () {
      expect(ProcessingStatus.completed.name, 'completed');
    });
  });
}
