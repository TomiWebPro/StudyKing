import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/data/source_adapter.dart';
import '../../helpers/hive_test_utils.dart';

void main() {
  group('SourceAdapter', () {
    test('has correct typeId', () {
      final adapter = SourceAdapter();
      expect(adapter.typeId, 26);
    });

    test('is a TypeAdapter<Source>', () {
      final adapter = SourceAdapter();
      expect(adapter, isA<TypeAdapter<Source>>());
    });

    test('read and write round-trips a Source with all fields', () {
      final adapter = SourceAdapter();
      final now = DateTime.utc(2024, 6, 15, 10, 30);
      final source = Source(
        id: 'src1',
        title: 'Physics Textbook',
        type: SourceType.pdf,
        content: 'Full text content',
        subjectId: 'subj1',
        topicId: 'topic1',
        syllabusId: 'syll1',
        sourceUrl: 'https://example.com/book.pdf',
        studentId: 'student1',
        language: 'en',
        summary: 'A physics textbook',
        processingStatus: 'completed',
        extractedText: 'Extracted text here',
        generatedQuestionIds: ['q1', 'q2', 'q3'],
        extractionMethod: 'pdfExtract',
        chunks: 'chunk1,chunk2',
        extractionMeta: '{"pages": 10}',
        createdAt: now,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, source);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

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
      expect(restored.processingStatus, source.processingStatus);
      expect(restored.extractedText, source.extractedText);
      expect(restored.generatedQuestionIds, source.generatedQuestionIds);
      expect(restored.extractionMethod, source.extractionMethod);
      expect(restored.chunks, source.chunks);
      expect(restored.extractionMeta, source.extractionMeta);
      expect(restored.createdAt, source.createdAt);
    });

    test('read and write round-trips a Source with minimal fields', () {
      final adapter = SourceAdapter();
      final source = Source(
        id: 'src2',
        title: 'Quick Note',
        type: SourceType.document,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, source);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, source.id);
      expect(restored.title, source.title);
      expect(restored.type, source.type);
      expect(restored.content, '');
      expect(restored.subjectId, '');
      expect(restored.processingStatus, 'pending');
      expect(restored.generatedQuestionIds, []);
      expect(restored.createdAt, isNull);
    });

    test('read and write round-trips a Source with null createdAt', () {
      final adapter = SourceAdapter();
      final source = Source(
        id: 'src3',
        title: 'No Date',
        type: SourceType.image,
        createdAt: null,
      );

      final writeCache = <int, dynamic>{};
      final writer = TestBinaryWriter(writeCache);
      adapter.write(writer, source);

      final reader = TestBinaryReader(writeCache);
      final restored = adapter.read(reader);

      expect(restored.id, source.id);
      expect(restored.title, source.title);
      expect(restored.createdAt, isNull);
    });
  });
}
