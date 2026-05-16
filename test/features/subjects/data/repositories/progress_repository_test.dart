import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/repositories/progress_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _MockProgressRepository extends ProgressRepository {
  final Map<String, TopicProgress> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<TopicProgress?> get(String topicId) async {
    return _storage[topicId];
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
    late _MockProgressRepository repository;

    setUp(() {
      repository = _MockProgressRepository();
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
        expect(progress, isNotNull);
        expect(progress?.topicId, 't1');
        expect(progress?.questionsAnswered, 1);
        expect(progress?.correctAnswers, 1);
      });

      test('records incorrect attempt', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 5000);
        final progress = await repository.get('t1');
        expect(progress?.questionsAnswered, 1);
        expect(progress?.correctAnswers, 0);
        expect(progress?.accuracy, 0.0);
      });

      test('updates existing progress', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);
        await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 3000);
        final progress = await repository.get('t1');
        expect(progress?.questionsAnswered, 2);
        expect(progress?.correctAnswers, 1);
        expect(progress?.accuracy, 0.5);
      });

      test('updates average time', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 4000);
        final progress = await repository.get('t1');
        expect(progress?.averageTimeMs, 3000);
      });

      test('handles multiple topics independently', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
        await repository.recordAttempt(topicId: 't2', isCorrect: false, timeSpentMs: 2000);
        expect((await repository.get('t1'))?.questionsAnswered, 1);
        expect((await repository.get('t2'))?.questionsAnswered, 1);
      });

      test('recordAttempt with timeSpentMs: 0 does not cause division issues', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 0);
        final progress = await repository.get('t1');
        expect(progress?.averageTimeMs, 0);
        expect(progress?.questionsAnswered, 1);
        expect(progress?.correctAnswers, 1);
      });

      test('recordAttempt with negative timeSpentMs is stored as-is', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: -1);
        final progress = await repository.get('t1');
        expect(progress?.averageTimeMs, -1);
        expect(progress?.questionsAnswered, 1);
      });

      test('averageTimeMs calculation on first attempt uses correct formula', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 5000);
        final progress = await repository.get('t1');
        expect(progress?.averageTimeMs, 5000);
      });

      test('averageTimeMs calculation on second attempt', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 4000);
        final progress = await repository.get('t1');
        expect(progress?.averageTimeMs, 3000);
      });

      test('averageTimeMs calculation on third attempt', () async {
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
        await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 3000);
        final progress = await repository.get('t1');
        expect(progress?.averageTimeMs, 2000);
      });

      test('concurrent recordAttempt calls do not corrupt state', () async {
        await Future.wait([
          repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000),
          repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 2000),
        ]);
        final progress = await repository.get('t1');
        expect(progress?.questionsAnswered, 2);
        expect(progress?.correctAnswers, 1);
      });

      test('concurrent recordAttempt calls on different topics are isolated', () async {
        await Future.wait([
          repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 1000),
          repository.recordAttempt(topicId: 't2', isCorrect: false, timeSpentMs: 2000),
          repository.recordAttempt(topicId: 't3', isCorrect: true, timeSpentMs: 3000),
        ]);
        expect((await repository.get('t1'))?.questionsAnswered, 1);
        expect((await repository.get('t2'))?.questionsAnswered, 1);
        expect((await repository.get('t3'))?.questionsAnswered, 1);
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
      expect(progress, isNotNull);
      expect(progress?.topicId, 't1');
      expect(progress?.questionsAnswered, 1);
      expect(progress?.correctAnswers, 1);
    });

    test('recordAttempt updates existing progress', () async {
      await repository.recordAttempt(topicId: 't1', isCorrect: true, timeSpentMs: 2000);
      await repository.recordAttempt(topicId: 't1', isCorrect: false, timeSpentMs: 4000);
      final progress = await repository.get('t1');
      expect(progress?.questionsAnswered, 2);
      expect(progress?.averageTimeMs, 3000);
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
