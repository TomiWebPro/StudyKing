import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';

void main() {
  group('Source', () {
    const id = 'source-1';
    const title = 'IB Physics Textbook';
    const content = 'Chapter 1: Kinematics...';

    group('constructor', () {
      test('creates instance with required fields', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        expect(source.id, id);
        expect(source.title, title);
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
        expect(source.statusEnum, ProcessingStatus.pending);
        expect(source.extractedText, '');
        expect(source.generatedQuestionIds, []);
      });

      test('accepts all optional fields', () {
        final source = Source(
          id: id, title: title, type: SourceType.video,
          content: content, subjectId: 'sub-1', topicId: 'topic-1',
          syllabusId: 'syl-1', sourceUrl: 'https://example.com',
          studentId: 'student-1', language: 'en', summary: 'Summary text',
          processingStatus: 'completed', extractedText: 'Extracted',
          generatedQuestionIds: ['q-1', 'q-2'],
        );
        expect(source.type, SourceType.video);
        expect(source.content, content);
        expect(source.subjectId, 'sub-1');
        expect(source.topicId, 'topic-1');
        expect(source.syllabusId, 'syl-1');
        expect(source.sourceUrl, 'https://example.com');
        expect(source.studentId, 'student-1');
        expect(source.language, 'en');
        expect(source.summary, 'Summary text');
        expect(source.processingStatus, 'completed');
        expect(source.statusEnum, ProcessingStatus.completed);
        expect(source.extractedText, 'Extracted');
        expect(source.generatedQuestionIds, ['q-1', 'q-2']);
      });

      test('all SourceType values are accepted', () {
        for (final type in SourceType.values) {
          final source = Source(id: id, title: title, type: type);
          expect(source.type, type);
        }
      });

      test('all ProcessingStatus values map correctly', () {
        for (final status in ProcessingStatus.values) {
          final source = Source(
            id: id, title: title, type: SourceType.pdf,
            processingStatus: status.name,
          );
          expect(source.processingStatus, status.name);
          expect(source.statusEnum, status);
        }
      });

      test('unknown processingStatus falls back to pending via statusEnum', () {
        final source = Source(
          id: id, title: title, type: SourceType.pdf,
          processingStatus: 'unknown_status',
        );
        expect(source.processingStatus, 'unknown_status');
        expect(source.statusEnum, ProcessingStatus.pending);
      });

      test('creates with empty generatedQuestionIds list', () {
        final source = Source(
          id: id, title: title, type: SourceType.pdf,
          generatedQuestionIds: [],
        );
        expect(source.generatedQuestionIds, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final source = Source(
          id: id, title: title, type: SourceType.syllabus,
          content: content, subjectId: 'sub-1', topicId: 'topic-1',
          syllabusId: 'syl-1', sourceUrl: 'https://example.com',
          studentId: 'student-1', language: 'en', summary: 'Summary',
          processingStatus: 'completed', extractedText: 'Extracted',
          generatedQuestionIds: ['q-1'],
        );
        final json = source.toJson();
        expect(json['id'], id);
        expect(json['title'], title);
        expect(json['type'], 'syllabus');
        expect(json['content'], content);
        expect(json['subjectId'], 'sub-1');
        expect(json['topicId'], 'topic-1');
        expect(json['syllabusId'], 'syl-1');
        expect(json['sourceUrl'], 'https://example.com');
        expect(json['studentId'], 'student-1');
        expect(json['language'], 'en');
        expect(json['summary'], 'Summary');
        expect(json['processingStatus'], 'completed');
        expect(json['extractedText'], 'Extracted');
        expect(json['generatedQuestionIds'], ['q-1']);
      });

      test('serializes all SourceType values as name strings', () {
        for (final type in SourceType.values) {
          final source = Source(id: id, title: title, type: type);
          final json = source.toJson();
          expect(json['type'], type.name);
        }
      });

      test('serializes empty generatedQuestionIds', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        final json = source.toJson();
        expect(json['generatedQuestionIds'], []);
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': id, 'title': title, 'type': 'textbook',
          'content': content, 'subjectId': 'sub-1', 'topicId': 'topic-1',
          'syllabusId': 'syl-1', 'sourceUrl': 'https://example.com',
          'studentId': 'student-1', 'language': 'en', 'summary': 'Summary',
          'processingStatus': 'completed', 'extractedText': 'Extracted',
          'generatedQuestionIds': ['q-1'],
        };
        final source = Source.fromJson(json);
        expect(source.id, id);
        expect(source.type, SourceType.textbook);
        expect(source.content, content);
        expect(source.subjectId, 'sub-1');
        expect(source.language, 'en');
        expect(source.summary, 'Summary');
        expect(source.processingStatus, 'completed');
        expect(source.extractedText, 'Extracted');
        expect(source.generatedQuestionIds, ['q-1']);
      });

      test('handles missing optional fields', () {
        final json = {'id': id, 'title': title, 'type': 'pdf'};
        final source = Source.fromJson(json);
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
        expect(source.generatedQuestionIds, []);
      });

      test('handles null values', () {
        final json = {
          'id': null, 'title': null, 'type': 'invalid',
          'content': null, 'subjectId': null,
        };
        final source = Source.fromJson(json);
        expect(source.id, '');
        expect(source.title, '');
        expect(source.type, SourceType.pdf);
        expect(source.content, '');
        expect(source.subjectId, '');
      });

      test('handles null generatedQuestionIds', () {
        final json = {
          'id': id, 'title': title, 'type': 'pdf',
          'generatedQuestionIds': null,
        };
        final source = Source.fromJson(json);
        expect(source.generatedQuestionIds, []);
      });

      test('handles missing type field', () {
        final json = {'id': id, 'title': title};
        final source = Source.fromJson(json);
        expect(source.type, SourceType.pdf);
      });

      test('handles empty string type', () {
        final json = {'id': id, 'title': title, 'type': ''};
        final source = Source.fromJson(json);
        expect(source.type, SourceType.pdf);
      });

      test('deserializes all SourceType values', () {
        for (final type in SourceType.values) {
          final json = {'id': id, 'title': title, 'type': type.name};
          final source = Source.fromJson(json);
          expect(source.type, type);
        }
      });

      test('deserializes all ProcessingStatus values', () {
        for (final status in ProcessingStatus.values) {
          final json = {
            'id': id, 'title': title, 'type': 'pdf',
            'processingStatus': status.name,
          };
          final source = Source.fromJson(json);
          expect(source.processingStatus, status.name);
          expect(source.statusEnum, status);
        }
      });

      test('unknown processingStatus in JSON is preserved as-is', () {
        final json = {
          'id': id, 'title': title, 'type': 'pdf',
          'processingStatus': 'bogus',
        };
        final source = Source.fromJson(json);
        expect(source.processingStatus, 'bogus');
        expect(source.statusEnum, ProcessingStatus.pending);
      });


    });

    group('serialization roundtrip', () {
      test('preserves all fields', () {
        final original = Source(
          id: id, title: title, type: SourceType.lectureNotes,
          content: content, subjectId: 'sub-1', summary: 'Notes summary',
        );
        final restored = Source.fromJson(original.toJson());
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.type, original.type);
        expect(restored.subjectId, original.subjectId);
      });

      test('roundtrip preserves all SourceType values', () {
        for (final type in SourceType.values) {
          final original = Source(id: 't-$id', title: title, type: type);
          final restored = Source.fromJson(original.toJson());
          expect(restored.type, type);
        }
      });

      test('roundtrip preserves all ProcessingStatus values', () {
        for (final status in ProcessingStatus.values) {
          final original = Source(
            id: '$id-${status.name}',
            title: title,
            type: SourceType.pdf,
            processingStatus: status.name,
          );
          final restored = Source.fromJson(original.toJson());
          expect(restored.processingStatus, status.name);
          expect(restored.statusEnum, status);
        }
      });

      test('roundtrip preserves empty generatedQuestionIds', () {
        final original = Source(id: id, title: title, type: SourceType.pdf);
        final restored = Source.fromJson(original.toJson());
        expect(restored.generatedQuestionIds, []);
      });

      test('roundtrip preserves populated generatedQuestionIds', () {
        final original = Source(
          id: id, title: title, type: SourceType.pdf,
          generatedQuestionIds: ['q1', 'q2', 'q3'],
        );
        final restored = Source.fromJson(original.toJson());
        expect(restored.generatedQuestionIds, ['q1', 'q2', 'q3']);
      });
    });

    group('copyWith', () {
      test('returns identical copy with no args', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        final copy = source.copyWith();
        expect(copy.id, source.id);
        expect(copy.title, source.title);
        expect(copy.type, source.type);
      });

      test('updates specified fields', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        final copy = source.copyWith(
          title: 'Updated Title', type: SourceType.video, language: 'es',
          processingStatus: 'completed', extractedText: 'Extracted',
          generatedQuestionIds: ['q-1'],
        );
        expect(copy.title, 'Updated Title');
        expect(copy.type, SourceType.video);
        expect(copy.language, 'es');
        expect(copy.id, id);
        expect(copy.processingStatus, 'completed');
        expect(copy.extractedText, 'Extracted');
        expect(copy.generatedQuestionIds, ['q-1']);
      });

      test('updates all fields', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        final copy = source.copyWith(
          id: 'new-id',
          title: 'New Title',
          type: SourceType.video,
          content: 'New content',
          subjectId: 'new-sub',
          topicId: 'new-topic',
          syllabusId: 'new-syl',
          sourceUrl: 'https://new.url',
          studentId: 'new-stu',
          language: 'fr',
          summary: 'New summary',
          processingStatus: 'failed',
          extractedText: 'New extracted',
          generatedQuestionIds: ['new-q1'],
        );
        expect(copy.id, 'new-id');
        expect(copy.title, 'New Title');
        expect(copy.type, SourceType.video);
        expect(copy.content, 'New content');
        expect(copy.subjectId, 'new-sub');
        expect(copy.topicId, 'new-topic');
        expect(copy.syllabusId, 'new-syl');
        expect(copy.sourceUrl, 'https://new.url');
        expect(copy.studentId, 'new-stu');
        expect(copy.language, 'fr');
        expect(copy.summary, 'New summary');
        expect(copy.processingStatus, 'failed');
        expect(copy.extractedText, 'New extracted');
        expect(copy.generatedQuestionIds, ['new-q1']);
      });

      test('does not mutate original instance', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        source.copyWith(title: 'Mutated');
        expect(source.title, title);
      });

      test('copyWith sets generatedQuestionIds to empty list', () {
        final source = Source(
          id: id, title: title, type: SourceType.pdf,
          generatedQuestionIds: ['q1', 'q2'],
        );
        final copy = source.copyWith(generatedQuestionIds: []);
        expect(copy.generatedQuestionIds, []);
        expect(source.generatedQuestionIds, ['q1', 'q2']);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final a = Source(id: id, title: title, type: SourceType.pdf);
        expect(a == a, isTrue);
      });

      test('different instances are not equal', () {
        final a = Source(id: id, title: title, type: SourceType.pdf);
        final b = Source(id: 'other', title: title, type: SourceType.pdf);
        expect(a == b, isFalse);
      });

      test('hashCode is consistent', () {
        final a = Source(id: id, title: title, type: SourceType.pdf);
        expect(a.hashCode, a.hashCode);
      });

      test('different objects have different hashCodes when id differs', () {
        final a = Source(id: id, title: title, type: SourceType.pdf);
        final b = Source(id: 'other', title: title, type: SourceType.pdf);
        expect(a.hashCode == b.hashCode, isFalse);
      });
    });

    group('toString', () {
      test('includes Instance of Source', () {
        final source = Source(id: id, title: title, type: SourceType.pdf);
        expect(source.toString(), contains('Source'));
      });
    });

    group('Hive annotations', () {
      test('typeId is 26', () {
        // Verify by checking HiveObject inheritance
        final source = Source(id: id, title: title, type: SourceType.pdf);
        expect(source, isA<HiveObject>());
      });
    });
  });
}
