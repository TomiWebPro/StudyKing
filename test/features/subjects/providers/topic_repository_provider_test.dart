import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
