import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/providers/subjects_repository_provider.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';

class FakeSubjectRepository extends SubjectRepository {
  final Map<String, Subject> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<Subject?>> get(String key) async =>
      Result.success(_storage[key]);

  @override
  Future<Result<List<Subject>>> getAll() async =>
      Result.success(_storage.values.toList());

  @override
  Future<Result<void>> save(String key, Subject item) async {
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _storage.remove(key);
    return Result.success(null);
  }
}

class TestSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  final FakeSubjectRepository _repo;
  bool buildCalled = false;

  TestSubjectsRepositoryNotifier(this._repo);

  @override
  Future<SubjectRepository> build() async {
    buildCalled = true;
    await Future.delayed(const Duration(milliseconds: 10));
    return _repo;
  }
}

class FailingSubjectsRepositoryNotifier extends SubjectsRepositoryNotifier {
  @override
  Future<SubjectRepository> build() async {
    await Future.delayed(const Duration(milliseconds: 10));
    throw Exception('Failed to initialize repository');
  }
}

class BuildCountingNotifier extends SubjectsRepositoryNotifier {
  final SubjectRepository repo;
  int buildCount = 0;

  BuildCountingNotifier(this.repo);

  @override
  Future<SubjectRepository> build() async {
    buildCount++;
    return repo;
  }
}

class _RecoverableNotifier extends SubjectsRepositoryNotifier {
  final VoidCallback onBuild;

  _RecoverableNotifier(this.onBuild);

  @override
  Future<SubjectRepository> build() async {
    onBuild();
    return FakeSubjectRepository();
  }
}

ProviderContainer _makeContainer(SubjectsRepositoryNotifier notifier) =>
    ProviderContainer(overrides: [subjectsRepositoryProvider.overrideWith(() => notifier)]);

class TestSubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 11;

  @override
  Subject read(BinaryReader reader) {
    final raw = reader.read() as Map;
    final map = <String, dynamic>{};
    for (final entry in raw.entries) {
      map['${entry.key}'] = entry.value;
    }
    return Subject.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer.write(obj.toJson());
  }
}

Subject _createSubject({
  required String id,
  String name = 'Test Subject',
  List<String>? topicIds,
}) {
  return Subject(
    id: id,
    name: name,
    topicIds: topicIds,
  );
}

void main() {
  group('subjectsRepositoryProvider', () {
    test('resolves SubjectRepository', () async {
      final c = _makeContainer(TestSubjectsRepositoryNotifier(FakeSubjectRepository()));
      expect(await c.read(subjectsRepositoryProvider.future), isA<SubjectRepository>());
      c.dispose();
    });

    test('shows loading before build', () {
      final c = _makeContainer(TestSubjectsRepositoryNotifier(FakeSubjectRepository()));
      expect(c.read(subjectsRepositoryProvider).isLoading, isTrue);
      c.dispose();
    });

    test('shows error on init failure', () async {
      final c = _makeContainer(FailingSubjectsRepositoryNotifier());
      try { await c.read(subjectsRepositoryProvider.future); } catch (_) {}
      expect(c.read(subjectsRepositoryProvider).hasError, isTrue);
      c.dispose();
    });

    test('returns same instance across reads', () async {
      final c = _makeContainer(TestSubjectsRepositoryNotifier(FakeSubjectRepository()));
      await c.read(subjectsRepositoryProvider.future);
      final a = c.read(subjectsRepositoryProvider).valueOrNull;
      final b = c.read(subjectsRepositoryProvider).valueOrNull;
      expect(identical(a, b), isTrue);
      c.dispose();
    });

    test('build method is called when provider is read', () async {
      final fakeRepo = FakeSubjectRepository();
      final notifier = TestSubjectsRepositoryNotifier(fakeRepo);
      final c = _makeContainer(notifier);
      expect(notifier.buildCalled, isFalse);
      await c.read(subjectsRepositoryProvider.future);
      expect(notifier.buildCalled, isTrue);
      c.dispose();
    });

    test('overridden fake repo is returned from provider', () async {
      final fakeRepo = FakeSubjectRepository();
      final notifier = TestSubjectsRepositoryNotifier(fakeRepo);
      final c = _makeContainer(notifier);
      final repo = await c.read(subjectsRepositoryProvider.future);
      expect(repo, same(fakeRepo));
      c.dispose();
    });

    test('error state contains exception message', () async {
      final c = _makeContainer(FailingSubjectsRepositoryNotifier());
      try { await c.read(subjectsRepositoryProvider.future); } catch (_) {}
      final asyncValue = c.read(subjectsRepositoryProvider);
      expect(asyncValue.hasError, isTrue);
      expect(asyncValue.error.toString(), contains('Failed to initialize repository'));
      c.dispose();
    });

    test('notifier disposes without error', () async {
      final notifier = TestSubjectsRepositoryNotifier(FakeSubjectRepository());
      final c = _makeContainer(notifier);
      await c.read(subjectsRepositoryProvider.future);
      expect(c.dispose, returnsNormally);
    });

    test('fake repo methods work through provider', () async {
      final fakeRepo = FakeSubjectRepository();
      final notifier = TestSubjectsRepositoryNotifier(fakeRepo);
      final c = _makeContainer(notifier);
      final repo = await c.read(subjectsRepositoryProvider.future);

      final all = await repo.getAll();
      expect(all.data, isEmpty);

      await repo.save('subj-1', _createSubject(id: 'subj-1', name: 'Physics'));
      final saved = await repo.get('subj-1');
      expect(saved.data, isNotNull);
      expect(saved.data!.name, 'Physics');

      await repo.delete('subj-1');
      final afterDelete = await repo.get('subj-1');
      expect(afterDelete.data, isNull);
      c.dispose();
    });

    test('invalidate triggers rebuild on next read', () async {
      final fakeRepo = FakeSubjectRepository();
      final notifier = BuildCountingNotifier(fakeRepo);
      final c = _makeContainer(notifier);
      expect(notifier.buildCount, equals(0));

      await c.read(subjectsRepositoryProvider.future);
      expect(notifier.buildCount, equals(1));

      c.invalidate(subjectsRepositoryProvider);
      expect(notifier.buildCount, equals(1));

      await c.read(subjectsRepositoryProvider.future);
      expect(notifier.buildCount, equals(2));
      c.dispose();
    });

    test('invalidate delivers a new repository instance', () async {
      final fakeRepo1 = FakeSubjectRepository();
      final notifier = BuildCountingNotifier(fakeRepo1);
      final c = _makeContainer(notifier);

      final repo1 = await c.read(subjectsRepositoryProvider.future);
      expect(repo1, same(fakeRepo1));

      c.invalidate(subjectsRepositoryProvider);
      final repo2 = await c.read(subjectsRepositoryProvider.future);
      expect(repo2, same(fakeRepo1));
      expect(identical(repo1, repo2), isTrue);
      c.dispose();
    });

    test('error state can be recovered by invalidate', () async {
      int attempt = 0;
      final c = ProviderContainer(overrides: [
        subjectsRepositoryProvider.overrideWith(() => _RecoverableNotifier(() {
              attempt++;
              if (attempt == 1) throw Exception('First attempt fails');
            })),
      ]);
      addTearDown(c.dispose);

      try {
        await c.read(subjectsRepositoryProvider.future);
      } catch (_) {}
      expect(c.read(subjectsRepositoryProvider).hasError, isTrue);

      c.invalidate(subjectsRepositoryProvider);
      final repo = await c.read(subjectsRepositoryProvider.future);
      expect(repo, isA<SubjectRepository>());
      expect(c.read(subjectsRepositoryProvider).hasError, isFalse);
    });
  });

  group('subjectsRepositoryProvider (real Hive init)', () {
    late String hivePath;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('subjects_provider_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(TestSubjectAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
    });

    test('real build() creates SubjectRepository with init', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      expect(repo, isA<SubjectRepository>());
      final subjects = await repo.getAll();
      expect(subjects.data, isEmpty);
    });

    test('real build() supports CRUD after init', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final subject = _createSubject(id: 'test-1', name: 'Physics');
      await repo.save('test-1', subject);

      final retrieved = await repo.get('test-1');
      expect(retrieved.data, isNotNull);
      expect(retrieved.data!.name, 'Physics');
      expect((await repo.getAll()).data, hasLength(1));

      await repo.delete('test-1');
      expect((await repo.get('test-1')).data, isNull);
    });

    test('real build() returns same instance on repeated reads', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subjectsRepositoryProvider.future);
      final a = container.read(subjectsRepositoryProvider).valueOrNull;
      final b = container.read(subjectsRepositoryProvider).valueOrNull;
      expect(identical(a, b), isTrue);
    });

    test('create() persists subject through real provider', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final subject = _createSubject(id: 'create-1', name: 'Chemistry');
      await repo.create(subject);

      final retrieved = await repo.get('create-1');
      expect(retrieved.data, isNotNull);
      expect(retrieved.data!.name, 'Chemistry');
    });

    test('getWithTopics returns subjects matching topicIds', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final s1 = _createSubject(id: 's1', name: 'Math', topicIds: ['t1', 't2']);
      final s2 = _createSubject(id: 's2', name: 'Physics', topicIds: ['t3']);
      await repo.save('s1', s1);
      await repo.save('s2', s2);

      final matching = await repo.getWithTopics(['t1', 't3']);
      expect(matching, hasLength(2));

      final noMatch = await repo.getWithTopics(['t99']);
      expect(noMatch, isEmpty);
    });

    test('getByCode finds subject by code', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final subject = Subject(
        id: 'code-test',
        name: 'History',
        code: 'HIST101',
      );
      await repo.save('code-test', subject);

      final found = await repo.getByCode('HIST101');
      expect(found, isNotNull);
      expect(found!.id, 'code-test');

      final notFound = await repo.getByCode('NONEXIST');
      expect(notFound, isNull);
    });

    test('addTopicToSubject adds topic id to subject', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final subject = _createSubject(id: 's-add', name: 'Biology');
      await repo.save('s-add', subject);

      await repo.addTopicToSubject('s-add', 'topic-1');
      final updated = await repo.get('s-add');
      expect(updated.data!.topicIds, contains('topic-1'));
    });

    test('addTopicToSubject does not duplicate existing topic id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final subject = _createSubject(id: 's-dup', name: 'Biology', topicIds: ['topic-1']);
      await repo.save('s-dup', subject);

      await repo.addTopicToSubject('s-dup', 'topic-1');
      final updated = await repo.get('s-dup');
      expect(updated.data!.topicIds, hasLength(1));
    });

    test('addTopicToSubject does nothing for unknown subject', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      await repo.addTopicToSubject('nonexistent', 'topic-1');
      // Should not throw
    });

    test('removeTopicFromSubject removes topic id from subject', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      final subject = _createSubject(id: 's-rm', name: 'Physics', topicIds: ['t1', 't2']);
      await repo.save('s-rm', subject);

      await repo.removeTopicFromSubject('s-rm', 't1');
      final updated = await repo.get('s-rm');
      expect(updated.data!.topicIds, equals(['t2']));
    });

    test('removeTopicFromSubject does nothing for unknown subject', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = await container.read(subjectsRepositoryProvider.future);
      await repo.removeTopicFromSubject('nonexistent', 't1');
      // Should not throw
    });

    test('build() is called again after invalidate', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = await container.read(subjectsRepositoryProvider.future);
      container.invalidate(subjectsRepositoryProvider);
      final repo = await container.read(subjectsRepositoryProvider.future);
      expect(repo, isA<SubjectRepository>());
      expect(identical(repo1, repo), isFalse);
    });
  });
}


