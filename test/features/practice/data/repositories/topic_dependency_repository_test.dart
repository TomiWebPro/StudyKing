import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/subjects/data/adapters/topic_dependency_adapter.dart';

class _FakeTopicDependencyBox implements Box<TopicDependency> {
  final Map<String, TopicDependency> _storage = {};

  @override
  Iterable<TopicDependency> get values => _storage.values;

  @override
  TopicDependency? get(dynamic key, {TopicDependency? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, TopicDependency value) async {
    _storage[key.toString()] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key.toString());
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  int get length => _storage.length;

  @override
  bool get isOpen => true;

  @override
  String get name => 'topicDependencies';

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key.toString());

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTopicDependencyRepository extends TopicDependencyRepository {
  final Box<TopicDependency> _fakeBox;

  _FakeTopicDependencyRepository(this._fakeBox);

  @override
  void attachBox(Box<TopicDependency> box) {}

  @override
  Future<Result<TopicDependency>> getTopicDependency(String topicId) async {
    final dep = _fakeBox.get(topicId);
    if (dep != null) {
      return Result.success(dep);
    }
    final newDep = TopicDependency(topicId: topicId);
    await _fakeBox.put(topicId, newDep);
    return Result.success(newDep);
  }

  @override
  Future<Result<void>> updateTopicDependency(
      TopicDependency dependency) async {
    await _fakeBox.put(dependency.topicId, dependency);
    return Result.success(null);
  }

  @override
  Future<Result<List<TopicDependency>>> getAllDependencies() async {
    return Result.success(_fakeBox.values.toList());
  }
}

void main() {
  group('TopicDependencyRepository', () {
    late _FakeTopicDependencyBox box;
    late _FakeTopicDependencyRepository repository;

    setUp(() {
      box = _FakeTopicDependencyBox();
      repository = _FakeTopicDependencyRepository(box);
    });

    group('getTopicDependency', () {
      test('returns existing dependency when found', () async {
        final dep = TopicDependency(topicId: 't1', prerequisites: ['t0']);
        await box.put('t1', dep);

        final result = await repository.getTopicDependency('t1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.topicId, 't1');
        expect(result.data?.prerequisites, ['t0']);
      });

      test('creates new dependency when not found', () async {
        final result = await repository.getTopicDependency('t1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.topicId, 't1');
        expect(result.data?.prerequisites, []);
        expect(result.data?.syllabusWeight, 1.0);
      });

      test('returns distinct dependencies for different topics', () async {
        final result1 = await repository.getTopicDependency('t1');
        final result2 = await repository.getTopicDependency('t2');

        expect(result1.data?.topicId, 't1');
        expect(result2.data?.topicId, 't2');
      });
    });

    group('updateTopicDependency', () {
      test('saves and retrieves updated dependency', () async {
        final dep = TopicDependency(
          topicId: 't1',
          prerequisites: ['t0'],
          syllabusWeight: 2.0,
        );

        await repository.updateTopicDependency(dep);
        final result = await repository.getTopicDependency('t1');
        expect(result.data?.prerequisites, ['t0']);
        expect(result.data?.syllabusWeight, 2.0);
      });

      test('overwrites existing dependency', () async {
        await repository.updateTopicDependency(
          TopicDependency(topicId: 't1', prerequisites: ['old']));
        await repository.updateTopicDependency(
          TopicDependency(topicId: 't1', prerequisites: ['new']));

        final result = await repository.getTopicDependency('t1');
        expect(result.data?.prerequisites, ['new']);
      });
    });

    group('getAllDependencies', () {
      test('returns all dependencies', () async {
        await repository.updateTopicDependency(TopicDependency(topicId: 't1'));
        await repository.updateTopicDependency(TopicDependency(topicId: 't2'));
        await repository.updateTopicDependency(TopicDependency(topicId: 't3'));

        final result = await repository.getAllDependencies();
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 3);
      });

      test('returns empty list when no dependencies', () async {
        final result = await repository.getAllDependencies();
        expect(result.data, isEmpty);
      });
    });
  });

  group('TopicDependencyRepository (init with real Hive)', () {
    late TopicDependencyRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(TopicDependencyAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('td_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = TopicDependencyRepository();
      await repository.init();
    });

    tearDown(() async {
      await Hive.close();
      await Hive.deleteBoxFromDisk('topic_dependencies');
    });

    test('init opens box and supports CRUD', () async {
      final dep = TopicDependency(topicId: 't1', prerequisites: ['t0']);
      await repository.updateTopicDependency(dep);
      final result = await repository.getTopicDependency('t1');
      expect(result.isSuccess, isTrue);
      expect(result.data?.prerequisites, ['t0']);
    });

    test('getAllDependencies works after init', () async {
      await repository.updateTopicDependency(TopicDependency(topicId: 't1'));
      await repository.updateTopicDependency(TopicDependency(topicId: 't2'));
      final result = await repository.getAllDependencies();
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
    });
  });
}
