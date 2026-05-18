import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool _shouldThrow = false;

  void setShouldThrow(bool value) => _shouldThrow = value;

  @override
  Future<Result<void>> create(Topic topic) async {
    if (_shouldThrow) throw Exception('fail');
    _topics[topic.id] = topic;
    return Result.success(null);
  }

  @override
  Future<Result<void>> put(String key, Topic item) async {
    if (_shouldThrow) throw Exception('fail');
    _topics[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<Topic?>> get(String key) async {
    if (_shouldThrow) throw Exception('fail');
    return Result.success(_topics[key]);
  }

  @override
  Future<Result<List<Topic>>> getAll() async {
    if (_shouldThrow) throw Exception('fail');
    return Result.success(_topics.values.toList());
  }

  @override
  Future<Result<void>> delete(String key) async {
    if (_shouldThrow) throw Exception('fail');
    _topics.remove(key);
    return Result.success(null);
  }

  @override
  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    if (_shouldThrow) throw Exception('fail');
    return Result.success(_topics.values.where((t) => t.subjectId == subjectId).toList());
  }

  @override
  Future<Result<List<Topic>>> getByParent(String parentId) async {
    if (_shouldThrow) throw Exception('fail');
    return Result.success(_topics.values.where((t) => t.parentId == parentId).toList());
  }

  @override
  Future<Result<List<Topic>>> getRootTopics() async {
    if (_shouldThrow) throw Exception('fail');
    return Result.success(_topics.values.where((t) => t.parentId == null).toList());
  }

  @override
  Future<Result<void>> init() async {
    return Result.success(null);
  }

  @override
  Future<Result<void>> addParent(Topic topic, String parentId) async {
    if (_shouldThrow) throw Exception('fail');
    final parent = _topics[parentId];
    if (parent != null) {
      final updated = topic.copyWith(
        parentId: parentId,
        subjectId: parent.subjectId,
      );
      await create(updated);
    }
    return Result.success(null);
  }
}

Topic _createTopic({
  required String id,
  required String subjectId,
  String? parentId,
}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: 'Topic $id',
    description: 'Description for $id',
    syllabusText: 'Syllabus for $id',
    childTopicIds: [],
    parentId: parentId,
  );
}

void main() {
  group('topicRepositoryProvider', () {
    test('creates a TopicRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(topicRepositoryProvider);
      expect(repo, isA<TopicRepository>());
    });

    test('returns the same instance on repeated reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo1 = container.read(topicRepositoryProvider);
      final repo2 = container.read(topicRepositoryProvider);
      expect(identical(repo1, repo2), isTrue);
    });

    test('can be overridden with fake repository', () async {
      final fakeRepo = _FakeTopicRepository();
      final topic = _createTopic(id: 't1', subjectId: 's1');
      await fakeRepo.put('t1', topic);

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      expect(repo, same(fakeRepo));
      final result = await repo.get('t1');
      expect(result.data, isNotNull);
      expect(result.data!.title, 'Topic t1');
    });

    test('propagates errors from repository', () {
      final fakeRepo = _FakeTopicRepository();
      fakeRepo.setShouldThrow(true);

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      expect(() async => await repo.get('t1'), throwsA(isA<Exception>()));
    });

    test('getBySubject works with override', () async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1'));

      await fakeRepo.put('t2', _createTopic(id: 't2', subjectId: 's1'));

      await fakeRepo.put('t3', _createTopic(id: 't3', subjectId: 's2'));


      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final result = await repo.getBySubject('s1');
      final subjectTopics = result.data ?? [];
      expect(subjectTopics, hasLength(2));
    });

    test('getByParent works with override', () async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1', parentId: 'p1'));

      await fakeRepo.put('t2', _createTopic(id: 't2', subjectId: 's1', parentId: 'p1'));

      await fakeRepo.put('t3', _createTopic(id: 't3', subjectId: 's1'));


      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final result = await repo.getByParent('p1');
      final children = result.data ?? [];
      expect(children, hasLength(2));
    });

    test('getRootTopics works with override', () async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1')); // root

      await fakeRepo.put('t2', _createTopic(id: 't2', subjectId: 's1', parentId: 't1')); // child

      await fakeRepo.put('t3', _createTopic(id: 't3', subjectId: 's1')); // root


      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final result = await repo.getRootTopics();
      final roots = result.data ?? [];
      expect(roots, hasLength(2));
    });

    test('create works through provider override', () async {
      final fakeRepo = _FakeTopicRepository();
      final topic = _createTopic(id: 't1', subjectId: 's1');

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.create(topic);
      final result = await repo.get('t1');
      expect(result.data, isNotNull);
      expect(result.data!.id, 't1');
    });

    test('save and getAll round-trip works through provider', () async {
      final fakeRepo = _FakeTopicRepository();
      final t1 = _createTopic(id: 't1', subjectId: 's1');
      final t2 = _createTopic(id: 't2', subjectId: 's1');

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.put('t1', t1);

      await repo.put('t2', t2);
      final all = await repo.getAll();
      expect(all.data, hasLength(2));
      expect(all.data!.map((t) => t.id), containsAll(['t1', 't2']));
    });

    test('addParent works through provider override', () async {
      final fakeRepo = _FakeTopicRepository();
      final parent = _createTopic(id: 'parent', subjectId: 's1');
      final child = _createTopic(id: 'child', subjectId: 's2');

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.put('parent', parent);
      await repo.addParent(child, 'parent');

      final stored = await repo.get('child');
      expect(stored.data, isNotNull);
      expect(stored.data!.parentId, 'parent');
      expect(stored.data!.subjectId, 's1');
    });

    test('multiple containers have independent provider state', () {
      final c1 = ProviderContainer();
      addTearDown(c1.dispose);
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);

      final repo1 = c1.read(topicRepositoryProvider);
      final repo2 = c2.read(topicRepositoryProvider);

      expect(repo1, isA<TopicRepository>());
      expect(repo2, isA<TopicRepository>());
      expect(identical(repo1, repo2), isFalse);
    });

    test('invalidate triggers re-creation on next read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(topicRepositoryProvider);
      container.invalidate(topicRepositoryProvider);
      final repo2 = container.read(topicRepositoryProvider);

      expect(repo1, isA<TopicRepository>());
      expect(repo2, isA<TopicRepository>());
      expect(identical(repo1, repo2), isFalse);
    });

    test('multiple invalidate cycles work correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(topicRepositoryProvider);
      container.invalidate(topicRepositoryProvider);
      final repo2 = container.read(topicRepositoryProvider);
      container.invalidate(topicRepositoryProvider);
      final repo3 = container.read(topicRepositoryProvider);

      expect(identical(repo1, repo2), isFalse);
      expect(identical(repo2, repo3), isFalse);
      expect(identical(repo1, repo3), isFalse);
    });

    test('invalidate without subsequent read does not create new instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(topicRepositoryProvider);
      container.invalidate(topicRepositoryProvider);
      // Read not called again; repo1 should still be valid
      expect(repo1, isA<TopicRepository>());
    });

    test('delete works through provider override', () async {
      final fakeRepo = _FakeTopicRepository();
      final topic = _createTopic(id: 't1', subjectId: 's1');
      await fakeRepo.put('t1', topic);

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.delete('t1');
      final result = await repo.get('t1');
      expect(result.data, isNull);
    });

    test('getAll works through provider override', () async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.put('t1', _createTopic(id: 't1', subjectId: 's1'));

      await fakeRepo.put('t2', _createTopic(id: 't2', subjectId: 's1'));
      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final all = await repo.getAll();
      expect(all.data, hasLength(2));
    });
  });

  group('topicRepositoryProvider (real Hive init)', () {
    late String hivePath;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('topic_provider_test_');
      hivePath = dir.path;
      Hive.init(hivePath);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(_TestTopicAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
    });

    test('real provider creates TopicRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      expect(repo, isA<TopicRepository>());
    });

    test('real provider supports singleton behavior', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(topicRepositoryProvider);
      final repo2 = container.read(topicRepositoryProvider);
      expect(identical(repo1, repo2), isTrue);
    });

    test('real provider invalidate creates new instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(topicRepositoryProvider);
      container.invalidate(topicRepositoryProvider);
      final repo2 = container.read(topicRepositoryProvider);
      expect(identical(repo1, repo2), isFalse);
    });

    test('real provider create and get round-trip', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.init();
      final topic = _createTopic(id: 'rt-1', subjectId: 'rs-1');
      await repo.create(topic);

      final result = await repo.get('rt-1');
      expect(result.data, isNotNull);
      expect(result.data!.id, 'rt-1');
    });

    test('real provider getBySubject returns filtered topics', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.init();
      await repo.create(_createTopic(id: 'rt-a', subjectId: 'rs-1'));
      await repo.create(_createTopic(id: 'rt-b', subjectId: 'rs-1'));
      await repo.create(_createTopic(id: 'rt-c', subjectId: 'rs-2'));

      final result1 = await repo.getBySubject('rs-1');
      final forSubject1 = result1.data ?? [];
      expect(forSubject1, hasLength(2));

      final result2 = await repo.getBySubject('rs-2');
      final forSubject2 = result2.data ?? [];
      expect(forSubject2, hasLength(1));

      final result3 = await repo.getBySubject('rs-3');
      final forSubject3 = result3.data ?? [];
      expect(forSubject3, isEmpty);
    });

    test('real provider getRootTopics returns only root topics', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.init();
      await repo.create(_createTopic(id: 'rt-root1', subjectId: 'rs-1'));
      await repo.create(_createTopic(id: 'rt-root2', subjectId: 'rs-1'));
      await repo.create(_createTopic(id: 'rt-child', subjectId: 'rs-1', parentId: 'rt-root1'));

      final result = await repo.getRootTopics();
      final roots = result.data ?? [];
      expect(roots, hasLength(2));
    });

    test('real provider getByParent returns children', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.init();
      await repo.create(_createTopic(id: 'rt-parent', subjectId: 'rs-1'));
      await repo.create(_createTopic(id: 'rt-child1', subjectId: 'rs-1', parentId: 'rt-parent'));
      await repo.create(_createTopic(id: 'rt-child2', subjectId: 'rs-1', parentId: 'rt-parent'));

      final result = await repo.getByParent('rt-parent');
      final children = result.data ?? [];
      expect(children, hasLength(2));
    });

    test('real provider addParent links topic to parent', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      await repo.init();
      final parent = _createTopic(id: 'rt-par', subjectId: 'rs-1');
      final child = _createTopic(id: 'rt-ch', subjectId: 'rs-2');
      await repo.create(parent);
      await repo.create(child);

      await repo.addParent(child, 'rt-par');
      final stored = await repo.get('rt-ch');
      expect(stored.data!.parentId, 'rt-par');
      expect(stored.data!.subjectId, 'rs-1');
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
