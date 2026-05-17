import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/subjects/data/repositories/progress_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _FakeProgressRepository extends ProgressRepository {
  final Map<String, TopicProgress> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<TopicProgress?>> get(String topicId) async {
    return Result.success(_storage[topicId]);
  }

  @override
  Future<Result<List<TopicProgress>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<void>> delete(String key) async {
    _storage.remove(key);
    return Result.success(null);
  }

  @override
  Future<void> recordAttempt({
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
  }) async {
    var progress = _storage[topicId];
    if (progress == null) {
      progress = TopicProgress(
        topicId: topicId,
        lastUpdated: DateTime.now(),
      );
      _storage[topicId] = progress;
    }
    progress.questionsAnswered++;
    if (isCorrect) progress.correctAnswers++;
    progress.averageTimeMs = (progress.averageTimeMs * (progress.questionsAnswered - 1) + timeSpentMs) / progress.questionsAnswered;
    progress.lastUpdated = DateTime.now();
  }
}

void main() {
  group('ProgressRepository', () {
    late _FakeProgressRepository repository;

    setUp(() {
      repository = _FakeProgressRepository();
    });

    group('get', () {
      test('returns null for non-existent', () async {
        expect(await repository.get('none'), isNull);
      });
    });

    group('recordAttempt', () {
      test('creates new progress for new topic', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);
        final progress = await repository.get('t1');
        expect(progress.data, isNotNull);
        expect(progress.data?.topicId, 't1');
        expect(progress.data?.questionsAnswered, 1);
        expect(progress.data?.correctAnswers, 1);
      });

      test('records incorrect attempt', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 5000);
        final progress = await repository.get('t1');
        expect(progress.data?.questionsAnswered, 1);
        expect(progress.data?.correctAnswers, 0);
        expect(progress.data?.accuracy, 0.0);
      });

      test('updates existing progress', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);
        await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 3000);
        final progress = await repository.get('t1');
        expect(progress.data?.questionsAnswered, 2);
        expect(progress.data?.correctAnswers, 1);
        expect(progress.data?.accuracy, 0.5);
      });

      test('updates average time', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 4000);
        final progress = await repository.get('t1');
        expect(progress.data?.averageTimeMs, 3000);
      });

      test('handles multiple topics independently', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
        await repository.recordAttempt(topicId: 't2', isCorrect: false, timeSpentMs: 2000);
        expect((await repository.get('t1')).data?.questionsAnswered, 1);
        expect((await repository.get('t2')).data?.questionsAnswered, 1);
      });

      test('recordAttempt with timeSpentMs: 0 does not cause division issues', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 0);
        final progress = await repository.get('t1');
        expect(progress.data?.averageTimeMs, 0);
        expect(progress.data?.questionsAnswered, 1);
        expect(progress.data?.correctAnswers, 1);
      });

      test('recordAttempt with negative timeSpentMs is stored as-is', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: -1);
        final progress = await repository.get('t1');
        expect(progress.data?.averageTimeMs, -1);
        expect(progress.data?.questionsAnswered, 1);
      });

      test('averageTimeMs calculation on first attempt uses correct formula', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);
        final progress = await repository.get('t1');
        expect(progress.data?.averageTimeMs, 5000);
      });

      test('averageTimeMs calculation on second attempt', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 4000);
        final progress = await repository.get('t1');
        expect(progress.data?.averageTimeMs, 3000);
      });

      test('averageTimeMs calculation on third attempt', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 3000);
        final progress = await repository.get('t1');
        expect(progress.data?.averageTimeMs, 2000);
      });

      test('concurrent recordAttempt calls do not corrupt state', () async {
        await Future.wait([
          repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000),
          repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 2000),
        ]);
        final progress = await repository.get('t1');
        expect(progress.data?.questionsAnswered, 2);
        expect(progress.data?.correctAnswers, 1);
      });

      test('concurrent recordAttempt calls on different topics are isolated', () async {
        await Future.wait([
          repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000),
          repository.recordAttempt(topicId: 't2', isCorrect: false, timeSpentMs: 2000),
          repository.recordAttempt(topicId: 't3', isCorrect: true, timeSpentMs: 3000),
        ]);
        expect((await repository.get('t1')).data?.questionsAnswered, 1);
        expect((await repository.get('t2')).data?.questionsAnswered, 1);
        expect((await repository.get('t3')).data?.questionsAnswered, 1);
      });

      test('getAll returns all progress records', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
        await repository.recordAttempt(topicId: 't2', isCorrect: false, timeSpentMs: 2000);

        final all = await repository.getAll();
        expect(all.data, hasLength(2));
      });

      test('getAll returns empty list when empty', () async {
        final all = await repository.getAll();
        expect(all.data, isEmpty);
      });

      test('delete removes progress record', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
        expect((await repository.get('t1')).data, isNotNull);

        await repository.delete('t1');
        expect((await repository.get('t1')).data, isNull);
      });
    });
  });

  group('ProgressRepository (init with real Hive)', () {
    late ProgressRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestTopicProgressAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('progress_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = ProgressRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('progress');
    });

    test('init opens box and supports CRUD', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);
      final progress = await repository.get('t1');
      expect(progress.data, isNotNull);
      expect(progress.data?.topicId, 't1');
      expect(progress.data?.questionsAnswered, 1);
      expect(progress.data?.correctAnswers, 1);
    });

    test('recordAttempt updates existing progress', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
      await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 4000);
      final progress = await repository.get('t1');
      expect(progress.data?.questionsAnswered, 2);
      expect(progress.data?.averageTimeMs, 3000);
    });

    test('getAll returns all progresses', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
      await repository.recordAttempt(topicId: 't2', isCorrect: false, timeSpentMs: 2000);
      await repository.recordAttempt(topicId: 't3', isCorrect: true, timeSpentMs: 3000);

      final all = await repository.getAll();
      expect(all.data, hasLength(3));
    });

    test('getAll returns empty list when no progresses', () async {
      final all = await repository.getAll();
      expect(all.data, isEmpty);
    });

    test('delete removes a progress', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
      expect((await repository.get('t1')).data, isNotNull);

      await repository.delete('t1');
      expect((await repository.get('t1')).data, isNull);
    });

    test('delete non-existent does not throw', () async {
      await repository.delete('non-existent');
    });

    test('save stores progress directly', () async {
      final progress = TopicProgress(
        topicId: 't1',
        questionsAnswered: 5,
        correctAnswers: 3,
        averageTimeMs: 2500.0,
        lastUpdated: DateTime(2024, 6, 15),
      );
      await repository.save('t1', progress);

      final retrieved = await repository.get('t1');
      expect(retrieved.data, isNotNull);
      expect(retrieved.data!.questionsAnswered, 5);
      expect(retrieved.data!.correctAnswers, 3);
      expect(retrieved.data!.averageTimeMs, 2500.0);
    });

    test('recordAttempt with large time values', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 999999);
      final progress = await repository.get('t1');
      expect(progress.data?.averageTimeMs, 999999);
    });

    test('multiple recordAttempts maintain correct average', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 3000);
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 4000);
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);

      final progress = await repository.get('t1');
      expect(progress.data?.questionsAnswered, 5);
      expect(progress.data?.correctAnswers, 5);
      expect(progress.data?.averageTimeMs, 3000);
      expect(progress.data?.accuracy, 1.0);
    });

    test('recordAttempt with mixed correct and incorrect', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
      await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 2000);
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 3000);

      final progress = await repository.get('t1');
      expect(progress.data?.questionsAnswered, 3);
      expect(progress.data?.correctAnswers, 2);
      expect(progress.data?.accuracy, 2 / 3);
    });
  });
}

class _TestTopicProgressAdapter extends TypeAdapter<TopicProgress> {
  @override
  final int typeId = 1;

  @override
  TopicProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopicProgress(
      topicId: fields[0] as String,
      questionsAnswered: fields[1] as int? ?? 0,
      correctAnswers: fields[2] as int? ?? 0,
      averageTimeMs: (fields[3] as num?)?.toDouble() ?? 0.0,
      lastUpdated: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TopicProgress obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.topicId)
      ..writeByte(1)
      ..write(obj.questionsAnswered)
      ..writeByte(2)
      ..write(obj.correctAnswers)
      ..writeByte(3)
      ..write(obj.averageTimeMs)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }
}
