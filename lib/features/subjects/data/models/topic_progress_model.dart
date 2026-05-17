import 'package:hive_flutter/hive_flutter.dart';

@Deprecated('Use MasteryState and MasteryStateRepository instead')
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

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'averageTimeMs': averageTimeMs,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
    topicId: json['topicId'],
    questionsAnswered: json['questionsAnswered'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    averageTimeMs: (json['averageTimeMs'] ?? 0.0).toDouble(),
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );

  TopicProgress copyWith({
    String? topicId,
    int? questionsAnswered,
    int? correctAnswers,
    double? averageTimeMs,
    DateTime? lastUpdated,
  }) {
    return TopicProgress(
      topicId: topicId ?? this.topicId,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      averageTimeMs: averageTimeMs ?? this.averageTimeMs,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
