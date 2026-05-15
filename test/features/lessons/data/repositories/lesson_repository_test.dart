import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/enums.dart';

class _MockLessonRepository extends LessonRepository {
  final Map<String, Lesson> _storage = {};
  final Map<String, LessonBlock> _blockStorage = {};

  @override
  Future<void> init() async {
  }

  @override
  Future<void> create(Lesson lesson) async {
    _storage[lesson.id] = lesson;
  }

  @override
  Future<Lesson?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<List<Lesson>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<List<Lesson>> getBySubject(String subjectId) async {
    return _storage.values.where((l) => l.subjectId == subjectId).toList();
  }

  @override
  Future<List<Lesson>> getByTopic(String topicId) async {
    return _storage.values.where((l) => l.topicId == topicId).toList();
  }

  @override
  Future<List<Lesson>> getBySubjectAndTopic(String subjectId, String topicId) async {
    return _storage.values
        .where((l) => l.subjectId == subjectId && l.topicId == topicId)
        .toList();
  }

  @override
  Future<void> addBlock(LessonBlock block) async {
    _blockStorage[block.id] = block;
  }

  @override
  Future<List<LessonBlock>> getBlocksForLesson(String lessonId) async {
    return _blockStorage.values.where((b) => b.lessonId == lessonId).toList();
  }

  @override
  Future<List<LessonBlock>> getBlocksBySubject(String subjectId) async {
    return _blockStorage.values.where((b) => b.subjectId == subjectId).toList();
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
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
    late _MockLessonRepository repository;

    setUp(() {
      repository = _MockLessonRepository();
    });

    group('create', () {
      test('stores a lesson', () async {
        final lesson = createTestLesson();
        await repository.create(lesson);
        final stored = await repository.get('lesson-1');
        expect(stored?.title, 'Test Lesson');
      });
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });
    });

    group('getAll', () {
      test('returns all lessons', () async {
        await repository.create(createTestLesson(id: 'l1'));
        await repository.create(createTestLesson(id: 'l2'));
        expect((await repository.getAll()).length, 2);
      });
    });

    group('getBySubject', () {
      test('returns lessons for subject', () async {
        await repository.create(createTestLesson(id: 'l1', subjectId: 's1'));
        await repository.create(createTestLesson(id: 'l2', subjectId: 's1'));
        await repository.create(createTestLesson(id: 'l3', subjectId: 's2'));
        expect((await repository.getBySubject('s1')).length, 2);
      });
    });

    group('getByTopic', () {
      test('returns lessons for topic', () async {
        await repository.create(createTestLesson(id: 'l1', topicId: 't1'));
        await repository.create(createTestLesson(id: 'l2', topicId: 't2'));
        expect((await repository.getByTopic('t1')).length, 1);
      });
    });

    group('getBySubjectAndTopic', () {
      test('returns filtered lessons', () async {
        await repository.create(createTestLesson(id: 'l1', subjectId: 's1', topicId: 't1'));
        await repository.create(createTestLesson(id: 'l2', subjectId: 's1', topicId: 't2'));
        expect((await repository.getBySubjectAndTopic('s1', 't1')).length, 1);
      });
    });

    group('addBlock', () {
      test('stores a lesson block', () async {
        final block = LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'Content');
        await repository.addBlock(block);
        final blocks = await repository.getBlocksForLesson('l1');
        expect(blocks.length, 1);
        expect(blocks.first.content, 'Content');
      });
    });

    group('getBlocksForLesson', () {
      test('returns blocks for lesson', () async {
        await repository.addBlock(LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        await repository.addBlock(LessonBlock(id: 'b2', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C2'));
        await repository.addBlock(LessonBlock(id: 'b3', subjectId: 's1', lessonId: 'l2', type: LessonBlockType.text, content: 'C3'));
        expect((await repository.getBlocksForLesson('l1')).length, 2);
      });
    });

    group('getBlocksBySubject', () {
      test('returns blocks for subject', () async {
        await repository.addBlock(LessonBlock(id: 'b1', subjectId: 's1', lessonId: 'l1', type: LessonBlockType.text, content: 'C1'));
        await repository.addBlock(LessonBlock(id: 'b2', subjectId: 's2', lessonId: 'l2', type: LessonBlockType.text, content: 'C2'));
        expect((await repository.getBlocksBySubject('s1')).length, 1);
      });
    });

    group('delete', () {
      test('removes lesson', () async {
        await repository.create(createTestLesson(id: 'l1'));
        await repository.delete('l1');
        expect(await repository.get('l1'), isNull);
      });
    });
  });
}
