import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';

class _TestSourceAdapter extends TypeAdapter<Source> {
  @override
  final int typeId = 26;

  @override
  Source read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    if (!map.containsKey('createdAt')) {
      map['createdAt'] = null;
    }
    return Source.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Source obj) {
    writer.write(obj.toJson());
  }
}

Source createTestSource({
  String id = 'src-1',
  String title = 'Test Source',
  SourceType type = SourceType.pdf,
  String content = '',
  String subjectId = '',
  String topicId = '',
  String syllabusId = '',
  String sourceUrl = '',
  String studentId = '',
  String language = '',
  String summary = '',
  String processingStatus = 'pending',
  String extractedText = '',
  List<String> generatedQuestionIds = const [],
  DateTime? createdAt,
}) {
  return Source(
    id: id,
    title: title,
    type: type,
    content: content,
    subjectId: subjectId,
    topicId: topicId,
    syllabusId: syllabusId,
    sourceUrl: sourceUrl,
    studentId: studentId,
    language: language,
    summary: summary,
    processingStatus: processingStatus,
    extractedText: extractedText,
    generatedQuestionIds: generatedQuestionIds,
    createdAt: createdAt,
  );
}

void main() {
  // =========================================================================
  // Unit Tests — real SourceRepository via attachBox
  // =========================================================================
  group('SourceRepository (unit)', () {
    late Box<Source> box;
    late SourceRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_source_unit_');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(26)) {
        Hive.registerAdapter(_TestSourceAdapter());
      }
      box = await Hive.openBox<Source>('source_test_box');
      repo = SourceRepository();
      repo.attachBox(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('source_test_box');
    });

    group('create', () {
      test('stores a source', () async {
        final source = Source(id: 's1', title: 'Test', type: SourceType.pdf);
        await repo.create(source);
        final storedResult = await repo.get('s1');
        expect(storedResult.data?.title, 'Test');
      });

      test('overwrites existing source with same id', () async {
        await repo.create(Source(id: 's1', title: 'Original', type: SourceType.pdf));
        await repo.create(Source(id: 's1', title: 'Updated', type: SourceType.pdf));
        expect((await repo.get('s1')).data?.title, 'Updated');
      });

      test('stores source with all fields', () async {
        final source = createTestSource(
          id: 'full-src',
          title: 'Full Source',
          type: SourceType.textbook,
          content: 'Full content',
          subjectId: 'sub-1',
          topicId: 'topic-1',
          syllabusId: 'syl-1',
          sourceUrl: 'https://example.com',
          studentId: 'stu-1',
          language: 'en',
          summary: 'Summary text',
        );
        await repo.create(source);
        final storedResult = await repo.get('full-src');
        expect(storedResult.data, isNotNull);
        final stored = storedResult.data!;
        expect(stored.title, 'Full Source');
        expect(stored.type, SourceType.textbook);
        expect(stored.content, 'Full content');
        expect(stored.subjectId, 'sub-1');
        expect(stored.topicId, 'topic-1');
        expect(stored.syllabusId, 'syl-1');
        expect(stored.sourceUrl, 'https://example.com');
        expect(stored.studentId, 'stu-1');
        expect(stored.language, 'en');
        expect(stored.summary, 'Summary text');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect((await repo.get('none')).data, isNull);
      });

      test('returns stored source', () async {
        await repo.create(Source(id: 's1', title: 'Test', type: SourceType.pdf));
        final result = await repo.get('s1');
        expect(result.data, isNotNull);
        expect(result.data?.id, 's1');
      });
    });

    group('getAll', () {
      test('returns all sources', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repo.create(Source(id: 's2', title: 'S2', type: SourceType.textbook));
        expect((await repo.getAll()).data?.length ?? 0, 2);
      });

      test('returns empty when no sources', () async {
        expect((await repo.getAll()).data ?? [], isEmpty);
      });

      test('sources survive across create calls', () async {
        await repo.create(Source(id: 'a', title: 'A', type: SourceType.pdf));
        await repo.create(Source(id: 'b', title: 'B', type: SourceType.video));
        final allResult = await repo.getAll();
        final all = allResult.data ?? [];
        expect(all.any((s) => s.id == 'a'), isTrue);
        expect(all.any((s) => s.id == 'b'), isTrue);
      });
    });

    group('getBySubject', () {
      test('returns sources for subject', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, subjectId: 'sub1'));
        await repo.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, subjectId: 'sub1'));
        await repo.create(Source(id: 's3', title: 'S3', type: SourceType.pdf, subjectId: 'sub2'));
        expect((await repo.getBySubject('sub1')).length, 2);
        expect((await repo.getBySubject('sub1')).every((s) => s.subjectId == 'sub1'), isTrue);
      });

      test('returns empty for non-existent subject', () async {
        expect(await repo.getBySubject('none'), isEmpty);
      });
    });

    group('getByTopic', () {
      test('returns sources for topic', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, topicId: 't1'));
        await repo.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, topicId: 't2'));
        expect((await repo.getByTopic('t1')).length, 1);
        expect((await repo.getByTopic('t1')).first.topicId, 't1');
      });

      test('returns empty for non-existent topic', () async {
        expect(await repo.getByTopic('none'), isEmpty);
      });

      test('returns sources with topicId empty string', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, topicId: ''));
        await repo.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, topicId: 't1'));
        expect((await repo.getByTopic('')).length, 1);
      });
    });

    group('getByStudent', () {
      test('returns sources for student', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, studentId: 'stu1'));
        await repo.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, studentId: 'stu2'));
        expect((await repo.getByStudent('stu1')).length, 1);
        expect((await repo.getByStudent('stu1')).first.studentId, 'stu1');
      });

      test('returns empty for non-existent student', () async {
        expect(await repo.getByStudent('none'), isEmpty);
      });
    });

    group('getByType', () {
      test('returns sources of the given type', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repo.create(Source(id: 's2', title: 'S2', type: SourceType.textbook));
        await repo.create(Source(id: 's3', title: 'S3', type: SourceType.pdf));
        final pdfSources = await repo.getByType('pdf');
        expect(pdfSources.length, 2);
        expect(pdfSources.every((s) => s.type == SourceType.pdf), isTrue);
      });

      test('returns empty when no sources match the type', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        final result = await repo.getByType('video');
        expect(result, isEmpty);
      });

      test('handles all SourceType values', () async {
        for (final type in SourceType.values) {
          await repo.create(Source(id: 'src-${type.name}', title: type.name, type: type));
        }
        for (final type in SourceType.values) {
          final results = await repo.getByType(type.name);
          expect(results.length, 1, reason: 'Expected 1 source for type ${type.name}');
          expect(results.first.type, type);
        }
      });

      test('case-sensitive type matching', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        final result = await repo.getByType('PDF');
        expect(result, isEmpty);
      });
    });

    group('getByStatus', () {
      test('returns sources with matching status', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'pending'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'completed'));
        final pending = await repo.getByStatus(ProcessingStatus.pending);
        expect(pending.length, 1);
        expect(pending.first.id, 's1');
      });

      test('handles all ProcessingStatus values', () async {
        for (final status in ProcessingStatus.values) {
          await repo.create(
            createTestSource(id: 'src-${status.name}', processingStatus: status.name),
          );
        }
        for (final status in ProcessingStatus.values) {
          final results = await repo.getByStatus(status);
          expect(results.length, 1,
              reason: 'Expected 1 source for status ${status.name}');
          expect(results.first.processingStatus, status.name);
        }
      });

      test('returns empty for status with no match', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'pending'));
        final results = await repo.getByStatus(ProcessingStatus.completed);
        expect(results, isEmpty);
      });

      test('statuses are distinct — no cross-contamination', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'pending'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'extracting'));
        await repo.create(createTestSource(id: 's3', processingStatus: 'classifying'));
        await repo.create(createTestSource(id: 's4', processingStatus: 'generatingQuestions'));
        await repo.create(createTestSource(id: 's5', processingStatus: 'validating'));
        await repo.create(createTestSource(id: 's6', processingStatus: 'completed'));
        await repo.create(createTestSource(id: 's7', processingStatus: 'failed'));

        for (final status in ProcessingStatus.values) {
          final results = await repo.getByStatus(status);
          expect(results.length, 1,
              reason: 'Expected exactly 1 source for status $status');
          expect(results.first.processingStatus, status.name);
        }
      });
    });

    group('getPending', () {
      test('returns only pending sources', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'pending'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'completed'));
        final pending = await repo.getPending();
        expect(pending.length, 1);
        expect(pending.first.id, 's1');
      });
    });

    group('getCompleted', () {
      test('returns only completed sources', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'completed'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'failed'));
        final completed = await repo.getCompleted();
        expect(completed.length, 1);
        expect(completed.first.id, 's1');
      });
    });

    group('getFailed', () {
      test('returns only failed sources', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'failed'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'pending'));
        final failed = await repo.getFailed();
        expect(failed.length, 1);
        expect(failed.first.id, 's1');
      });
    });

    group('delete', () {
      test('removes a source', () async {
        await repo.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repo.delete('s1');
        expect(await repo.get('s1'), isNull);
      });

      test('does nothing for non-existent', () async {
        await repo.delete('none');
      });

      test('does not affect other sources', () async {
        await repo.create(Source(id: 'keep', title: 'Keep', type: SourceType.pdf));
        await repo.create(Source(id: 'remove', title: 'Remove', type: SourceType.pdf));
        await repo.delete('remove');
        expect(await repo.get('keep'), isNotNull);
        expect(await repo.get('remove'), isNull);
      });
    });

    group('save (update via Repository base)', () {
      test('updates an existing source via save', () async {
        await repo.create(createTestSource(id: 'updatable', title: 'Original'));
        await repo.save('updatable', createTestSource(id: 'updatable', title: 'Updated'));
        final storedResult = await repo.get('updatable');
        expect(storedResult.data?.title, 'Updated');
      });
    });

    group('box getter', () {
      test('returns the attached box', () {
        expect(repo.box, same(box));
      });

      test('box is populated after creates', () async {
        await repo.create(Source(id: 'a', title: 'A', type: SourceType.pdf));
        await repo.create(Source(id: 'b', title: 'B', type: SourceType.pdf));
        expect(repo.box.length, 2);
      });
    });
  });

  // =========================================================================
  // Hive Integration Tests — real SourceRepository with init()
  // =========================================================================
  group('SourceRepository Hive integration', () {
    late String hivePath;
    late SourceRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_source_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(26)) {
        Hive.registerAdapter(_TestSourceAdapter());
      }
      repo = SourceRepository();
      await repo.init();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('init opens box and readies the repository', () async {
      expect(repo, isNotNull);
      expect((await repo.getAll()).data ?? [], isEmpty);
    });

    test('init is idempotent when called multiple times', () async {
      await repo.init();
      await repo.create(createTestSource(id: 's1'));
      final result = await repo.getAll();
      expect(result.data?.length ?? 0, 1);
    });

    test('box is available after init', () {
      expect(repo.box, isNotNull);
      expect(repo.box.name, 'sources');
    });

    group('create', () {
      test('stores a source and retrieves it', () async {
        await repo.create(createTestSource());
        final storedResult = await repo.get('src-1');
        expect(storedResult.data, isNotNull);
        final stored = storedResult.data!;
        expect(stored.title, 'Test Source');
        expect(stored.type, SourceType.pdf);
      });

      test('stores a source with all fields', () async {
        await repo.create(createTestSource(
          id: 'full-src',
          title: 'Full Source',
          type: SourceType.textbook,
          content: 'Full content',
          subjectId: 'sub-1',
          topicId: 'topic-1',
          syllabusId: 'syl-1',
          sourceUrl: 'https://example.com',
          studentId: 'stu-1',
          language: 'en',
          summary: 'Summary text',
        ));
        final storedResult = await repo.get('full-src');
        expect(storedResult.data, isNotNull);
        final stored = storedResult.data!;
        expect(stored.title, 'Full Source');
        expect(stored.type, SourceType.textbook);
        expect(stored.content, 'Full content');
        expect(stored.subjectId, 'sub-1');
        expect(stored.topicId, 'topic-1');
        expect(stored.syllabusId, 'syl-1');
        expect(stored.sourceUrl, 'https://example.com');
        expect(stored.studentId, 'stu-1');
        expect(stored.language, 'en');
        expect(stored.summary, 'Summary text');
      });

      test('overwrites existing source with same id', () async {
        await repo.create(createTestSource(id: 's1', title: 'Original'));
        await repo.create(createTestSource(id: 's1', title: 'Updated'));
        final storedResult = await repo.get('s1');
        expect(storedResult.data?.title, 'Updated');
      });

      test('stores multiple sources', () async {
        await repo.create(createTestSource(id: 'a'));
        await repo.create(createTestSource(id: 'b'));
        await repo.create(createTestSource(id: 'c'));
        expect((await repo.getAll()).data ?? [], hasLength(3));
      });
    });

    group('get', () {
      test('returns null for non-existent source', () async {
        expect((await repo.get('nonexistent')).data, isNull);
      });

      test('returns stored source by id', () async {
        await repo.create(createTestSource(id: 'find-me', title: 'Find Me'));
        final result = await repo.get('find-me');
        expect(result.data, isNotNull);
        expect(result.data!.id, 'find-me');
      });
    });

    group('getAll', () {
      test('returns empty list when no sources exist', () async {
        expect((await repo.getAll()).data ?? [], isEmpty);
      });

      test('returns all stored sources', () async {
        await repo.create(createTestSource(id: 's1'));
        await repo.create(createTestSource(id: 's2'));
        await repo.create(createTestSource(id: 's3'));
        final allResult = await repo.getAll();
        final all = allResult.data ?? [];
        expect(all.length, 3);
      });
    });

    group('getBySubject', () {
      test('returns sources matching the subject', () async {
        await repo.create(createTestSource(id: 's1', subjectId: 'math'));
        await repo.create(createTestSource(id: 's2', subjectId: 'math'));
        await repo.create(createTestSource(id: 's3', subjectId: 'physics'));
        final mathSources = await repo.getBySubject('math');
        expect(mathSources.length, 2);
        expect(mathSources.every((s) => s.subjectId == 'math'), isTrue);
      });

      test('returns empty when no sources match the subject', () async {
        await repo.create(createTestSource(id: 's1', subjectId: 'math'));
        final result = await repo.getBySubject('physics');
        expect(result, isEmpty);
      });
    });

    group('getByTopic', () {
      test('returns sources matching the topic', () async {
        await repo.create(createTestSource(id: 's1', topicId: 'algebra'));
        await repo.create(createTestSource(id: 's2', topicId: 'algebra'));
        await repo.create(createTestSource(id: 's3', topicId: 'geometry'));
        final algebraSources = await repo.getByTopic('algebra');
        expect(algebraSources.length, 2);
        expect(algebraSources.every((s) => s.topicId == 'algebra'), isTrue);
      });

      test('returns empty when no sources match the topic', () async {
        await repo.create(createTestSource(id: 's1', topicId: 'algebra'));
        final result = await repo.getByTopic('geometry');
        expect(result, isEmpty);
      });
    });

    group('getByStudent', () {
      test('returns sources matching the student', () async {
        await repo.create(createTestSource(id: 's1', studentId: 'stu1'));
        await repo.create(createTestSource(id: 's2', studentId: 'stu1'));
        await repo.create(createTestSource(id: 's3', studentId: 'stu2'));
        final stu1Sources = await repo.getByStudent('stu1');
        expect(stu1Sources.length, 2);
        expect(stu1Sources.every((s) => s.studentId == 'stu1'), isTrue);
      });

      test('returns empty when no sources match the student', () async {
        await repo.create(createTestSource(id: 's1', studentId: 'stu1'));
        final result = await repo.getByStudent('stu2');
        expect(result, isEmpty);
      });
    });

    group('getByType', () {
      test('returns sources of the given type', () async {
        await repo.create(createTestSource(id: 's1', type: SourceType.pdf));
        await repo.create(createTestSource(id: 's2', type: SourceType.textbook));
        await repo.create(createTestSource(id: 's3', type: SourceType.pdf));
        final pdfSources = await repo.getByType('pdf');
        expect(pdfSources.length, 2);
      });

      test('returns empty when no sources match the type', () async {
        await repo.create(createTestSource(id: 's1', type: SourceType.pdf));
        final result = await repo.getByType('video');
        expect(result, isEmpty);
      });

      test('distinguishes between different types', () async {
        await repo.create(createTestSource(id: 's1', type: SourceType.pdf));
        await repo.create(createTestSource(id: 's2', type: SourceType.syllabus));
        await repo.create(createTestSource(id: 's3', type: SourceType.video));
        await repo.create(createTestSource(id: 's4', type: SourceType.lectureNotes));
        await repo.create(createTestSource(id: 's5', type: SourceType.externalResource));
        await repo.create(createTestSource(id: 's6', type: SourceType.textbook));
        await repo.create(createTestSource(id: 's7', type: SourceType.image));
        await repo.create(createTestSource(id: 's8', type: SourceType.webPage));
        await repo.create(createTestSource(id: 's9', type: SourceType.audio));
        await repo.create(createTestSource(id: 's10', type: SourceType.document));
        expect(await repo.getByType('pdf'), hasLength(1));
        expect(await repo.getByType('syllabus'), hasLength(1));
        expect(await repo.getByType('video'), hasLength(1));
        expect(await repo.getByType('lectureNotes'), hasLength(1));
        expect(await repo.getByType('externalResource'), hasLength(1));
        expect(await repo.getByType('textbook'), hasLength(1));
        expect(await repo.getByType('image'), hasLength(1));
        expect(await repo.getByType('webPage'), hasLength(1));
        expect(await repo.getByType('audio'), hasLength(1));
        expect(await repo.getByType('document'), hasLength(1));
      });
    });

    group('getByStatus and convenience methods', () {
      test('getByStatus returns sources with matching status', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'extracting'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'classifying'));
        final extracting = await repo.getByStatus(ProcessingStatus.extracting);
        expect(extracting.length, 1);
        expect(extracting.first.id, 's1');
      });

      test('getPending returns only pending sources', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'pending'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'completed'));
        final pending = await repo.getPending();
        expect(pending.length, 1);
        expect(pending.first.id, 's1');
      });

      test('getCompleted returns only completed sources', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'completed'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'failed'));
        final completed = await repo.getCompleted();
        expect(completed.length, 1);
        expect(completed.first.id, 's1');
      });

      test('getFailed returns only failed sources', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'failed'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'pending'));
        final failed = await repo.getFailed();
        expect(failed.length, 1);
        expect(failed.first.id, 's1');
      });

      test('generatingQuestions status query works', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'generatingQuestions'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'pending'));
        final results = await repo.getByStatus(ProcessingStatus.generatingQuestions);
        expect(results.length, 1);
        expect(results.first.id, 's1');
      });

      test('validating status query works', () async {
        await repo.create(createTestSource(id: 's1', processingStatus: 'validating'));
        await repo.create(createTestSource(id: 's2', processingStatus: 'completed'));
        final results = await repo.getByStatus(ProcessingStatus.validating);
        expect(results.length, 1);
        expect(results.first.id, 's1');
      });
    });

    group('delete', () {
      test('removes a stored source', () async {
        await repo.create(createTestSource(id: 'to-delete'));
        expect((await repo.get('to-delete')).data, isNotNull);
        await repo.delete('to-delete');
        expect((await repo.get('to-delete')).data, isNull);
      });

      test('does not throw when deleting non-existent source', () async {
        await repo.create(createTestSource(id: 'existing'));
        await repo.delete('nonexistent');
        expect((await repo.get('existing')).data, isNotNull);
      });
    });

    group('save (update via Repository base)', () {
      test('updates an existing source via save', () async {
        await repo.create(createTestSource(id: 'updatable', title: 'Original'));
        await repo.save('updatable', createTestSource(id: 'updatable', title: 'Updated'));
        final storedResult = await repo.get('updatable');
        expect(storedResult.data?.title, 'Updated');
      });
    });
  });
}
