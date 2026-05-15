import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('Source', () {
    test('creates with only required fields', () {
      final source = Source(
        id: 'src-1',
        title: 'Math Textbook',
        type: SourceType.textbook,
      );
      expect(source.id, 'src-1');
      expect(source.title, 'Math Textbook');
      expect(source.type, SourceType.textbook);
      expect(source.content, '');
      expect(source.subjectId, '');
      expect(source.topicId, '');
      expect(source.syllabusId, '');
      expect(source.sourceUrl, '');
      expect(source.studentId, '');
      expect(source.language, '');
      expect(source.summary, '');
    });

    test('creates with all named fields', () {
      final source = Source(
        id: 'src-2',
        title: 'Physics Video',
        type: SourceType.video,
        content: 'video content',
        subjectId: 'sub-1',
        topicId: 'topic-1',
        syllabusId: 'syl-1',
        sourceUrl: 'https://example.com',
        studentId: 'student-1',
        language: 'en',
        summary: 'video summary',
      );
      expect(source.id, 'src-2');
      expect(source.title, 'Physics Video');
      expect(source.type, SourceType.video);
      expect(source.content, 'video content');
      expect(source.subjectId, 'sub-1');
      expect(source.topicId, 'topic-1');
      expect(source.syllabusId, 'syl-1');
      expect(source.sourceUrl, 'https://example.com');
      expect(source.studentId, 'student-1');
      expect(source.language, 'en');
      expect(source.summary, 'video summary');
    });

    group('toJson / fromJson', () {
      test('roundtrip preserves all fields', () {
        final source = Source(
          id: 'src-3',
          title: 'Chemistry Notes',
          type: SourceType.lectureNotes,
          content: 'notes content',
          subjectId: 'sub-2',
          topicId: 'topic-2',
          syllabusId: 'syl-2',
          sourceUrl: 'https://chem.example.com',
          studentId: 'student-2',
          language: 'fr',
          summary: 'chemistry summary',
        );
        final json = source.toJson();
        final restored = Source.fromJson(json);
        expect(restored.id, source.id);
        expect(restored.title, source.title);
        expect(restored.type, source.type);
        expect(restored.content, source.content);
        expect(restored.subjectId, source.subjectId);
        expect(restored.topicId, source.topicId);
        expect(restored.syllabusId, source.syllabusId);
        expect(restored.sourceUrl, source.sourceUrl);
        expect(restored.studentId, source.studentId);
        expect(restored.language, source.language);
        expect(restored.summary, source.summary);
      });

      test('roundtrip with only required fields', () {
        final source = Source(id: 'src-4', title: 'Minimal', type: SourceType.pdf);
        final json = source.toJson();
        final restored = Source.fromJson(json);
        expect(restored.id, 'src-4');
        expect(restored.title, 'Minimal');
        expect(restored.type, SourceType.pdf);
        expect(restored.content, '');
      });

      test('toJson produces correct map', () {
        final source = Source(
          id: 'src-5',
          title: 'History Doc',
          type: SourceType.syllabus,
          content: 'content',
          subjectId: 'sub-3',
          topicId: 'topic-3',
          syllabusId: 'syl-3',
          sourceUrl: 'url',
          studentId: 's-1',
          language: 'de',
          summary: 'hist summary',
        );
        final json = source.toJson();
        expect(json['id'], 'src-5');
        expect(json['title'], 'History Doc');
        expect(json['type'], 'syllabus');
        expect(json['content'], 'content');
        expect(json['subjectId'], 'sub-3');
        expect(json['topicId'], 'topic-3');
        expect(json['syllabusId'], 'syl-3');
        expect(json['sourceUrl'], 'url');
        expect(json['studentId'], 's-1');
        expect(json['language'], 'de');
        expect(json['summary'], 'hist summary');
      });
    });

    group('fromJson edge cases', () {
      test('handles null title defaults to empty string', () {
        final json = <String, dynamic>{
          'id': 'src-null',
          'title': null,
          'type': 'pdf',
        };
        final source = Source.fromJson(json);
        expect(source.title, '');
        expect(source.type, SourceType.pdf);
      });

      test('handles null type defaults to pdf', () {
        final json = <String, dynamic>{
          'id': 'src-no-type',
          'title': 'No Type',
          'type': null,
        };
        final source = Source.fromJson(json);
        expect(source.type, SourceType.pdf);
      });

      test('handles invalid type string defaults to pdf', () {
        final json = <String, dynamic>{
          'id': 'src-bad-type',
          'title': 'Bad Type',
          'type': 'unknown_type_value',
        };
        final source = Source.fromJson(json);
        expect(source.type, SourceType.pdf);
      });

      test('handles null id defaults to empty string', () {
        final json = <String, dynamic>{
          'id': null,
          'title': 'No ID',
          'type': 'pdf',
        };
        final source = Source.fromJson(json);
        expect(source.id, '');
        expect(source.title, 'No ID');
      });

      test('handles missing id defaults to empty string', () {
        final json = <String, dynamic>{
          'title': 'Missing ID',
          'type': 'pdf',
        };
        final source = Source.fromJson(json);
        expect(source.id, '');
      });

      test('handles empty JSON map', () {
        final json = <String, dynamic>{};
        final source = Source.fromJson(json);
        expect(source.id, '');
        expect(source.title, '');
        expect(source.type, SourceType.pdf);
        expect(source.content, '');
      });

      test('handles missing fields with defaults', () {
        final json = <String, dynamic>{
          'id': 'src-missing',
          'title': 'Missing Fields',
          'type': 'video',
        };
        final source = Source.fromJson(json);
        expect(source.type, SourceType.video);
        expect(source.content, '');
        expect(source.subjectId, '');
        expect(source.topicId, '');
        expect(source.syllabusId, '');
        expect(source.sourceUrl, '');
        expect(source.studentId, '');
        expect(source.language, '');
        expect(source.summary, '');
      });

      test('handles all source types by name', () {
        for (final type in SourceType.values) {
          final json = <String, dynamic>{
            'id': 'src-$type',
            'title': type.name,
            'type': type.name,
          };
          final source = Source.fromJson(json);
          expect(source.type, type);
        }
      });
    });

    group('copyWith', () {
      test('returns identical object when no args', () {
        final source = Source(id: 's1', title: 'T1', type: SourceType.pdf);
        final copied = source.copyWith();
        expect(copied.id, 's1');
        expect(copied.title, 'T1');
        expect(copied.type, SourceType.pdf);
        expect(copied.content, '');
      });

      test('replaces single fields', () {
        final source = Source(id: 's1', title: 'T1', type: SourceType.pdf);
        expect(source.copyWith(id: 's2').id, 's2');
        expect(source.copyWith(title: 'T2').title, 'T2');
        expect(source.copyWith(type: SourceType.video).type, SourceType.video);
        expect(source.copyWith(content: 'new content').content, 'new content');
        expect(source.copyWith(subjectId: 'sub-x').subjectId, 'sub-x');
        expect(source.copyWith(topicId: 'topic-x').topicId, 'topic-x');
        expect(source.copyWith(syllabusId: 'syl-x').syllabusId, 'syl-x');
        expect(source.copyWith(sourceUrl: 'url-x').sourceUrl, 'url-x');
        expect(source.copyWith(studentId: 'stu-x').studentId, 'stu-x');
        expect(source.copyWith(language: 'lang-x').language, 'lang-x');
        expect(source.copyWith(summary: 'sum-x').summary, 'sum-x');
      });

      test('null fields keep original values', () {
        final source = Source(
          id: 's1',
          title: 'T1',
          type: SourceType.syllabus,
          content: 'orig',
          subjectId: 'sub',
          topicId: 'topic',
          syllabusId: 'syl',
          sourceUrl: 'url',
          studentId: 'stu',
          language: 'en',
          summary: 'sum',
        );
        final copied = source.copyWith(
          id: null,
          title: null,
          type: null,
          content: null,
          subjectId: null,
          topicId: null,
          syllabusId: null,
          sourceUrl: null,
          studentId: null,
          language: null,
          summary: null,
        );
        expect(copied.id, 's1');
        expect(copied.title, 'T1');
        expect(copied.type, SourceType.syllabus);
        expect(copied.content, 'orig');
        expect(copied.subjectId, 'sub');
        expect(copied.topicId, 'topic');
        expect(copied.syllabusId, 'syl');
        expect(copied.sourceUrl, 'url');
        expect(copied.studentId, 'stu');
        expect(copied.language, 'en');
        expect(copied.summary, 'sum');
      });

      test('does not mutate original', () {
        final source = Source(id: 's1', title: 'T1', type: SourceType.pdf);
        source.copyWith(id: 's2', title: 'T2', type: SourceType.video);
        expect(source.id, 's1');
        expect(source.title, 'T1');
        expect(source.type, SourceType.pdf);
      });
    });

    group('equality', () {
      test('uses identity-based equality (no override)', () {
        final a = Source(id: 's1', title: 'T', type: SourceType.pdf);
        final b = Source(id: 's1', title: 'T', type: SourceType.pdf);
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });
    });

    group('hashCode', () {
      test('is consistent across calls', () {
        final source = Source(id: 's1', title: 'T', type: SourceType.pdf);
        final hash = source.hashCode;
        expect(source.hashCode, hash);
      });
    });

    group('toString', () {
      test('returns default Object representation', () {
        final source = Source(id: 's1', title: 'T', type: SourceType.pdf);
        expect(source.toString(), contains('Instance of'));
      });
    });
  });
}
