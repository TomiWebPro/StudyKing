import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('Source', () {
    group('constructor', () {
      test('creates with required fields', () {
        final source = Source(
          id: 'source-1',
          title: 'Physics Textbook',
          type: SourceType.pdf,
        );

        expect(source.id, 'source-1');
        expect(source.title, 'Physics Textbook');
        expect(source.type, SourceType.pdf);
        expect(source.content, '');
        expect(source.subjectId, '');
        expect(source.topicId, '');
        expect(source.syllabusId, '');
        expect(source.sourceUrl, '');
        expect(source.studentId, '');
        expect(source.language, '');
        expect(source.summary, '');
        expect(source.processingStatus, 'pending');
        expect(source.extractedText, '');
        expect(source.generatedQuestionIds, isEmpty);
        expect(source.extractionMethod, '');
        expect(source.chunks, '');
        expect(source.extractionMeta, '');
        expect(source.createdAt, isNull);
      });

      test('creates with all fields', () {
        final createdAt = DateTime(2024, 1, 15);
        final source = Source(
          id: 'source-2',
          title: 'Chemistry Notes',
          type: SourceType.document,
          content: 'content body',
          subjectId: 'subj-1',
          topicId: 'topic-1',
          syllabusId: 'syll-1',
          sourceUrl: 'https://example.com',
          studentId: 'student-1',
          language: 'en',
          summary: 'summary text',
          processingStatus: 'completed',
          extractedText: 'extracted',
          generatedQuestionIds: ['q1', 'q2'],
          extractionMethod: 'ocr',
          chunks: '[]',
          extractionMeta: '{"pages": 5}',
          createdAt: createdAt,
        );

        expect(source.id, 'source-2');
        expect(source.title, 'Chemistry Notes');
        expect(source.type, SourceType.document);
        expect(source.content, 'content body');
        expect(source.subjectId, 'subj-1');
        expect(source.topicId, 'topic-1');
        expect(source.syllabusId, 'syll-1');
        expect(source.sourceUrl, 'https://example.com');
        expect(source.studentId, 'student-1');
        expect(source.language, 'en');
        expect(source.summary, 'summary text');
        expect(source.processingStatus, 'completed');
        expect(source.extractedText, 'extracted');
        expect(source.generatedQuestionIds, ['q1', 'q2']);
        expect(source.extractionMethod, 'ocr');
        expect(source.chunks, '[]');
        expect(source.extractionMeta, '{"pages": 5}');
        expect(source.createdAt, createdAt);
      });

      test('applies default values for optional fields', () {
        final source = Source(
          id: 'source-1',
          title: 'Test',
          type: SourceType.pdf,
        );

        expect(source.content, '');
        expect(source.subjectId, '');
        expect(source.topicId, '');
        expect(source.syllabusId, '');
        expect(source.sourceUrl, '');
        expect(source.studentId, '');
        expect(source.language, '');
        expect(source.summary, '');
        expect(source.processingStatus, 'pending');
        expect(source.extractedText, '');
        expect(source.generatedQuestionIds, isEmpty);
        expect(source.extractionMethod, '');
        expect(source.chunks, '');
        expect(source.extractionMeta, '');
        expect(source.createdAt, isNull);
      });
    });

    group('statusEnum', () {
      test('returns ProcessingStatus.pending for default status', () {
        final source = Source(
          id: 'source-1',
          title: 'Test',
          type: SourceType.pdf,
        );
        expect(source.statusEnum, ProcessingStatus.pending);
      });

      test('returns ProcessingStatus when status matches', () {
        final source = Source(
          id: 'source-2',
          title: 'Test',
          type: SourceType.pdf,
          processingStatus: 'completed',
        );
        expect(source.statusEnum, ProcessingStatus.completed);
      });

      test('returns ProcessingStatus.pending for unknown status', () {
        final source = Source(
          id: 'source-3',
          title: 'Test',
          type: SourceType.pdf,
          processingStatus: 'unknown_status',
        );
        expect(source.statusEnum, ProcessingStatus.pending);
      });

      test('handles all processing statuses', () {
        for (final status in ProcessingStatus.values) {
          final source = Source(
            id: 'source-${status.name}',
            title: 'Test',
            type: SourceType.pdf,
            processingStatus: status.name,
          );
          expect(source.statusEnum, status);
        }
      });
    });

    group('toJson', () {
      test('serializes required fields correctly', () {
        final source = Source(
          id: 'source-1',
          title: 'Physics Textbook',
          type: SourceType.pdf,
        );

        final json = source.toJson();

        expect(json['id'], 'source-1');
        expect(json['title'], 'Physics Textbook');
        expect(json['type'], 'pdf');
        expect(json['content'], '');
        expect(json['subjectId'], '');
        expect(json['topicId'], '');
        expect(json['syllabusId'], '');
        expect(json['sourceUrl'], '');
        expect(json['studentId'], '');
        expect(json['language'], '');
        expect(json['summary'], '');
        expect(json['processingStatus'], 'pending');
        expect(json['extractedText'], '');
        expect(json['generatedQuestionIds'], <String>[]);
        expect(json['extractionMethod'], '');
        expect(json['chunks'], '');
        expect(json['extractionMeta'], '');
        expect(json['createdAt'], isNull);
      });

      test('serializes all fields correctly', () {
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final source = Source(
          id: 'source-2',
          title: 'Chemistry Notes',
          type: SourceType.document,
          content: 'body',
          subjectId: 'subj-1',
          topicId: 'topic-1',
          syllabusId: 'syll-1',
          sourceUrl: 'https://example.com',
          studentId: 'student-1',
          language: 'en',
          summary: 'summary',
          processingStatus: 'completed',
          extractedText: 'extracted',
          generatedQuestionIds: ['q1', 'q2'],
          extractionMethod: 'ocr',
          chunks: '[]',
          extractionMeta: '{}',
          createdAt: createdAt,
        );

        final json = source.toJson();

        expect(json['id'], 'source-2');
        expect(json['title'], 'Chemistry Notes');
        expect(json['type'], 'document');
      });
    });

    group('fromJson', () {
      test('parses required fields correctly', () {
        final json = {
          'id': 'source-1',
          'title': 'Physics Textbook',
          'type': 'pdf',
        };

        final source = Source.fromJson(json);

        expect(source.id, 'source-1');
        expect(source.title, 'Physics Textbook');
        expect(source.type, SourceType.pdf);
        expect(source.content, '');
        expect(source.processingStatus, 'pending');
      });

      test('parses all fields correctly', () {
        final json = {
          'id': 'source-2',
          'title': 'Chemistry Notes',
          'type': 'document',
          'content': 'body',
          'subjectId': 'subj-1',
          'topicId': 'topic-1',
          'syllabusId': 'syll-1',
          'sourceUrl': 'https://example.com',
          'studentId': 'student-1',
          'language': 'en',
          'summary': 'summary',
          'processingStatus': 'completed',
          'extractedText': 'extracted',
          'generatedQuestionIds': ['q1', 'q2'],
          'extractionMethod': 'ocr',
          'chunks': '[]',
          'extractionMeta': '{}',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final source = Source.fromJson(json);

        expect(source.id, 'source-2');
        expect(source.title, 'Chemistry Notes');
        expect(source.type, SourceType.document);
        expect(source.content, 'body');
        expect(source.subjectId, 'subj-1');
        expect(source.topicId, 'topic-1');
        expect(source.syllabusId, 'syll-1');
        expect(source.sourceUrl, 'https://example.com');
        expect(source.studentId, 'student-1');
        expect(source.language, 'en');
        expect(source.summary, 'summary');
        expect(source.processingStatus, 'completed');
        expect(source.extractedText, 'extracted');
        expect(source.generatedQuestionIds, ['q1', 'q2']);
        expect(source.extractionMethod, 'ocr');
        expect(source.chunks, '[]');
        expect(source.extractionMeta, '{}');
        expect(source.createdAt, DateTime(2024, 1, 15, 10, 30));
      });

      test('handles null createdAt', () {
        final json = {
          'id': 'source-1',
          'title': 'Test',
          'type': 'pdf',
          'createdAt': null,
        };

        final source = Source.fromJson(json);

        expect(source.createdAt, isNull);
      });

      test('handles null generatedQuestionIds', () {
        final json = {
          'id': 'source-1',
          'title': 'Test',
          'type': 'pdf',
          'generatedQuestionIds': null,
        };

        final source = Source.fromJson(json);

        expect(source.generatedQuestionIds, isEmpty);
      });

      test('handles unknown type, defaults to pdf', () {
        final json = {
          'id': 'source-1',
          'title': 'Test',
          'type': 'unknown',
        };

        final source = Source.fromJson(json);

        expect(source.type, SourceType.pdf);
      });

      test('handles missing type', () {
        final json = {
          'id': 'source-1',
          'title': 'Test',
        };

        final source = Source.fromJson(json);

        expect(source.type, SourceType.pdf);
      });

      test('parses video type from JSON', () {
        final json = {
          'id': 'source-v',
          'title': 'Video',
          'type': 'video',
        };

        final source = Source.fromJson(json);

        expect(source.type, SourceType.video);
      });

      test('defaults processingStatus to pending when not provided', () {
        final json = {
          'id': 'source-1',
          'title': 'Test',
          'type': 'pdf',
        };

        final source = Source.fromJson(json);

        expect(source.processingStatus, 'pending');
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        final original = Source(
          id: 'source-1',
          title: 'Physics',
          type: SourceType.pdf,
        );
        final copy = original.copyWith(id: 'source-2');

        expect(copy.id, 'source-2');
        expect(copy.title, 'Physics');
      });

      test('creates copy with updated title and type', () {
        final original = Source(
          id: 'source-1',
          title: 'Physics',
          type: SourceType.pdf,
        );
        final copy = original.copyWith(title: 'Chemistry', type: SourceType.document);

        expect(copy.title, 'Chemistry');
        expect(copy.type, SourceType.document);
        expect(original.title, 'Physics');
        expect(original.type, SourceType.pdf);
      });

      test('preserves original values when no params provided', () {
        final original = Source(
          id: 'source-1',
          title: 'Physics',
          type: SourceType.pdf,
          processingStatus: 'completed',
          generatedQuestionIds: ['q1'],
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.type, original.type);
        expect(copy.processingStatus, original.processingStatus);
        expect(copy.generatedQuestionIds, original.generatedQuestionIds);
      });

      test('returns new instance', () {
        final original = Source(
          id: 'source-1',
          title: 'Test',
          type: SourceType.pdf,
        );
        final copy = original.copyWith();

        expect(identical(original, copy), isFalse);
      });

      test('preserves createdAt when null is passed', () {
        final date = DateTime(2024, 1, 15);
        final original = Source(
          id: 's1', title: 'Test', type: SourceType.pdf,
          createdAt: date,
        );
        final copy = original.copyWith(createdAt: null);
        expect(copy.createdAt, date);
      });

      test('preserves generatedQuestionIds when null is passed', () {
        final original = Source(
          id: 's1', title: 'Test', type: SourceType.pdf,
          generatedQuestionIds: ['q1', 'q2'],
        );
        final copy = original.copyWith(generatedQuestionIds: null);
        expect(copy.generatedQuestionIds, ['q1', 'q2']);
      });
    });

    group('Hive annotations', () {
      test('extends HiveObject', () {
        final source = Source(id: 's1', title: 'Test', type: SourceType.pdf);
        expect(source, isA<HiveObject>());
      });
    });

    group('JSON round-trip', () {
      test('full round-trip preserves all fields', () {
        final original = Source(
          id: 'source-1',
          title: 'Physics Textbook',
          type: SourceType.pdf,
          content: 'full content',
          subjectId: 'subj-1',
          topicId: 'topic-1',
          syllabusId: 'syll-1',
          sourceUrl: 'https://example.com',
          studentId: 'student-1',
          language: 'en',
          summary: 'A summary',
          processingStatus: 'completed',
          extractedText: 'extracted text',
          generatedQuestionIds: ['q1', 'q2', 'q3'],
          extractionMethod: 'ocr',
          chunks: '[]',
          extractionMeta: '{"pages": 10}',
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        final json = original.toJson();
        final restored = Source.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.type, original.type);
        expect(restored.content, original.content);
        expect(restored.subjectId, original.subjectId);
        expect(restored.topicId, original.topicId);
        expect(restored.syllabusId, original.syllabusId);
        expect(restored.sourceUrl, original.sourceUrl);
        expect(restored.studentId, original.studentId);
        expect(restored.language, original.language);
        expect(restored.summary, original.summary);
        expect(restored.processingStatus, original.processingStatus);
        expect(restored.extractedText, original.extractedText);
        expect(restored.generatedQuestionIds, original.generatedQuestionIds);
        expect(restored.extractionMethod, original.extractionMethod);
        expect(restored.chunks, original.chunks);
        expect(restored.extractionMeta, original.extractionMeta);
        expect(restored.createdAt, original.createdAt);
      });

      test('round-trip with minimal fields', () {
        final original = Source(
          id: 'source-1',
          title: 'Test',
          type: SourceType.pdf,
        );

        final json = original.toJson();
        final restored = Source.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.type, original.type);
        expect(restored.processingStatus, original.processingStatus);
      });
    });
  });
}
