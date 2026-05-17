import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<Result<void>> save(String key, Topic item) async {
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
  Future<List<Topic>> getBySubject(String subjectId) async {
    if (_shouldThrow) throw Exception('fail');
    return _topics.values.where((t) => t.subjectId == subjectId).toList();
  }

  @override
  Future<List<Topic>> getByParent(String parentId) async {
    if (_shouldThrow) throw Exception('fail');
    return _topics.values.where((t) => t.parentId == parentId).toList();
  }

  @override
  Future<List<Topic>> getRootTopics() async {
    if (_shouldThrow) throw Exception('fail');
    return _topics.values.where((t) => t.parentId == null).toList();
  }

  @override
  Future<void> create(Topic topic) async {
    if (_shouldThrow) throw Exception('fail');
    _topics[topic.id] = topic;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> addParent(Topic topic, String parentId) async {
    if (_shouldThrow) throw Exception('fail');
    final parent = _topics[parentId];
    if (parent != null) {
      final updated = topic.copyWith(
        parentId: parentId,
        subjectId: parent.subjectId,
      );
      await create(updated);
    }
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
      await fakeRepo.save('t1', topic);

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
      await fakeRepo.save('t1', _createTopic(id: 't1', subjectId: 's1'));
      await fakeRepo.save('t2', _createTopic(id: 't2', subjectId: 's1'));
      await fakeRepo.save('t3', _createTopic(id: 't3', subjectId: 's2'));

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final subjectTopics = await repo.getBySubject('s1');
      expect(subjectTopics, hasLength(2));
    });

    test('getByParent works with override', () async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.save('t1', _createTopic(id: 't1', subjectId: 's1', parentId: 'p1'));
      await fakeRepo.save('t2', _createTopic(id: 't2', subjectId: 's1', parentId: 'p1'));
      await fakeRepo.save('t3', _createTopic(id: 't3', subjectId: 's1'));

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final children = await repo.getByParent('p1');
      expect(children, hasLength(2));
    });

    test('getRootTopics works with override', () async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.save('t1', _createTopic(id: 't1', subjectId: 's1')); // root
      await fakeRepo.save('t2', _createTopic(id: 't2', subjectId: 's1', parentId: 't1')); // child
      await fakeRepo.save('t3', _createTopic(id: 't3', subjectId: 's1')); // root

      final container = ProviderContainer(
        overrides: [
          topicRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(topicRepositoryProvider);
      final roots = await repo.getRootTopics();
      expect(roots, hasLength(2));
    });

    testWidgets('provider is accessible in widget tree', (tester) async {
      final fakeRepo = _FakeTopicRepository();
      await fakeRepo.save('t1', _createTopic(id: 't1', subjectId: 's1'));

      String? topicTitle;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: _TopicReaderWidget(
              onRead: (repo) async {
                final topic = await repo.get('t1');
                topicTitle = topic.data?.title;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(topicTitle, 'Topic t1');
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
      await repo.save('t1', t1);
      await repo.save('t2', t2);

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
      await repo.save('parent', parent);
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
  });
}

class _TopicReaderWidget extends ConsumerStatefulWidget {
  final void Function(TopicRepository repo) onRead;

  const _TopicReaderWidget({required this.onRead});

  @override
  ConsumerState<_TopicReaderWidget> createState() => _TopicReaderWidgetState();
}

class _TopicReaderWidgetState extends ConsumerState<_TopicReaderWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(topicRepositoryProvider);
      widget.onRead(repo);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
