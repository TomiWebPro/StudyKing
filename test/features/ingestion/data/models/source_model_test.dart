import 'package:flutter_test/flutter_test.dart';
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
      });

      test('accepts all optional fields', () {
        final source = Source(
          id: id, title: title, type: SourceType.video,
          content: content, subjectId: 'sub-1', topicId: 'topic-1',
          syllabusId: 'syl-1', sourceUrl: 'https://example.com',
          studentId: 'student-1', language: 'en', summary: 'Summary text',
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
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final source = Source(
          id: id, title: title, type: SourceType.syllabus,
          content: content, subjectId: 'sub-1', topicId: 'topic-1',
          syllabusId: 'syl-1', sourceUrl: 'https://example.com',
          studentId: 'student-1', language: 'en', summary: 'Summary',
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
      });
    });

    group('fromJson', () {
      test('deserializes all fields', () {
        final json = {
          'id': id, 'title': title, 'type': 'textbook',
          'content': content, 'subjectId': 'sub-1', 'topicId': 'topic-1',
          'syllabusId': 'syl-1', 'sourceUrl': 'https://example.com',
          'studentId': 'student-1', 'language': 'en', 'summary': 'Summary',
        };
        final source = Source.fromJson(json);
        expect(source.id, id);
        expect(source.type, SourceType.textbook);
        expect(source.content, content);
        expect(source.subjectId, 'sub-1');
        expect(source.language, 'en');
        expect(source.summary, 'Summary');
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
        );
        expect(copy.title, 'Updated Title');
        expect(copy.type, SourceType.video);
        expect(copy.language, 'es');
        expect(copy.id, id);
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
    });
  });
}
