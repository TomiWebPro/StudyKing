import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/repositories/progress_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';

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
    });
  });
}
