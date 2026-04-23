import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 1)
class TopicProgress extends HiveObject {
  @HiveField(0)
  final String topicId;

  @HiveField(1, defaultValue: 0)
  int questionsAnswered;

  @HiveField(2, defaultValue: 0)
  int correctAnswers;

  @HiveField(3, defaultValue: 0.0)
  double averageTimeMs;

  @HiveField(4)
  DateTime lastUpdated;

  TopicProgress({
    required this.topicId,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.averageTimeMs = 0.0,
    required this.lastUpdated,
  });

  double get accuracy => questionsAnswered == 0 ? 0.0 : correctAnswers / questionsAnswered;
}
