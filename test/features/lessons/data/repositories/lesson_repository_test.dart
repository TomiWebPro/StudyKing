import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';

class _FakeLessonRepository extends LessonRepository {
  final Map<String, Lesson> _storage = {};
  final Map<String, LessonBlock> _blockStorage = {};

  @override
  Future<void> init() async {
  }

  @override
  Future<Result<void>> create(Lesson lesson) async {
    _storage[lesson.id] = lesson;
    return Result.success(null);
  }

  @override
  Future<Result<Lesson?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<List<Lesson>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<List<Lesson>>> getBySubject(String subjectId) async {
    return Result.success(_storage.values.where((l) => l.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<Lesson>>> getByTopic(String topicId) async {
    return Result.success(_storage.values.where((l) => l.topicId == topicId).toList());
  }

  @override
  Future<Result<List<Lesson>>> getBySubjectAndTopic(String subjectId, String topicId) async {
    return Result.success(_storage.values
        .where((l) => l.subjectId == subjectId && l.topicId == topicId)
        .toList());
  }

  @override
  Future<Result<void>> addBlock(LessonBlock block) async {
    _blockStorage[block.id] = block;
    return Result.success(null);
  }

  @override
  Future<Result<List<LessonBlock>>> getBlocksForLesson(String lessonId) async {
    return Result.success(_blockStorage.values.where((b) => b.lessonId == lessonId).toList());
  }

  @override
  Future<Result<List<LessonBlock>>> getBlocksBySubject(String subjectId) async {
    return Result.success(_blockStorage.values.where((b) => b.subjectId == subjectId).toList());
  }

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }
}

class _TestLessonAdapter extends TypeAdapter<Lesson> {
  @override
  final int typeId = 7;

  @override
  Lesson read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    return Lesson.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Lesson obj) {
    writer.write(obj.toJson());
  }
}

class _TestLessonBlockAdapter extends TypeAdapter<LessonBlock> {
  @override
  final int typeId = 6;

  @override
  LessonBlock read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    return LessonBlock.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, LessonBlock obj) {
    writer.write(obj.toJson());
  }
}

Lesson createTestLesson({
  String id = 'lesson-1',
  String subjectId = 'sub-1',
  String title = 'Test Lesson',
  String topicId = 'topic-1',
}) {
  return Lesson(
    id: id,
    subjectId: subjectId,
    title: title,
    topicId: topicId,
    createdAt: DateTime(2026, 5, 12),
  );
}

void main() {
  group('LessonRepository', () {
    late _FakeLessonRepository repository;

    setUp(() {
      repository = _FakeLessonRepository();
    });

    group('create', () {
      test('stores a lesson', () async {
        final lesson = createTestLesson();
        await repository.create(lesson);
        final stored = await repository.get('lesson-1');
        expect(stored.data?.title, 'Test Lesson');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect((await repository.get('none')).data, isNull);
      });
    });

    group('getAll', () {
      test('returns all lessons', () async {
        await repository.create(createTestLesson(id: 'l1'));
        await repository.create(createTestLesson(id: 'l2'));
        expect((await repository.getAll()).data!.length, 2);
      });
    });

    group('getBySubject', () {
      test('returns lessons for subject', () async {
        await repository.create(createTestLesson(id: 'l1', subjectId: 's1'));
        await repository.create(createTestLesson(id: 'l2', subjectId: 's1'));
        await repository.create(createTestLesson(id: 'l3', subjectId: 's2'));
        expect((await repository.getBySubject('s1')).data!.length, 2);
      });
    });

    group('getByTopic', () {
      test('returns lessons for topic', () async {
        await repository.create(createTestLesson(id: 'l1', topicId: 't1'));
        await repository.create(createTestLesson(id: 'l2', topicId: 't2'));
        expect((await repository.getByTopic('t1')).data!.length, 1);
      });
    });

    group('getBySubjectAndTopic', () {
      test('returns filtered lessons', () async {
        await repository.create(createTestLesson(id: 'l1', subjectId: 's1', topicId: 't1'));
        await repository.create(createTestLesson(id: 'l2', subjectId: 's1', topicId: 't2'));
        expect((await repository.getBySubjectAndTopic('s1', 't1')).data!.length, 1);
      });
    });

    group('addBlock', () {
      test('stores a lesson block', () async {
        final block = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'Content');
        await repository.addBlock(block);
        final blocksResult = await repository.getBlocksForLesson('l1');
        expect(blocksResult.data!.length, 1);
        expect(blocksResult.data!.first.content, 'Content');
      });
    });

    group('getBlocksForLesson', () {
      test('returns blocks for lesson', () async {
        await repository.addBlock(LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        await repository.addBlock(LessonBlock(id: 'b2', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C2'));
        await repository.addBlock(LessonBlock(id: 'b3', subjectId: 's1', lessonId: 'l2', type: LessonBlockType.text, content: 'C3'));
        expect((await repository.getBlocksForLesson('l1')).data!.length, 2);
      });
    });

    group('getBlocksBySubject', () {
      test('returns blocks for subject', () async {
        await repository.addBlock(LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        await repository.addBlock(LessonBlock(id: 'b2', subjectId: 's2', lessonId: 'l2', type: LessonBlockType.text, content: 'C2'));
        expect((await repository.getBlocksBySubject('s1')).data!.length, 1);
      });
    });

    group('delete', () {
      test('removes lesson', () async {
        await repository.create(createTestLesson(id: 'l1'));
        await repository.delete('l1');
        expect((await repository.get('l1')).data, isNull);
      });
    });
  });

  group('LessonRepository Hive integration', () {
    late String hivePath;
    late LessonRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dir = await Directory.systemTemp.createTemp('hive_lesson_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(_TestLessonAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(_TestLessonBlockAdapter());
      }
      repo = LessonRepository();
      await repo.init();
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('init opens boxes and readies the repository', () async {
      expect(repo, isNotNull);
    });

    group('create', () {
      test('stores a lesson and retrieves it', () async {
        final lesson = createTestLesson();
        await repo.create(lesson);
        final stored = await repo.get('lesson-1');
        expect(stored.data, isNotNull);
        expect(stored.data!.title, 'Test Lesson');
        expect(stored.data!.subjectId, 'sub-1');
        expect(stored.data!.topicId, 'topic-1');
      });

      test('stores a lesson with all fields', () async {
        final lesson = Lesson(
          id: 'full-lesson',
          subjectId: 'sub-1',
          title: 'Full Lesson',
          topicId: 'topic-1',
          blocks: [
            LessonBlock(id: 'b1', subjectId: 'sub-1', lessonId: 'full-lesson', type: LessonBlockType.text, content: 'Block 1', order: 1),
          ],
          difficulty: 3,
          generatedBy: GeneratedBy.ai,
          createdAt: DateTime(2026, 5, 15),
          markscheme: 'Answer key',
        );
        await repo.create(lesson);
        final stored = await repo.get('full-lesson');
        expect(stored.data, isNotNull);
        expect(stored.data!.difficulty, 3);
        expect(stored.data!.generatedBy, GeneratedBy.ai);
        expect(stored.data!.markscheme, 'Answer key');
        expect(stored.data!.blocks.length, 1);
        expect(stored.data!.blocks.first.content, 'Block 1');
      });
    });

    group('get', () {
      test('returns null for non-existent lesson', () async {
        expect((await repo.get('nonexistent')).data, isNull);
      });
    });

    group('getAll', () {
      test('returns empty list when no lessons exist', () async {
        expect((await repo.getAll()).data, isEmpty);
      });

      test('returns all stored lessons', () async {
        await repo.create(createTestLesson(id: 'l1'));
        await repo.create(createTestLesson(id: 'l2'));
        await repo.create(createTestLesson(id: 'l3'));
        final all = await repo.getAll();
        expect(all.data!.length, 3);
      });
    });

    group('getBySubject', () {
      test('returns lessons matching the subject', () async {
        await repo.create(createTestLesson(id: 'l1', subjectId: 'math'));
        await repo.create(createTestLesson(id: 'l2', subjectId: 'math'));
        await repo.create(createTestLesson(id: 'l3', subjectId: 'physics'));
        final mathLessonsResult = await repo.getBySubject('math');
        expect(mathLessonsResult.isSuccess, isTrue);
        final mathLessons = mathLessonsResult.data!;
        expect(mathLessons.length, 2);
        expect(mathLessons.every((l) => l.subjectId == 'math'), isTrue);
      });

      test('returns empty when no lessons match the subject', () async {
        await repo.create(createTestLesson(id: 'l1', subjectId: 'math'));
        final result = await repo.getBySubject('physics');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getByTopic', () {
      test('returns lessons matching the topic', () async {
        await repo.create(createTestLesson(id: 'l1', topicId: 'algebra'));
        await repo.create(createTestLesson(id: 'l2', topicId: 'algebra'));
        await repo.create(createTestLesson(id: 'l3', topicId: 'geometry'));
        final algebraLessonsResult = await repo.getByTopic('algebra');
        expect(algebraLessonsResult.isSuccess, isTrue);
        final algebraLessons = algebraLessonsResult.data!;
        expect(algebraLessons.length, 2);
        expect(algebraLessons.every((l) => l.topicId == 'algebra'), isTrue);
      });

      test('returns empty when no lessons match the topic', () async {
        await repo.create(createTestLesson(id: 'l1', topicId: 'algebra'));
        final result = await repo.getByTopic('geometry');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getBySubjectAndTopic', () {
      test('returns lessons matching both subject and topic', () async {
        await repo.create(createTestLesson(id: 'l1', subjectId: 'math', topicId: 'algebra'));
        await repo.create(createTestLesson(id: 'l2', subjectId: 'math', topicId: 'geometry'));
        await repo.create(createTestLesson(id: 'l3', subjectId: 'physics', topicId: 'algebra'));
        final result = await repo.getBySubjectAndTopic('math', 'algebra');
        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'l1');
      });

      test('returns empty when no lessons match', () async {
        await repo.create(createTestLesson(id: 'l1', subjectId: 'math', topicId: 'algebra'));
        expect((await repo.getBySubjectAndTopic('physics', 'algebra')).data, isEmpty);
        expect((await repo.getBySubjectAndTopic('math', 'geometry')).data, isEmpty);
      });
    });

    group('addBlock', () {
      test('stores a lesson block when lesson exists', () async {
        await repo.create(createTestLesson(id: 'l1'));
        final block = LessonBlock(id: 'b1', subjectId: 'math', lessonId: 'l1', type: LessonBlockType.text, content: 'Content');
        final addResult = await repo.addBlock(block);
        expect(addResult.isSuccess, isTrue);
        final blocksResult = await repo.getBlocksForLesson('l1');
        expect(blocksResult.isSuccess, isTrue);
        final blocks = blocksResult.data!;
        expect(blocks.length, 1);
        expect(blocks.first.id, 'b1');
        expect(blocks.first.content, 'Content');
        expect(blocks.first.type, LessonBlockType.text);
      });

      test('stores a block with all fields when lesson exists', () async {
        await repo.create(createTestLesson(id: 'l1'));
        final block = LessonBlock(id: 'b2', subjectId: 'sub-1', lessonId: 'l1', type: LessonBlockType.example, content: 'Example', order: 5);
        final addResult = await repo.addBlock(block);
        expect(addResult.isSuccess, isTrue);
        final blocksResult = await repo.getBlocksForLesson('l1');
        expect(blocksResult.isSuccess, isTrue);
        final blocks = blocksResult.data!;
        expect(blocks.length, 1);
        expect(blocks.first.order, 5);
        expect(blocks.first.type, LessonBlockType.example);
      });

      test('returns failure when lesson does not exist', () async {
        final block = LessonBlock(id: 'b1', subjectId: 'math', lessonId: 'nonexistent', type: LessonBlockType.text, content: 'Content');
        final result = await repo.addBlock(block);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Lesson_not_found'));
      });
    });

    group('getBlocksForLesson', () {
      test('returns blocks for a specific lesson', () async {
        await repo.create(createTestLesson(id: 'l1'));
        await repo.create(createTestLesson(id: 'l2'));
        await repo.addBlock(LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        await repo.addBlock(LessonBlock(id: 'b2', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C2'));
        await repo.addBlock(LessonBlock(id: 'b3', subjectId: 's1', lessonId: 'l2', type: LessonBlockType.text, content: 'C3'));
        final blocksResult = await repo.getBlocksForLesson('l1');
        expect(blocksResult.isSuccess, isTrue);
        final List<LessonBlock> blocks = blocksResult.data!;
        expect(blocks.length, 2);
        final ids = blocks.map((b) => b.id).toSet();
        expect(ids, containsAll(['b1', 'b2']));
      });

      test('returns empty list when lesson does not exist', () async {
        final result = await repo.getBlocksForLesson('nonexistent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns empty list when lesson has no blocks', () async {
        await repo.create(createTestLesson(id: 'empty-lesson'));
        final result = await repo.getBlocksForLesson('empty-lesson');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('getBlocksBySubject', () {
      test('returns blocks for a specific subject', () async {
        await repo.create(createTestLesson(id: 'l1'));
        await repo.create(createTestLesson(id: 'l2'));
        await repo.create(createTestLesson(id: 'l3'));
        await repo.addBlock(LessonBlock(id: 'b1', subjectId: 'math', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        await repo.addBlock(LessonBlock(id: 'b2', subjectId: 'math', lessonId: 'l2', type: LessonBlockType.text, content: 'C2'));
        await repo.addBlock(LessonBlock(id: 'b3', subjectId: 'physics', lessonId: 'l3', type: LessonBlockType.text, content: 'C3'));
        final mathBlocksResult = await repo.getBlocksBySubject('math');
        expect(mathBlocksResult.isSuccess, isTrue);
        expect(mathBlocksResult.data!.length, 2);
      });

      test('returns empty when no blocks for subject', () async {
        await repo.create(createTestLesson(id: 'l1'));
        await repo.addBlock(LessonBlock(id: 'b1', subjectId: 'math', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        final result = await repo.getBlocksBySubject('physics');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('returns empty when no lessons exist', () async {
        final result = await repo.getBlocksBySubject('math');
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('delete', () {
      test('removes a stored lesson', () async {
        await repo.create(createTestLesson(id: 'to-delete'));
        expect((await repo.get('to-delete')).data, isNotNull);
        await repo.delete('to-delete');
        expect((await repo.get('to-delete')).data, isNull);
      });

      test('does not throw when deleting non-existent lesson', () async {
        await repo.create(createTestLesson(id: 'existing'));
        await repo.delete('nonexistent');
        expect((await repo.get('existing')).data, isNotNull);
      });
    });

    group('save (update)', () {
      test('updates an existing lesson via save', () async {
        await repo.create(createTestLesson(id: 'updatable', title: 'Original'));
        await repo.save('updatable', createTestLesson(id: 'updatable', title: 'Updated'));
        final stored = await repo.get('updatable');
        expect(stored.data?.title, 'Updated');
      });
    });
  });

  group('LessonRepository error handling', () {
    late _ThrowingLessonRepository throwingRepo;

    setUp(() {
      throwingRepo = _ThrowingLessonRepository();
    });

    group('init', () {
      test('error during init is logged and rethrown', () async {
        final repo = _FailingInitLessonRepository();
        await expectLater(repo.init(), throwsException);
      });
    });

    group('create', () {
      test('returns failure when save throws', () async {
        throwingRepo.throwOnSave = true;
        final lesson = createTestLesson();
        final result = await throwingRepo.create(lesson);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });

    group('getBySubject', () {
      test('returns failure when filterBy throws', () async {
        throwingRepo.throwOnFilterBy = true;
        final result = await throwingRepo.getBySubject('math');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });

    group('getByTopic', () {
      test('returns failure when filterBy throws', () async {
        throwingRepo.throwOnFilterBy = true;
        final result = await throwingRepo.getByTopic('algebra');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });

    group('getBySubjectAndTopic', () {
      test('returns failure when filterBy throws', () async {
        throwingRepo.throwOnFilterBy = true;
        final result = await throwingRepo.getBySubjectAndTopic('math', 'algebra');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });

    group('addBlock', () {
      test('returns failure when get throws', () async {
        throwingRepo.throwOnGet = true;
        final block = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C');
        final result = await throwingRepo.addBlock(block);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });

      test('returns failure when save throws after get succeeds', () async {
        throwingRepo.throwOnSave = true;
        throwingRepo.storedLesson = createTestLesson(id: 'l1');
        final block = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C');
        final result = await throwingRepo.addBlock(block);
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });

    group('getBlocksForLesson', () {
      test('returns failure when get throws', () async {
        throwingRepo.throwOnGet = true;
        final result = await throwingRepo.getBlocksForLesson('l1');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });

    group('getBlocksBySubject', () {
      test('returns failure when getAll throws', () async {
        throwingRepo.throwOnGetAll = true;
        final result = await throwingRepo.getBlocksBySubject('math');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
      });
    });
  });
}

class _FailingInitLessonRepository extends LessonRepository {
  @override
  Future<void> openBox(String boxName) async {
    throw Exception('Failed to open box');
  }
}

class _ThrowingLessonRepository extends LessonRepository {
  bool throwOnSave = false;
  bool throwOnGet = false;
  bool throwOnGetAll = false;
  bool throwOnFilterBy = false;
  Lesson? storedLesson;

  @override
  Future<Result<void>> save(String key, Lesson item) async {
    if (throwOnSave) throw Exception('Save error');
    return Result.success(null);
  }

  @override
  Future<Result<Lesson?>> get(String id) async {
    if (throwOnGet) throw Exception('Get error');
    return Result.success(storedLesson);
  }

  @override
  Future<Result<List<Lesson>>> getAll() async {
    if (throwOnGetAll) throw Exception('GetAll error');
    return Result.success([]);
  }

  @override
  List<Lesson> filterBy<K>(K Function(Lesson) getter, K value) {
    if (throwOnFilterBy) throw Exception('FilterBy error');
    return [];
  }
}
