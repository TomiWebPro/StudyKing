import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';

class _MockTopicRepository extends TopicRepository {
  final Map<String, Topic> _storage = {};

  @override
  Future<void> init() async {
  }

  @override
  Future<Topic?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<void> create(Topic topic) async {
    _storage[topic.id] = topic;
  }

  @override
  Future<List<Topic>> getAll() async {
    return _storage.values.toList();
  }

  @override
  Future<List<Topic>> getBySubject(String subjectId) async {
    return _storage.values.where((t) => t.subjectId == subjectId).toList();
  }

  @override
  Future<List<Topic>> getByParent(String parentId) async {
    return _storage.values.where((t) => t.parentId == parentId).toList();
  }

  @override
  Future<List<Topic>> getRootTopics() async {
    return _storage.values.where((t) => t.parentId == null).toList();
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> addParent(Topic topic, String parentId) async {
    final parent = await get(parentId);
    if (parent != null) {
      final updated = topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
      await create(updated);
    }
  }
}

Topic createTestTopic({
  String id = 'topic-1',
  String subjectId = 'subject-1',
  String title = 'Algebra',
  String description = 'Algebra description',
  String? parentId,
  int sortOrder = 0,
  String syllabusText = 'Syllabus',
}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: title,
    description: description,
    parentId: parentId,
    sortOrder: sortOrder,
    syllabusText: syllabusText,
  );
}

void main() {
  group('TopicRepository', () {
    late _MockTopicRepository repository;

    setUp(() {
      repository = _MockTopicRepository();
    });

    group('create', () {
      test('stores a topic', () async {
        final topic = createTestTopic();
        await repository.create(topic);
        expect(await repository.get('topic-1'), isNotNull);
      });
    });

    group('get', () {
      test('returns null for non-existent topic', () async {
        expect(await repository.get('non-existent'), isNull);
      });

      test('returns stored topic', () async {
        final topic = createTestTopic();
        await repository.create(topic);
        final result = await repository.get('topic-1');
        expect(result?.id, 'topic-1');
        expect(result?.title, 'Algebra');
      });
    });

    group('getAll', () {
      test('returns empty list when no topics', () async {
        expect(await repository.getAll(), isEmpty);
      });

      test('returns all topics', () async {
        await repository.create(createTestTopic(id: 't1', title: 'Algebra'));
        await repository.create(createTestTopic(id: 't2', title: 'Geometry'));
        final all = await repository.getAll();
        expect(all.length, 2);
      });
    });

    group('getBySubject', () {
      test('returns topics for subject', () async {
        await repository.create(createTestTopic(id: 't1', subjectId: 's1'));
        await repository.create(createTestTopic(id: 't2', subjectId: 's1'));
        await repository.create(createTestTopic(id: 't3', subjectId: 's2'));
        final result = await repository.getBySubject('s1');
        expect(result.length, 2);
      });

      test('returns empty for non-existent subject', () async {
        expect(await repository.getBySubject('none'), isEmpty);
      });
    });

    group('getByParent', () {
      test('returns topics with given parent', () async {
        await repository.create(createTestTopic(id: 't1', parentId: 'parent-1'));
        await repository.create(createTestTopic(id: 't2', parentId: 'parent-1'));
        await repository.create(createTestTopic(id: 't3'));
        final result = await repository.getByParent('parent-1');
        expect(result.length, 2);
      });

      test('returns empty for non-existent parent', () async {
        expect(await repository.getByParent('none'), isEmpty);
      });
    });

    group('getRootTopics', () {
      test('returns topics with no parent', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.create(createTestTopic(id: 't2', parentId: 'p1'));
        await repository.create(createTestTopic(id: 't3'));
        final result = await repository.getRootTopics();
        expect(result.length, 2);
        expect(result.every((t) => t.parentId == null), isTrue);
      });

      test('returns empty when no root topics', () async {
        await repository.create(createTestTopic(id: 't1', parentId: 'p1'));
        expect(await repository.getRootTopics(), isEmpty);
      });
    });

    group('addParent', () {
      test('sets parent on topic when parent exists', () async {
        final parent = createTestTopic(id: 'parent-1', subjectId: 's1', title: 'Parent');
        final child = createTestTopic(id: 'child-1', title: 'Child');
        await repository.create(parent);
        await repository.addParent(child, 'parent-1');
        final stored = await repository.get('child-1');
        expect(stored?.parentId, 'parent-1');
        expect(stored?.subjectId, 's1');
      });

      test('does nothing when parent does not exist', () async {
        final child = createTestTopic(id: 'child-1', title: 'Child');
        await repository.addParent(child, 'non-existent');
        expect(await repository.get('child-1'), isNull);
      });
    });

    group('delete', () {
      test('removes topic', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.delete('t1');
        expect(await repository.get('t1'), isNull);
      });
    });
  });
}
