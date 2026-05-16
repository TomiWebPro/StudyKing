import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/core/data/models/topic_model.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};
  bool _shouldThrow = false;

  void setShouldThrow(bool value) => _shouldThrow = value;

  @override
  Future<void> save(String key, Topic item) async {
    if (_shouldThrow) throw Exception('fail');
    _topics[key] = item;
  }

  @override
  Future<Topic?> get(String key) async {
    if (_shouldThrow) throw Exception('fail');
    return _topics[key];
  }

  @override
  Future<List<Topic>> getAll() async {
    if (_shouldThrow) throw Exception('fail');
    return _topics.values.toList();
  }

  @override
  Future<void> delete(String key) async {
    if (_shouldThrow) throw Exception('fail');
    _topics.remove(key);
  }
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
      final topic = Topic(id: 't1', subjectId: 's1', title: 'Test Topic', description: '', syllabusText: '', childTopicIds: []);
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
      expect(result, isNotNull);
      expect(result!.title, 'Test Topic');
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
  });
}
