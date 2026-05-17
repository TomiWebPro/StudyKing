import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/subjects/data/models/topic_progress_model.dart';
import 'package:studyking/core/data/repository.dart';

@Deprecated('Use MasteryStateRepository instead')
class ProgressRepository extends Repository<TopicProgress> {
  Future<void> init() async {
    await openBox(HiveBoxNames.progress);
  }

  Future<void> recordAttempt({
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
  }) async {
    final progressResult = await get(topicId);
    var progress = progressResult.data;
    if (progress == null) {
      progress = TopicProgress(
        topicId: topicId,
        lastUpdated: DateTime.now(),
      );
      await box.put(topicId, progress);
    }
    progress.questionsAnswered++;
    if (isCorrect) progress.correctAnswers++;
    progress.averageTimeMs = (progress.averageTimeMs *
                (progress.questionsAnswered - 1) +
            timeSpentMs) /
        progress.questionsAnswered;
    progress.lastUpdated = DateTime.now();
  }
}
