import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _storage = {};

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<Topic?>> get(String id) async {
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<void>> create(Topic topic) async {
    _storage[topic.id] = topic;
    return Result.success(null);
  }

  @override
  Future<Result<List<Topic>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    return Result.success(_storage.values.where((t) => t.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<Topic>>> getByParent(String parentId) async {
    return Result.success(_storage.values.where((t) => t.parentId == parentId).toList());
  }

  @override
  Future<Result<List<Topic>>> getRootTopics() async {
    return Result.success(_storage.values.where((t) => t.parentId == null).toList());
  }

  @override
  Future<Result<void>> delete(String id) async {
    _storage.remove(id);
    return Result.success(null);
  }

  @override
  Future<Result<void>> addParent(Topic topic, String parentId) async {
    final getResult = await get(parentId);
    final parent = getResult.data;
    if (parent != null) {
      final updated = topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
      await create(updated);
    }
    return Result.success(null);
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
  List<String> childTopicIds = const [],
}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: title,
    description: description,
    parentId: parentId,
    sortOrder: sortOrder,
    syllabusText: syllabusText,
    childTopicIds: childTopicIds,
  );
}

void main() {
  group('TopicRepository', () {
    late _FakeTopicRepository repository;

    setUp(() {
      repository = _FakeTopicRepository();
    });

    group('create', () {
      test('stores a topic', () async {
        final topic = createTestTopic();
        await repository.create(topic);
        expect((await repository.get('topic-1')).data, isNotNull);
      });

      test('updates existing topic with same id', () async {
        await repository.create(createTestTopic(id: 't1', title: 'Original', subjectId: 's1'));
        await repository.create(createTestTopic(id: 't1', title: 'Updated', subjectId: 's1'));
        final result = await repository.get('t1');
        expect(result.data!.title, 'Updated');
      });

      test('preserves other topics when creating new one', () async {
        await repository.create(createTestTopic(id: 't1', title: 'A'));
        await repository.create(createTestTopic(id: 't2', title: 'B'));
        final all = await repository.getAll();
        expect(all.data!.length, 2);
      });

      test('stores multiple topics with unique ids', () async {
        await repository.create(createTestTopic(id: 't1', title: 'Algebra'));
        await repository.create(createTestTopic(id: 't2', title: 'Geometry'));
        await repository.create(createTestTopic(id: 't3', title: 'Calculus'));
        expect((await repository.getAll()).data, hasLength(3));
      });
    });

    group('get', () {
      test('returns null for non-existent topic', () async {
        expect((await repository.get('non-existent')).data, isNull);
      });

      test('returns stored topic', () async {
        final topic = createTestTopic();
        await repository.create(topic);
        final result = await repository.get('topic-1');
        expect(result.data?.id, 'topic-1');
        expect(result.data?.title, 'Algebra');
      });

      test('returns null for empty storage', () async {
        expect((await repository.get('anything')).data, isNull);
      });

      test('get returns correct topic when multiple exist', () async {
        await repository.create(createTestTopic(id: 't1', title: 'A'));
        await repository.create(createTestTopic(id: 't2', title: 'B'));
        await repository.create(createTestTopic(id: 't3', title: 'C'));
        expect((await repository.get('t2')).data!.title, 'B');
      });
    });

    group('getAll', () {
      test('returns empty list when no topics', () async {
        expect((await repository.getAll()).data, isEmpty);
      });

      test('returns all topics', () async {
        await repository.create(createTestTopic(id: 't1', title: 'Algebra'));
        await repository.create(createTestTopic(id: 't2', title: 'Geometry'));
        final all = await repository.getAll();
        expect(all.data!.length, 2);
      });

      test('returns new list instance each time', () async {
        await repository.create(createTestTopic(id: 't1', title: 'A'));
        final result1 = await repository.getAll();
        final result2 = await repository.getAll();
        expect(identical(result1, result2), isFalse);
      });

      test('modifying returned list does not affect repository', () async {
        await repository.create(createTestTopic(id: 't1', title: 'A'));
        final list = await repository.getAll();
        list.data!.clear();
        final result = await repository.getAll();
        expect(result.data!.length, 1);
      });
    });

    group('getBySubject', () {
      test('returns topics for subject', () async {
        await repository.create(createTestTopic(id: 't1', subjectId: 's1'));
        await repository.create(createTestTopic(id: 't2', subjectId: 's1'));
        await repository.create(createTestTopic(id: 't3', subjectId: 's2'));
        final result = await repository.getBySubject('s1');
        final topics = result.data ?? [];
        expect(topics.length, 2);
      });

      test('returns empty for non-existent subject', () async {
        final result = await repository.getBySubject('none');
        expect(result.data ?? [], isEmpty);
      });

      test('excludes topics from other subjects', () async {
        await repository.create(createTestTopic(id: 't1', subjectId: 's1'));
        await repository.create(createTestTopic(id: 't2', subjectId: 's2'));
        await repository.create(createTestTopic(id: 't3', subjectId: 's2'));
        final result = await repository.getBySubject('s2');
        final topics = result.data ?? [];
        expect(topics.length, 2);
        expect(topics.every((t) => t.subjectId == 's2'), isTrue);
      });

      test('excludes topics with different subjectId', () async {
        await repository.create(createTestTopic(id: 't1', subjectId: 'math'));
        await repository.create(createTestTopic(id: 't2', subjectId: 'science'));
        final result = await repository.getBySubject('math');
        final topics = result.data ?? [];
        expect(topics.length, 1);
        expect(topics.first.id, 't1');
      });

      test('returns empty list when no topics at all', () async {
        final result = await repository.getBySubject('any');
        expect(result.data ?? [], isEmpty);
      });
    });

    group('getByParent', () {
      test('returns topics with given parent', () async {
        await repository.create(createTestTopic(id: 't1', parentId: 'parent-1'));
        await repository.create(createTestTopic(id: 't2', parentId: 'parent-1'));
        await repository.create(createTestTopic(id: 't3'));
        final result = await repository.getByParent('parent-1');
        final topics = result.data ?? [];
        expect(topics.length, 2);
      });

      test('returns empty for non-existent parent', () async {
        final result = await repository.getByParent('none');
        expect(result.data ?? [], isEmpty);
      });

      test('excludes topics with null parentId', () async {
        await repository.create(createTestTopic(id: 't1', parentId: 'p1'));
        await repository.create(createTestTopic(id: 't2'));
        final result = await repository.getByParent('p1');
        final topics = result.data ?? [];
        expect(topics.length, 1);
        expect(topics.first.id, 't1');
      });

      test('excludes topics with different parentId', () async {
        await repository.create(createTestTopic(id: 't1', parentId: 'p1'));
        await repository.create(createTestTopic(id: 't2', parentId: 'p2'));
        final result = await repository.getByParent('p1');
        final topics = result.data ?? [];
        expect(topics.length, 1);
      });

      test('returns empty list when no topics exist', () async {
        final result = await repository.getByParent('p1');
        expect(result.data ?? [], isEmpty);
      });

      test('returns all children of the same parent', () async {
        for (int i = 0; i < 5; i++) {
          await repository.create(createTestTopic(id: 'child-$i', parentId: 'parent-1'));
        }
        final result = await repository.getByParent('parent-1');
        final topics = result.data ?? [];
        expect(topics.length, 5);
      });
    });

    group('getRootTopics', () {
      test('returns topics with no parent', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.create(createTestTopic(id: 't2', parentId: 'p1'));
        await repository.create(createTestTopic(id: 't3'));
        final result = await repository.getRootTopics();
        final topics = result.data ?? [];
        expect(topics.length, 2);
        expect(topics.every((t) => t.parentId == null), isTrue);
      });

      test('returns empty when no root topics', () async {
        await repository.create(createTestTopic(id: 't1', parentId: 'p1'));
        final result = await repository.getRootTopics();
        expect(result.data ?? [], isEmpty);
      });

      test('returns empty when no topics at all', () async {
        final result = await repository.getRootTopics();
        expect(result.data ?? [], isEmpty);
      });

      test('root topics are not affected by child topics', () async {
        await repository.create(createTestTopic(id: 'root-1'));
        await repository.create(createTestTopic(id: 'child-1', parentId: 'root-1'));
        await repository.create(createTestTopic(id: 'child-2', parentId: 'root-1'));
        final result = await repository.getRootTopics();
        final topics = result.data ?? [];
        expect(topics.length, 1);
        expect(topics.first.id, 'root-1');
      });

      test('handles mixed hierarchy correctly', () async {
        await repository.create(createTestTopic(id: 'r1'));
        await repository.create(createTestTopic(id: 'c1', parentId: 'r1'));
        await repository.create(createTestTopic(id: 'c2', parentId: 'c1'));
        await repository.create(createTestTopic(id: 'r2'));
        await repository.create(createTestTopic(id: 'c3', parentId: 'r2'));
        final result = await repository.getRootTopics();
        final topics = result.data ?? [];
        expect(topics.length, 2);
        expect(topics.map((t) => t.id), containsAll(['r1', 'r2']));
      });
    });

    group('addParent', () {
      test('sets parent on topic when parent exists', () async {
        final parent = createTestTopic(id: 'parent-1', subjectId: 's1', title: 'Parent');
        final child = createTestTopic(id: 'child-1', title: 'Child');
        await repository.create(parent);
        await repository.addParent(child, 'parent-1');
        final stored = await repository.get('child-1');
        expect(stored.data?.parentId, 'parent-1');
        expect(stored.data?.subjectId, 's1');
      });

      test('does nothing when parent does not exist', () async {
        final child = createTestTopic(id: 'child-1', title: 'Child');
        await repository.addParent(child, 'non-existent');
        expect((await repository.get('child-1')).data, isNull);
      });

      test('updates existing topic with new parent', () async {
        final parent = createTestTopic(id: 'parent-1', subjectId: 's1', title: 'Parent');
        await repository.create(parent);
        await repository.create(createTestTopic(id: 'child-1', title: 'Child', subjectId: 's1'));
        await repository.addParent(createTestTopic(id: 'child-1', title: 'Child'), 'parent-1');
        final stored = await repository.get('child-1');
        expect(stored.data?.parentId, 'parent-1');
      });

      test('inherits subjectId from parent', () async {
        final parent = createTestTopic(id: 'parent-1', subjectId: 'physics', title: 'Physics');
        final child = createTestTopic(id: 'child-1', title: 'Child', subjectId: 'old-subject');
        await repository.create(parent);
        await repository.addParent(child, 'parent-1');
        final stored = await repository.get('child-1');
        expect(stored.data?.subjectId, 'physics');
      });

      test('preserves existing fields when adding parent', () async {
        final parent = createTestTopic(id: 'parent-1', subjectId: 's1', title: 'Parent');
        final child = createTestTopic(
          id: 'child-1',
          title: 'Child Topic',
          description: 'Description text',
          sortOrder: 5,
          syllabusText: 'Syllabus content',
        );
        await repository.create(parent);
        await repository.addParent(child, 'parent-1');
        final stored = await repository.get('child-1');
        expect(stored.data?.title, 'Child Topic');
        expect(stored.data?.description, 'Description text');
        expect(stored.data?.sortOrder, 5);
        expect(stored.data?.syllabusText, 'Syllabus content');
      });
    });

    group('delete', () {
      test('removes topic', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.delete('t1');
        expect((await repository.get('t1')).data, isNull);
      });

      test('handles non-existent id gracefully', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.delete('non-existent');
        expect((await repository.get('t1')).data, isNotNull);
      });

      test('delete from empty storage does not throw', () async {
        await repository.delete('any');
      });

      test('delete on already-deleted id is safe', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.delete('t1');
        await repository.delete('t1');
        expect((await repository.getAll()).data, isEmpty);
      });

      test('deletes only specified topic', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.create(createTestTopic(id: 't2'));
        await repository.delete('t1');
        final remaining = await repository.getAll();
        expect(remaining.data!.length, 1);
        expect(remaining.data!.first.id, 't2');
      });

      test('delete all topics leaves empty storage', () async {
        await repository.create(createTestTopic(id: 't1'));
        await repository.create(createTestTopic(id: 't2'));
        await repository.create(createTestTopic(id: 't3'));
        await repository.delete('t1');
        await repository.delete('t2');
        await repository.delete('t3');
        expect((await repository.getAll()).data, isEmpty);
      });
    });

    group('save', () {
      test('save round-trip preserves all fields', () async {
        final topic = Topic(
          id: 'full-topic',
          subjectId: 'subject-1',
          title: 'Advanced Algebra',
          description: 'A comprehensive description',
          parentId: 'parent-1',
          sortOrder: 3,
          syllabusText: 'Full syllabus content',
          childTopicIds: ['child-1', 'child-2'],
        );
        await repository.create(topic);
        final retrieved = await repository.get('full-topic');
        expect(retrieved.data, isNotNull);
        expect(retrieved.data!.id, 'full-topic');
        expect(retrieved.data!.subjectId, 'subject-1');
        expect(retrieved.data!.title, 'Advanced Algebra');
        expect(retrieved.data!.description, 'A comprehensive description');
        expect(retrieved.data!.parentId, 'parent-1');
        expect(retrieved.data!.sortOrder, 3);
        expect(retrieved.data!.syllabusText, 'Full syllabus content');
        expect(retrieved.data!.childTopicIds, ['child-1', 'child-2']);
      });

      test('save preserves null parentId', () async {
        final topic = createTestTopic(id: 'null-parent', parentId: null);
        await repository.create(topic);
        final retrieved = await repository.get('null-parent');
        expect(retrieved.data!.parentId, isNull);
      });

      test('save preserves empty childTopicIds', () async {
        final topic = createTestTopic(id: 'no-children', childTopicIds: []);
        await repository.create(topic);
        final retrieved = await repository.get('no-children');
        expect(retrieved.data!.childTopicIds, isEmpty);
      });
    });

    group('Data integrity', () {
      test('save -> get -> save (update) -> get preserves fields', () async {
        await repository.create(createTestTopic(id: 't1', title: 'Original', sortOrder: 1));
        final g1 = await repository.get('t1');
        expect(g1.data!.title, 'Original');

        await repository.create(createTestTopic(id: 't1', title: 'Updated', sortOrder: 2));
        final g2 = await repository.get('t1');
        expect(g2.data!.title, 'Updated');
        expect(g2.data!.sortOrder, 2);
      });

      test('save -> delete -> save restores with new data', () async {
        await repository.create(createTestTopic(id: 'cyclic', title: 'Version 1', subjectId: 's1'));
        await repository.delete('cyclic');
        expect((await repository.get('cyclic')).data, isNull);

        await repository.create(createTestTopic(id: 'cyclic', title: 'Version 2', subjectId: 's2'));
        final restored = await repository.get('cyclic');
        expect(restored.data, isNotNull);
        expect(restored.data!.title, 'Version 2');
        expect(restored.data!.subjectId, 's2');
      });

      test('getAll returns consistent results after multiple operations', () async {
        for (int i = 0; i < 5; i++) {
          await repository.create(createTestTopic(id: 't$i', title: 'Topic $i', subjectId: 's1'));
        }
        expect((await repository.getAll()).data, hasLength(5));

        await repository.delete('t0');
        await repository.delete('t4');
        expect((await repository.getAll()).data, hasLength(3));

        await repository.create(createTestTopic(id: 't0', title: 'Topic 0 again', subjectId: 's1'));
        expect((await repository.getAll()).data, hasLength(4));
      });

      test('multiple operations in sequence work correctly', () async {
        await repository.create(createTestTopic(id: 'a', title: 'A', subjectId: 's1'));
        await repository.create(createTestTopic(id: 'b', title: 'B', subjectId: 's2'));

        expect((await repository.getBySubject('s1')).data ?? [], hasLength(1));
        expect((await repository.getBySubject('s2')).data ?? [], hasLength(1));

        await repository.delete('b');
        final result = await repository.getBySubject('s2');
        expect(result.data ?? [], isEmpty);
        expect((await repository.getAll()).data, hasLength(1));
      });

      test('addParent then getByParent returns correct topics', () async {
        final parent = createTestTopic(id: 'parent', subjectId: 's1', title: 'Parent');
        await repository.create(parent);

        for (int i = 0; i < 3; i++) {
          await repository.addParent(
            createTestTopic(id: 'child-$i', title: 'Child $i'),
            'parent',
          );
        }

        final result = await repository.getByParent('parent');
        final children = result.data ?? [];
        expect(children.length, 3);
      });
    });

    group('Edge cases', () {
      test('handles very long title', () async {
        final longTitle = 'A' * 1000;
        await repository.create(createTestTopic(id: 'long', title: longTitle, syllabusText: 'S'));
        final result = await repository.get('long');
        expect(result.data!.title.length, 1000);
      });

      test('handles very long syllabus text', () async {
        final longSyllabus = 'S' * 5000;
        await repository.create(createTestTopic(id: 'long-syllabus', title: 'T', syllabusText: longSyllabus));
        final result = await repository.get('long-syllabus');
        expect(result.data!.syllabusText.length, 5000);
      });

      test('handles many child topic IDs', () async {
        final manyChildren = List.generate(100, (i) => 'child-$i');
        await repository.create(createTestTopic(id: 'many-children', title: 'T', childTopicIds: manyChildren));
        final result = await repository.get('many-children');
        expect(result.data!.childTopicIds.length, 100);
      });

      test('handles topic with no optional fields', () async {
        final topic = Topic(id: 'minimal', subjectId: 's1', title: 'Minimal', description: '', syllabusText: '');
        await repository.create(topic);
        final result = await repository.get('minimal');
        expect(result.data, isNotNull);
        expect(result.data!.parentId, isNull);
        expect(result.data!.childTopicIds, isEmpty);
      });
    });

    group('Stress and bulk operations', () {
      test('getAll with many topics', () async {
        for (int i = 0; i < 100; i++) {
          await repository.create(createTestTopic(id: 't$i', title: 'Topic $i', subjectId: 's1'));
        }
        final all = await repository.getAll();
        expect(all.data!.length, 100);
      });

      test('sequential creates and deletes', () async {
        for (int i = 0; i < 50; i++) {
          await repository.create(createTestTopic(id: 't$i', title: 'Topic $i', subjectId: 's1'));
        }
        expect((await repository.getAll()).data, hasLength(50));

        for (int i = 0; i < 50; i++) {
          await repository.delete('t$i');
        }
        expect((await repository.getAll()).data, isEmpty);
      });

      test('getBySubject with many topics', () async {
        for (int i = 0; i < 50; i++) {
          await repository.create(createTestTopic(id: 't$i', title: 'Topic $i', subjectId: 's1'));
        }
        for (int i = 50; i < 100; i++) {
          await repository.create(createTestTopic(id: 't$i', title: 'Topic $i', subjectId: 's2'));
        }
        expect((await repository.getBySubject('s1')).data ?? [], hasLength(50));
        expect((await repository.getBySubject('s2')).data ?? [], hasLength(50));
      });
    });
  });

  group('TopicRepository - dependency graph operations', () {
    late TopicRepository repo;

    setUp(() {
      repo = TopicRepository();
    });

    group('getDependencyGraph', () {
      test('produces correct graph with dependencies', () async {
        final result = await repo.getDependencyGraph(
          ['t1', 't2', 't3'],
          {'t2': ['t1'], 't3': ['t1', 't2']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!['t1'], []);
        expect(result.data!['t2'], ['t1']);
        expect(result.data!['t3'], ['t1', 't2']);
      });

      test('returns empty lists for topics with no dependencies', () async {
        final result = await repo.getDependencyGraph(
          ['t1', 't2'],
          {},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!['t1'], []);
        expect(result.data!['t2'], []);
      });

      test('handles empty topic list', () async {
        final result = await repo.getDependencyGraph([], {});
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('excludes dependencies for topics not in topicIds', () async {
        final result = await repo.getDependencyGraph(
          ['t1'],
          {'t2': ['t1']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
        expect(result.data!.containsKey('t2'), isFalse);
      });

      test('includes topic even if it has no entry in dependencies map', () async {
        final result = await repo.getDependencyGraph(
          ['orphan'],
          {'other': ['some']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!['orphan'], []);
      });
    });

    group('getTopologicalOrder', () {
      test('returns correct order for a simple chain', () async {
        final result = await repo.getTopologicalOrder(
          ['t1', 't2', 't3'],
          {'t2': ['t1'], 't3': ['t2']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!.indexOf('t1'), lessThan(result.data!.indexOf('t2')));
        expect(result.data!.indexOf('t2'), lessThan(result.data!.indexOf('t3')));
      });

      test('handles single node', () async {
        final result = await repo.getTopologicalOrder(['t1'], {});
        expect(result.isSuccess, isTrue);
        expect(result.data!, ['t1']);
      });

      test('handles disconnected graph', () async {
        final result = await repo.getTopologicalOrder(
          ['t1', 't2', 't3'],
          {},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(3));
        expect(result.data, containsAll(['t1', 't2', 't3']));
      });

      test('handles empty topic list', () async {
        final result = await repo.getTopologicalOrder([], {});
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('cycle results in empty order (Kahn partial result)', () async {
        final result = await repo.getTopologicalOrder(
          ['t1', 't2'],
          {'t1': ['t2'], 't2': ['t1']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('complex DAG with multiple dependencies', () async {
        final result = await repo.getTopologicalOrder(
          ['t1', 't2', 't3', 't4'],
          {'t3': ['t1', 't2'], 't4': ['t3']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!.indexOf('t1'), lessThan(result.data!.indexOf('t3')));
        expect(result.data!.indexOf('t2'), lessThan(result.data!.indexOf('t3')));
        expect(result.data!.indexOf('t3'), lessThan(result.data!.indexOf('t4')));
      });

      test('multiple independent chains maintain ordering within each', () async {
        final result = await repo.getTopologicalOrder(
          ['a1', 'a2', 'b1', 'b2'],
          {'a2': ['a1'], 'b2': ['b1']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!.indexOf('a1'), lessThan(result.data!.indexOf('a2')));
        expect(result.data!.indexOf('b1'), lessThan(result.data!.indexOf('b2')));
        expect(result.data, hasLength(4));
      });

      test('fan-in: multiple prerequisites for one topic', () async {
        final result = await repo.getTopologicalOrder(
          ['a', 'b', 'c'],
          {'c': ['a', 'b']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!.indexOf('a'), lessThan(result.data!.indexOf('c')));
        expect(result.data!.indexOf('b'), lessThan(result.data!.indexOf('c')));
      });

      test('fan-out: one prerequisite for multiple topics', () async {
        final result = await repo.getTopologicalOrder(
          ['a', 'b', 'c'],
          {'b': ['a'], 'c': ['a']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data!.indexOf('a'), lessThan(result.data!.indexOf('b')));
        expect(result.data!.indexOf('a'), lessThan(result.data!.indexOf('c')));
      });
    });

    group('getDownstreamTopicIds', () {
      test('returns direct and indirect downstream topics', () async {
        final result = await repo.getDownstreamTopicIds(
          't1',
          {'t2': ['t1'], 't3': ['t2']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, containsAll(['t2', 't3']));
      });

      test('returns empty when no downstream topics', () async {
        final result = await repo.getDownstreamTopicIds('t1', {});
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('handles deep dependency chain', () async {
        final result = await repo.getDownstreamTopicIds(
          't1',
          {'t2': ['t1'], 't3': ['t2'], 't4': ['t3']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, ['t2', 't3', 't4']);
      });

      test('does not include topics that do not depend on the target', () async {
        final result = await repo.getDownstreamTopicIds(
          't1',
          {'t2': ['t1'], 't3': ['t2'], 't4': ['t5']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, containsAll(['t2', 't3']));
        expect(result.data, isNot(contains('t4')));
      });

      test('handles topic that is a downstream of multiple paths', () async {
        final result = await repo.getDownstreamTopicIds(
          't1',
          {'t2': ['t1'], 't3': ['t1'], 't4': ['t2', 't3']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, containsAll(['t2', 't3', 't4']));
      });

      test('does not include the target topic itself', () async {
        final result = await repo.getDownstreamTopicIds(
          't1',
          {'t1': ['t0']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('handles circular dependency gracefully', () async {
        final result = await repo.getDownstreamTopicIds(
          't1',
          {'t1': ['t2'], 't2': ['t1']},
        );
        expect(result.isSuccess, isTrue);
        expect(result.data, ['t2', 't1']);
      });
    });
  });

  group('TopicRepository (init with real Hive)', () {
    late TopicRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestTopicAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('topic_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = TopicRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('topics');
    });

    test('init opens box and supports CRUD', () async {
      final topic = createTestTopic(id: 'hive-1', title: 'Hive Test');
      await repository.create(topic);
      final stored = await repository.get('hive-1');
      expect(stored.data, isNotNull);
      expect(stored.data!.title, 'Hive Test');
    });

    test('init is idempotent when called multiple times', () async {
      await repository.init();
      await repository.init();
      await repository.create(createTestTopic(id: 't1', title: 'After re-init'));
      expect((await repository.get('t1')).data, isNotNull);
    });

    test('getAll returns empty after init', () async {
      expect((await repository.getAll()).data, isEmpty);
    });

    test('create and get round-trip preserves all fields', () async {
      final topic = Topic(
        id: 'full',
        subjectId: 's1',
        title: 'Full Topic',
        description: 'Full description',
        parentId: 'p1',
        sortOrder: 7,
        syllabusText: 'Full syllabus',
        childTopicIds: ['c1', 'c2'],
      );
      await repository.create(topic);
      final stored = await repository.get('full');
      expect(stored.data!.id, 'full');
      expect(stored.data!.subjectId, 's1');
      expect(stored.data!.title, 'Full Topic');
      expect(stored.data!.description, 'Full description');
      expect(stored.data!.parentId, 'p1');
      expect(stored.data!.sortOrder, 7);
      expect(stored.data!.syllabusText, 'Full syllabus');
      expect(stored.data!.childTopicIds, ['c1', 'c2']);
    });

    test('getBySubject works after init', () async {
      await repository.create(createTestTopic(id: 't1', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't2', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't3', subjectId: 's2'));
      expect((await repository.getBySubject('s1')).data ?? [], hasLength(2));
      expect((await repository.getBySubject('s2')).data ?? [], hasLength(1));
    });

    test('getBySubject returns empty for non-existent subject', () async {
      await repository.create(createTestTopic(id: 't1', subjectId: 's1'));
      final result = await repository.getBySubject('non-existent');
      expect(result.data ?? [], isEmpty);
    });

    test('getByParent works after init', () async {
      await repository.create(createTestTopic(id: 't1', parentId: 'p1', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't2', parentId: 'p1', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't3', parentId: 'p2', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't4', subjectId: 's1'));
      final result = await repository.getByParent('p1');
      final topics = result.data ?? [];
      expect(topics.length, 2);
      expect(topics.every((t) => t.parentId == 'p1'), isTrue);
    });

    test('getByParent returns empty for non-existent parent', () async {
      await repository.create(createTestTopic(id: 't1', parentId: 'p1', subjectId: 's1'));
      final result = await repository.getByParent('non-existent');
      expect(result.data ?? [], isEmpty);
    });

    test('getRootTopics works after init', () async {
      await repository.create(createTestTopic(id: 'root1', subjectId: 's1', title: 'Root 1'));
      await repository.create(createTestTopic(id: 'root2', subjectId: 's1', title: 'Root 2'));
      await repository.create(createTestTopic(id: 'child1', parentId: 'root1', subjectId: 's1', title: 'Child'));
      final result = await repository.getRootTopics();
      final topics = result.data ?? [];
      expect(topics.length, 2);
      expect(topics.every((t) => t.parentId == null), isTrue);
    });

    test('getRootTopics returns empty when all topics have parents', () async {
      await repository.create(createTestTopic(id: 'c1', parentId: 'p1', subjectId: 's1'));
      await repository.create(createTestTopic(id: 'c2', parentId: 'p1', subjectId: 's1'));
      final result = await repository.getRootTopics();
      expect(result.data ?? [], isEmpty);
    });

    test('getRootTopics returns empty when no topics exist', () async {
      final result = await repository.getRootTopics();
      expect(result.data ?? [], isEmpty);
    });

    test('addParent works after init', () async {
      final parent = createTestTopic(id: 'parent', subjectId: 's1', title: 'Parent');
      await repository.create(parent);
      final child = createTestTopic(id: 'child', title: 'Child', subjectId: 'old-subject');
      await repository.addParent(child, 'parent');
      final stored = await repository.get('child');
      expect(stored.data!.parentId, 'parent');
      expect(stored.data!.subjectId, 's1');
    });

    test('addParent does nothing when parent does not exist', () async {
      final child = createTestTopic(id: 'child', title: 'Child');
      await repository.addParent(child, 'non-existent');
      expect((await repository.get('child')).data, isNull);
    });

    test('addParent with null parentId child works', () async {
      final parent = createTestTopic(id: 'parent', subjectId: 's1', title: 'Parent');
      await repository.create(parent);
      final child = createTestTopic(id: 'child', title: 'Child');
      await repository.addParent(child, 'parent');
      final stored = await repository.get('child');
      expect(stored.data!.parentId, 'parent');
    });

    test('delete works after init', () async {
      await repository.create(createTestTopic(id: 'd1'));
      await repository.delete('d1');
      expect((await repository.get('d1')).data, isNull);
    });

    test('delete non-existent does not throw', () async {
      await repository.delete('non-existent');
    });

    test('getAll returns all stored topics', () async {
      await repository.create(createTestTopic(id: 't1', title: 'A', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't2', title: 'B', subjectId: 's1'));
      final all = await repository.getAll();
      expect(all.data!.length, 2);
    });

    test('create updates existing topic', () async {
      await repository.create(createTestTopic(id: 't1', title: 'Original', subjectId: 's1'));
      await repository.create(createTestTopic(id: 't1', title: 'Updated', subjectId: 's1'));
      final stored = await repository.get('t1');
      expect(stored.data!.title, 'Updated');
    });

    test('supports multiple topics and queries', () async {
      for (int i = 0; i < 5; i++) {
        await repository.create(createTestTopic(id: 'r$i', title: 'Root $i', subjectId: 's1'));
      }
      for (int i = 0; i < 10; i++) {
        final parentId = 'r${i % 5}';
        await repository.create(createTestTopic(id: 'c$i', title: 'Child $i', subjectId: 's1', parentId: parentId));
      }

      expect((await repository.getAll()).data, hasLength(15));
      expect((await repository.getRootTopics()).data ?? [], hasLength(5));
      expect((await repository.getByParent('r0')).data ?? [], hasLength(2));
      expect((await repository.getBySubject('s1')).data ?? [], hasLength(15));
    });
  });
}

class _TestTopicAdapter extends TypeAdapter<Topic> {
  @override
  final int typeId = 0;

  @override
  Topic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Topic(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      parentId: fields[4] as String?,
      sortOrder: fields[5] as int? ?? 0,
      syllabusText: fields[6] as String? ?? '',
      childTopicIds: (fields[7] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Topic obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(5)
      ..write(obj.sortOrder)
      ..writeByte(6)
      ..write(obj.syllabusText)
      ..writeByte(7)
      ..write(obj.childTopicIds);
  }
}
