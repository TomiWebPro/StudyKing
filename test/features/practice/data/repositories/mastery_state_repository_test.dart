import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/practice/data/adapters/mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';

class _FakeMasteryStateRepository extends MasteryStateRepository {
  final Map<String, MasteryState> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<MasteryState>> getMasteryState(
    String studentId,
    String topicId,
  ) async {
    final key = '${studentId}_$topicId';
    final state = _storage[key];
    if (state != null) {
      return Result.success(state);
    }
    final newState = MasteryState.initial(studentId: studentId, topicId: topicId);
    _storage[key] = newState;
    return Result.success(newState);
  }

  @override
  Future<Result<void>> updateMasteryState(MasteryState state) async {
    final key = '${state.studentId}_${state.topicId}';
    _storage[key] = state;
    return Result.success(null);
  }

  @override
  Future<Result<List<MasteryState>>> getAllMasteryStates(String studentId) async {
    final states = _storage.values
        .where((s) => s.studentId == studentId)
        .toList();
    return Result.success(states);
  }

  @override
  Future<Result<List<MasteryState>>> getTopicsNeedingReview(
      String studentId) async {
    final states = _storage.values
        .where((s) => s.studentId == studentId && s.reviewUrgency > 0.5)
        .toList();
    states.sort((a, b) => b.reviewUrgency.compareTo(a.reviewUrgency));
    return Result.success(states);
  }

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    final states = _storage.values
        .where((s) => s.studentId == studentId && s.accuracy < 0.7)
        .toList();
    states.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return Result.success(states);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(
      String studentId) async {
    final statesResult = await getAllMasteryStates(studentId);
    if (statesResult.isFailure) return Result.failure(statesResult.error);

    final topicStates = statesResult.data!;
    final avgAccuracy = topicStates.isEmpty
        ? 0.0
        : topicStates.map((s) => s.accuracy).reduce((a, b) => a + b) /
            topicStates.length;

    final masteredTopics =
        topicStates.where((s) => s.masteryLevel.index >= 3).length;
    final weakTopics = topicStates.where((s) => s.accuracy < 0.6).length;
    final totalAttempts =
        topicStates.fold<int>(0, (sum, s) => sum + s.totalAttempts);

    return Result.success({
      'totalTopics': topicStates.length,
      'masteredTopics': masteredTopics,
      'weakTopics': weakTopics,
      'averageAccuracy': avgAccuracy,
      'totalAttempts': totalAttempts,
      'avgReadiness': topicStates.isEmpty
          ? 0.0
          : topicStates
                  .map((s) => s.readinessScore)
                  .reduce((a, b) => a + b) /
              topicStates.length,
      'avgReviewUrgency': topicStates.isEmpty
          ? 0.0
          : topicStates
                  .map((s) => s.reviewUrgency)
                  .reduce((a, b) => a + b) /
              topicStates.length,
    });
  }
}

MasteryState _createState({
  String studentId = 's1',
  String topicId = 't1',
  double accuracy = 0.0,
  double reviewUrgency = 0.0,
  int totalAttempts = 0,
  MasteryLevel masteryLevel = MasteryLevel.novice,
  double readinessScore = 0.0,
}) {
  final now = DateTime(2026, 5, 12);
  return MasteryState(
    studentId: studentId,
    topicId: topicId,
    accuracy: accuracy,
    totalAttempts: totalAttempts,
    lastAttempt: now,
    lastUpdated: now,
    masteryLevel: masteryLevel,
    reviewUrgency: reviewUrgency,
    readinessScore: readinessScore,
  );
}

void main() {
  group('MasteryStateRepository', () {
    late _FakeMasteryStateRepository repository;

    setUp(() {
      repository = _FakeMasteryStateRepository();
    });

    group('getMasteryState', () {
      test('returns existing state when found', () async {
        final state = _createState();
        await repository.updateMasteryState(state);

        final result = await repository.getMasteryState('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.topicId, 't1');
      });

      test('creates initial state when not found', () async {
        final result = await repository.getMasteryState('s1', 't1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.studentId, 's1');
        expect(result.data?.topicId, 't1');
        expect(result.data?.accuracy, 0.0);
      });

      test('returns distinct states for different student-topic pairs', () async {
        final result1 = await repository.getMasteryState('s1', 't1');
        final result2 = await repository.getMasteryState('s2', 't2');

        expect(result1.data?.studentId, 's1');
        expect(result1.data?.topicId, 't1');
        expect(result2.data?.studentId, 's2');
        expect(result2.data?.topicId, 't2');
      });
    });

    group('updateMasteryState', () {
      test('saves and retrieves updated state', () async {
        final state = _createState(accuracy: 0.5);
        await repository.updateMasteryState(state);

        final result = await repository.getMasteryState('s1', 't1');
        expect(result.data?.accuracy, 0.5);
      });

      test('overwrites existing state', () async {
        final state1 = _createState(accuracy: 0.3);
        await repository.updateMasteryState(state1);

        final state2 = _createState(accuracy: 0.9);
        await repository.updateMasteryState(state2);

        final result = await repository.getMasteryState('s1', 't1');
        expect(result.data?.accuracy, 0.9);
      });
    });

    group('getAllMasteryStates', () {
      test('returns all states for a student', () async {
        await repository.updateMasteryState(_createState(topicId: 't1'));
        await repository.updateMasteryState(_createState(topicId: 't2'));
        await repository.updateMasteryState(_createState(topicId: 't3'));

        final result = await repository.getAllMasteryStates('s1');
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 3);
      });

      test('excludes other students states', () async {
        await repository.updateMasteryState(_createState(topicId: 't1'));
        await repository.updateMasteryState(
            _createState(studentId: 's2', topicId: 't2'));

        final result = await repository.getAllMasteryStates('s1');
        expect(result.data?.length, 1);
      });

      test('returns empty list when no states', () async {
        final result = await repository.getAllMasteryStates('none');
        expect(result.data, isEmpty);
      });
    });

    group('getTopicsNeedingReview', () {
      test('returns topics with urgency > 0.5 sorted descending', () async {
        await repository.updateMasteryState(
            _createState(topicId: 't1', reviewUrgency: 0.8));
        await repository.updateMasteryState(
            _createState(topicId: 't2', reviewUrgency: 0.3));
        await repository.updateMasteryState(
            _createState(topicId: 't3', reviewUrgency: 0.9));
        await repository.updateMasteryState(
            _createState(topicId: 't4', reviewUrgency: 0.6));

        final result = await repository.getTopicsNeedingReview('s1');
        expect(result.data?.length, 3);
        expect(result.data![0].reviewUrgency, 0.9);
        expect(result.data![1].reviewUrgency, 0.8);
        expect(result.data![2].reviewUrgency, 0.6);
      });

      test('returns empty when none need review', () async {
        await repository.updateMasteryState(
            _createState(topicId: 't1', reviewUrgency: 0.3));
        await repository.updateMasteryState(
            _createState(topicId: 't2', reviewUrgency: 0.1));

        final result = await repository.getTopicsNeedingReview('s1');
        expect(result.data, isEmpty);
      });
    });

    group('getWeakTopics', () {
      test('returns topics with accuracy < 0.7 sorted ascending', () async {
        await repository.updateMasteryState(
            _createState(topicId: 't1', accuracy: 0.5));
        await repository.updateMasteryState(
            _createState(topicId: 't2', accuracy: 0.8));
        await repository.updateMasteryState(
            _createState(topicId: 't3', accuracy: 0.3));
        await repository.updateMasteryState(
            _createState(topicId: 't4', accuracy: 0.6));

        final result = await repository.getWeakTopics('s1');
        expect(result.data?.length, 3);
        expect(result.data![0].accuracy, 0.3);
        expect(result.data![1].accuracy, 0.5);
        expect(result.data![2].accuracy, 0.6);
      });

      test('returns empty when no weak topics', () async {
        await repository.updateMasteryState(
            _createState(topicId: 't1', accuracy: 0.9));
        await repository.updateMasteryState(
            _createState(topicId: 't2', accuracy: 0.95));

        final result = await repository.getWeakTopics('s1');
        expect(result.data, isEmpty);
      });
    });

    group('getMasterySnapshot', () {
      test('returns aggregated stats for multiple topics', () async {
        await repository.updateMasteryState(_createState(
          topicId: 't1',
          accuracy: 0.9,
          totalAttempts: 20,
          masteryLevel: MasteryLevel.proficient,
          readinessScore: 0.8,
          reviewUrgency: 0.2,
        ));
        await repository.updateMasteryState(_createState(
          topicId: 't2',
          accuracy: 0.5,
          totalAttempts: 10,
          masteryLevel: MasteryLevel.developing,
          readinessScore: 0.4,
          reviewUrgency: 0.7,
        ));
        await repository.updateMasteryState(_createState(
          topicId: 't3',
          accuracy: 0.3,
          totalAttempts: 5,
          masteryLevel: MasteryLevel.novice,
          readinessScore: 0.2,
          reviewUrgency: 0.9,
        ));

        final result = await repository.getMasterySnapshot('s1');
        expect(result.isSuccess, isTrue);
        final snapshot = result.data!;
        expect(snapshot['totalTopics'], 3);
        expect(snapshot['masteredTopics'], 1);
        expect(snapshot['weakTopics'], 2);
        expect(snapshot['averageAccuracy'], (0.9 + 0.5 + 0.3) / 3);
        expect(snapshot['totalAttempts'], 35);
      });

      test('returns zero values when no topics', () async {
        final result = await repository.getMasterySnapshot('empty');
        expect(result.isSuccess, isTrue);
        final snapshot = result.data!;
        expect(snapshot['totalTopics'], 0);
        expect(snapshot['masteredTopics'], 0);
        expect(snapshot['weakTopics'], 0);
        expect(snapshot['averageAccuracy'], 0.0);
        expect(snapshot['totalAttempts'], 0);
        expect(snapshot['avgReadiness'], 0.0);
        expect(snapshot['avgReviewUrgency'], 0.0);
      });
    });
  });

  group('MasteryStateRepository (init with real Hive)', () {
    late MasteryStateRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(MasteryStateAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('ms_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = MasteryStateRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('mastery_states');
    });

    test('init opens box and supports CRUD', () async {
      final state = MasteryState.initial(studentId: 's1', topicId: 't1');
      await repository.updateMasteryState(state);
      final result = await repository.getMasteryState('s1', 't1');
      expect(result.isSuccess, isTrue);
      expect(result.data?.topicId, 't1');
    });

    test('getAllMasteryStates works after init', () async {
      await repository.updateMasteryState(MasteryState.initial(studentId: 's1', topicId: 't1'));
      await repository.updateMasteryState(MasteryState.initial(studentId: 's1', topicId: 't2'));
      final result = await repository.getAllMasteryStates('s1');
      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
    });

    test('getMasterySnapshot works after init', () async {
      final now = DateTime.now();
      await repository.updateMasteryState(MasteryState(studentId: 's1', topicId: 't1', lastAttempt: now, lastUpdated: now, accuracy: 0.8, totalAttempts: 10));
      await repository.updateMasteryState(MasteryState(studentId: 's1', topicId: 't2', lastAttempt: now, lastUpdated: now, accuracy: 0.5, totalAttempts: 5));
      final result = await repository.getMasterySnapshot('s1');
      expect(result.data?['totalTopics'], 2);
      expect(result.data?['totalAttempts'], 15);
    });
  });
}
