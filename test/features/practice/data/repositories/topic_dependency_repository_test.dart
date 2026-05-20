import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/subjects/data/adapters/topic_dependency_adapter.dart';

class _FakeTopicDependencyBox implements Box<TopicDependency> {
  final Map<String, TopicDependency> _storage = {};
  bool _shouldThrow = false;

  void throwOnNextCall() => _shouldThrow = true;

  @override
  Iterable<TopicDependency> get values {
    _checkThrow();
    return _storage.values;
  }

  @override
  TopicDependency? get(dynamic key, {TopicDependency? defaultValue}) {
    _checkThrow();
    return _storage[key] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, TopicDependency value) async {
    _checkThrow();
    _storage[key.toString()] = value;
  }

  void _checkThrow() {
    if (_shouldThrow) {
      _shouldThrow = false;
      throw Exception('simulated box error');
    }
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
  String get name => 'topic_dependencies';

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

void main() {
  group('TopicDependencyRepository', () {
    late _FakeTopicDependencyBox box;
    late TopicDependencyRepository repository;

    setUp(() {
      box = _FakeTopicDependencyBox();
      repository = TopicDependencyRepository();
      repository.attachBox(box);
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

      test('returns failure on box error', () async {
        box.throwOnNextCall();
        final result = await repository.getTopicDependency('t1');
        expect(result.isFailure, isTrue);
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

      test('returns failure on box error', () async {
        box.throwOnNextCall();
        final result = await repository.updateTopicDependency(
          TopicDependency(topicId: 't1'));
        expect(result.isFailure, isTrue);
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

      test('returns failure on box error', () async {
        box.throwOnNextCall();
        final result = await repository.getAllDependencies();
        expect(result.isFailure, isTrue);
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
