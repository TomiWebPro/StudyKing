class TopicProgress {
  String topicId;
  int questionsAnswered;
  int correctAnswers;
  double averageTimeMs;
  DateTime lastUpdated;

  TopicProgress({
    required this.topicId,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.averageTimeMs = 0.0,
    required this.lastUpdated,
  });

  double get accuracy {
    if (questionsAnswered == 0) return 0.0;
    return correctAnswers / questionsAnswered;
  }

  Map<String, dynamic> toJson() => {
        'topicId': topicId,
        'questionsAnswered': questionsAnswered,
        'correctAnswers': correctAnswers,
        'averageTimeMs': averageTimeMs,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
        topicId: json['topicId'] as String,
        questionsAnswered: json['questionsAnswered'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        averageTimeMs: (json['averageTimeMs'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );

  TopicProgress copyWith({
    String? topicId,
    int? questionsAnswered,
    int? correctAnswers,
    double? averageTimeMs,
    DateTime? lastUpdated,
  }) =>
      TopicProgress(
        topicId: topicId ?? this.topicId,
        questionsAnswered: questionsAnswered ?? this.questionsAnswered,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        averageTimeMs: averageTimeMs ?? this.averageTimeMs,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}
