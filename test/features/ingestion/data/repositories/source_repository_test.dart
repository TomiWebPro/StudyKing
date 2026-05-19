import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';

class InMemorySourceRepository extends SourceRepository {
  final Map<String, Source> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> create(Source source) async {
    _store[source.id] = source;
  }

  @override
  Future<Result<Source?>> get(String id) async {
    return Result.success(_store[id]);
  }

  @override
  Future<Result<List<Source>>> getAll() async {
    return Result.success(_store.values.toList());
  }

  @override
  Future<Result<void>> save(String key, Source item) async {
    _store[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _store.remove(key);
    return Result.success(null);
  }

  @override
  Future<List<Source>> getBySubject(String subjectId) async {
    return _store.values.where((s) => s.subjectId == subjectId).toList();
  }

  @override
  Future<List<Source>> getByTopic(String topicId) async {
    return _store.values.where((s) => s.topicId == topicId).toList();
  }

  @override
  Future<List<Source>> getByStudent(String studentId) async {
    return _store.values.where((s) => s.studentId == studentId).toList();
  }

  @override
  Future<List<Source>> getByType(String sourceType) async {
    return _store.values.where((s) => s.type.name == sourceType).toList();
  }

  @override
  Future<List<Source>> getByStatus(ProcessingStatus status) async {
    return _store.values.where((s) => s.statusEnum == status).toList();
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
  group('InMemorySourceRepository', () {
    late InMemorySourceRepository repo;

    setUp(() {
      repo = InMemorySourceRepository();
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

      test('statuses are distinct', () async {
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
        expect((await repo.get('s1')).data, isNull);
      });

      test('does nothing for non-existent', () async {
        await repo.delete('none');
      });

      test('does not affect other sources', () async {
        await repo.create(Source(id: 'keep', title: 'Keep', type: SourceType.pdf));
        await repo.create(Source(id: 'remove', title: 'Remove', type: SourceType.pdf));
        await repo.delete('remove');
        final keepResult = await repo.get('keep');
        expect(keepResult.data, isNotNull);
        expect((await repo.get('remove')).data, isNull);
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

    group('error-state: store behavior', () {
      test('get on empty store returns null', () async {
        expect((await repo.get('missing')).data, isNull);
      });

      test('delete on missing key does not throw', () async {
        await repo.delete('nonexistent');
      });

      test('getAll on empty store returns empty list', () async {
        final result = await repo.getAll();
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });
}
