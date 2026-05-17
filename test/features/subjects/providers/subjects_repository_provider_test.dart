import 'dart:io';

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
  });
}
