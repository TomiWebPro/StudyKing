import 'package:hive_flutter/hive_flutter.dart';
import '../models/topic_progress_model.dart';

class ProgressRepository {
  late Box<TopicProgress> _box;

  Future<void> init() async {
    _box = Hive.box<TopicProgress>('progress');
  }

  Future<TopicProgress?> get(String topicId) async {
    return _box.get(topicId);
  }

  Future<void> recordAttempt({
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
  }) async {
    var progress = await get(topicId);
    if (progress == null) {
      progress = TopicProgress(
        topicId: topicId,
        lastUpdated: DateTime.now(),
      );
      await _box.put(topicId, progress);
    }
    progress.questionsAnswered++;
    if (isCorrect) progress.correctAnswers++;
    progress.averageTimeMs = (progress.averageTimeMs * (progress.questionsAnswered - 1) + timeSpentMs) / progress.questionsAnswered;
    progress.lastUpdated = DateTime.now();
  }
}
