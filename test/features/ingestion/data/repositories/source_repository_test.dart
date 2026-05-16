import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/core/data/enums.dart';

class _MockSourceRepository extends SourceRepository {
  final Map<String, Source> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> create(Source source) async {
    _storage[source.id] = source;
  }

  @override
  Future<Source?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<Source>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<List<Source>> getBySubject(String subjectId) async {
    return _storage.values.where((s) => s.subjectId == subjectId).toList();
  }

  @override
  Future<List<Source>> getByTopic(String topicId) async {
    return _storage.values.where((s) => s.topicId == topicId).toList();
  }

  @override
  Future<List<Source>> getByStudent(String studentId) async {
    return _storage.values.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<List<Source>> getByType(String sourceType) async {
    return _storage.values.where((s) => s.type.name == sourceType).toList();
  }

  @override
  Future<List<Source>> getByStatus(ProcessingStatus status) async {
    return _storage.values.where((s) => s.statusEnum == status).toList();
  }

  @override
  Future<List<Source>> getPending() async {
    return getByStatus(ProcessingStatus.pending);
  }

  @override
  Future<List<Source>> getFailed() async {
    return getByStatus(ProcessingStatus.failed);
  }

  @override
  Future<List<Source>> getCompleted() async {
    return getByStatus(ProcessingStatus.completed);
  }
}

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
  );
}

void main() {
  group('SourceRepository', () {
    late _MockSourceRepository repository;

    setUp(() {
      repository = _MockSourceRepository();
    });

    group('create', () {
      test('stores a source', () async {
        final source = Source(id: 's1', title: 'Test', type: SourceType.pdf);
        await repository.create(source);
        final stored = await repository.get('s1');
        expect(stored?.title, 'Test');
      });

      test('overwrites existing source with same id', () async {
        await repository.create(Source(id: 's1', title: 'Original', type: SourceType.pdf));
        await repository.create(Source(id: 's1', title: 'Updated', type: SourceType.pdf));
        expect((await repository.get('s1'))?.title, 'Updated');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });

      test('returns stored source', () async {
        await repository.create(Source(id: 's1', title: 'Test', type: SourceType.pdf));
        final result = await repository.get('s1');
        expect(result, isNotNull);
        expect(result?.id, 's1');
      });
    });

    group('getAll', () {
      test('returns all sources', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.textbook));
        expect((await repository.getAll()).length, 2);
      });

      test('returns empty when no sources', () async {
        expect(await repository.getAll(), isEmpty);
      });
    });

    group('getBySubject', () {
      test('returns sources for subject', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, subjectId: 'sub1'));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, subjectId: 'sub1'));
        await repository.create(Source(id: 's3', title: 'S3', type: SourceType.pdf, subjectId: 'sub2'));
        expect((await repository.getBySubject('sub1')).length, 2);
      });

      test('returns empty for non-existent subject', () async {
        expect(await repository.getBySubject('none'), isEmpty);
      });
    });

    group('getByTopic', () {
      test('returns sources for topic', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, topicId: 't1'));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, topicId: 't2'));
        expect((await repository.getByTopic('t1')).length, 1);
      });

      test('returns empty for non-existent topic', () async {
        expect(await repository.getByTopic('none'), isEmpty);
      });
    });

    group('getByStudent', () {
      test('returns sources for student', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf, studentId: 'stu1'));
        await repository.create(Source(id: 's2', title: 'S2', type: SourceType.pdf, studentId: 'stu2'));
        expect((await repository.getByStudent('stu1')).length, 1);
      });

      test('returns empty for non-existent student', () async {
        expect(await repository.getByStudent('none'), isEmpty);
      });
    });

    group('delete', () {
      test('removes a source', () async {
        await repository.create(Source(id: 's1', title: 'S1', type: SourceType.pdf));
        await repository.delete('s1');
        expect(await repository.get('s1'), isNull);
      });

      test('does nothing for non-existent', () async {
        await repository.delete('none');
      });
    });

    group('status queries', () {
      test('getByStatus returns sources with matching status', () async {
        await repository.create(createTestSource(id: 's1', processingStatus: 'pending'));
        await repository.create(createTestSource(id: 's2', processingStatus: 'completed'));
        final pending = await repository.getByStatus(ProcessingStatus.pending);
        expect(pending.length, 1);
        expect(pending.first.id, 's1');
      });

      test('getPending returns only pending sources', () async {
        await repository.create(createTestSource(id: 's1', processingStatus: 'pending'));
        await repository.create(createTestSource(id: 's2', processingStatus: 'completed'));
        final pending = await repository.getPending();
        expect(pending.length, 1);
        expect(pending.first.id, 's1');
      });

      test('getCompleted returns only completed sources', () async {
        await repository.create(createTestSource(id: 's1', processingStatus: 'completed'));
        await repository.create(createTestSource(id: 's2', processingStatus: 'failed'));
        final completed = await repository.getCompleted();
        expect(completed.length, 1);
        expect(completed.first.id, 's1');
      });

      test('getFailed returns only failed sources', () async {
        await repository.create(createTestSource(id: 's1', processingStatus: 'failed'));
        await repository.create(createTestSource(id: 's2', processingStatus: 'pending'));
        final failed = await repository.getFailed();
        expect(failed.length, 1);
        expect(failed.first.id, 's1');
      });
    });
  });

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
      expect(await repo.getAll(), isEmpty);
    });

    test('init is idempotent when called multiple times', () async {
      await repo.init();
      await repo.create(createTestSource(id: 's1'));
      final result = await repo.getAll();
      expect(result.length, 1);
    });

    group('create', () {
      test('stores a source and retrieves it', () async {
        await repo.create(createTestSource());
        final stored = await repo.get('src-1');
        expect(stored, isNotNull);
        expect(stored!.title, 'Test Source');
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
        final stored = await repo.get('full-src');
        expect(stored, isNotNull);
        expect(stored!.title, 'Full Source');
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
        final stored = await repo.get('s1');
        expect(stored?.title, 'Updated');
      });
    });

    group('get', () {
      test('returns null for non-existent source', () async {
        expect(await repo.get('nonexistent'), isNull);
      });

      test('returns stored source by id', () async {
        await repo.create(createTestSource(id: 'find-me', title: 'Find Me'));
        final result = await repo.get('find-me');
        expect(result, isNotNull);
        expect(result!.id, 'find-me');
      });
    });

    group('getAll', () {
      test('returns empty list when no sources exist', () async {
        expect(await repo.getAll(), isEmpty);
      });

      test('returns all stored sources', () async {
        await repo.create(createTestSource(id: 's1'));
        await repo.create(createTestSource(id: 's2'));
        await repo.create(createTestSource(id: 's3'));
        final all = await repo.getAll();
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
        expect(await repo.getByType('pdf'), hasLength(1));
        expect(await repo.getByType('syllabus'), hasLength(1));
        expect(await repo.getByType('video'), hasLength(1));
        expect(await repo.getByType('lectureNotes'), hasLength(1));
        expect(await repo.getByType('externalResource'), hasLength(1));
        expect(await repo.getByType('textbook'), hasLength(1));
      });
    });

    group('delete', () {
      test('removes a stored source', () async {
        await repo.create(createTestSource(id: 'to-delete'));
        expect(await repo.get('to-delete'), isNotNull);
        await repo.delete('to-delete');
        expect(await repo.get('to-delete'), isNull);
      });

      test('does not throw when deleting non-existent source', () async {
        await repo.create(createTestSource(id: 'existing'));
        await repo.delete('nonexistent');
        expect(await repo.get('existing'), isNotNull);
      });
    });

    group('save (update via Repository base)', () {
      test('updates an existing source via save', () async {
        await repo.create(createTestSource(id: 'updatable', title: 'Original'));
        await repo.save('updatable', createTestSource(id: 'updatable', title: 'Updated'));
        final stored = await repo.get('updatable');
        expect(stored?.title, 'Updated');
      });
    });
  });
}
