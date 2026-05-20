import 'dart:math';

class ReviewLogEntry {
  final String questionId;
  final DateTime timestamp;
  final int grade;
  final double easeFactor;
  final Duration interval;
  final DateTime nextReview;

  ReviewLogEntry({
    required this.questionId,
    required this.timestamp,
    required this.grade,
    required this.easeFactor,
    required this.interval,
    required this.nextReview,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'timestamp': timestamp.toIso8601String(),
    'grade': grade,
    'easeFactor': easeFactor,
    'intervalMs': interval.inMilliseconds,
    'nextReview': nextReview.toIso8601String(),
  };

  factory ReviewLogEntry.fromJson(Map<String, dynamic> json) => ReviewLogEntry(
    questionId: json['questionId'],
    timestamp: DateTime.parse(json['timestamp']),
    grade: json['grade'],
    easeFactor: (json['easeFactor'] as num).toDouble(),
    interval: Duration(milliseconds: json['intervalMs']),
    nextReview: DateTime.parse(json['nextReview']),
  );
}

class QuestionSRData {
  final int repetitions;
  final double easeFactor;
  final Duration? previousInterval;
  final DateTime? lastReview;
  final List<ReviewLogEntry> reviewLog;

  const QuestionSRData({
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.previousInterval,
    this.lastReview,
    this.reviewLog = const [],
  });

  QuestionSRData copyWith({
    int? repetitions,
    double? easeFactor,
    Duration? previousInterval,
    DateTime? lastReview,
    List<ReviewLogEntry>? reviewLog,
    bool clearPreviousInterval = false,
  }) {
    return QuestionSRData(
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      previousInterval: clearPreviousInterval
          ? null
          : (previousInterval ?? this.previousInterval),
      lastReview: lastReview ?? this.lastReview,
      reviewLog: reviewLog ?? this.reviewLog,
    );
  }
}

class SM2Result {
  final DateTime nextReview;
  final QuestionSRData updatedData;

  SM2Result({required this.nextReview, required this.updatedData});
}

class SpacedRepetitionEngine {
  static const double defaultEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const Duration initialInterval = Duration(days: 1);
  static const Duration secondInterval = Duration(days: 6);

  const SpacedRepetitionEngine();

  SM2Result scheduleReview({
    required String questionId,
    required int grade,
    QuestionSRData? currentData,
    DateTime? now,
  }) {
    final reviewTime = now ?? DateTime.now();
    final data = currentData ?? const QuestionSRData();
    final clampedGrade = grade.clamp(0, 5);

    int newRepetitions;
    Duration newInterval;
    double newEaseFactor;

    if (clampedGrade >= 3) {
      newRepetitions = data.repetitions + 1;
      if (data.repetitions == 0) {
        newInterval = initialInterval;
      } else if (data.repetitions == 1) {
        newInterval = secondInterval;
      } else {
        final prevMs = data.previousInterval?.inMilliseconds.toDouble() ??
            initialInterval.inMilliseconds.toDouble();
        newInterval = Duration(
          milliseconds: (prevMs * data.easeFactor).round(),
        );
      }
    } else {
      newRepetitions = 0;
      newInterval = initialInterval;
    }

    newEaseFactor = data.easeFactor +
        (0.1 - (5 - clampedGrade) * (0.08 + (5 - clampedGrade) * 0.02));
    newEaseFactor = newEaseFactor.clamp(minEaseFactor, 5.0);

    final nextReview = reviewTime.add(newInterval);

    final logEntry = ReviewLogEntry(
      questionId: questionId,
      timestamp: reviewTime,
      grade: clampedGrade,
      easeFactor: newEaseFactor,
      interval: newInterval,
      nextReview: nextReview,
    );

    final updatedLog = [...data.reviewLog, logEntry];

    final updatedData = QuestionSRData(
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      previousInterval: newInterval,
      lastReview: reviewTime,
      reviewLog: updatedLog,
    );

    return SM2Result(nextReview: nextReview, updatedData: updatedData);
  }

  SM2Result migrateFromLegacy({
    required String questionId,
    required DateTime? legacyNextReview,
    required DateTime? legacyLastReview,
    required int totalAttempts,
    required double accuracy,
    DateTime? now,
  }) {
    final reviewTime = now ?? DateTime.now();

    int initialRepetitions;
    double initialEaseFactor;
    Duration? initialInterval;

    if (legacyNextReview != null && legacyNextReview.isAfter(reviewTime)) {
      final daysUntilReview =
          legacyNextReview.difference(reviewTime).inDays;
      if (daysUntilReview >= 7) {
        initialRepetitions = max(3, totalAttempts);
        initialEaseFactor = 2.5;
        initialInterval = Duration(days: daysUntilReview);
      } else if (daysUntilReview >= 3) {
        initialRepetitions = max(2, totalAttempts ~/ 2);
        initialEaseFactor = 2.2;
        initialInterval = Duration(days: daysUntilReview);
      } else if (daysUntilReview >= 1) {
        initialRepetitions = max(1, totalAttempts ~/ 3);
        initialEaseFactor = 2.0;
        initialInterval = Duration(days: daysUntilReview);
      } else {
        initialRepetitions = 0;
        initialEaseFactor = defaultEaseFactor;
        initialInterval = null;
      }
    } else {
      initialRepetitions = 0;
      initialEaseFactor = defaultEaseFactor;
      initialInterval = null;
    }

    if (accuracy < 0.5 && initialRepetitions > 0) {
      initialRepetitions = 0;
      initialEaseFactor = defaultEaseFactor;
      initialInterval = null;
    }

    final nextReview = initialInterval != null
        ? reviewTime.add(initialInterval)
        : reviewTime;

    final logEntry = ReviewLogEntry(
      questionId: questionId,
      timestamp: reviewTime,
      grade: accuracy >= 0.9
          ? 5
          : accuracy >= 0.7
              ? 4
              : accuracy >= 0.5
                  ? 3
                  : accuracy >= 0.3
                      ? 2
                      : 1,
      easeFactor: initialEaseFactor,
      interval: initialInterval ?? Duration.zero,
      nextReview: nextReview,
    );

    final updatedData = QuestionSRData(
      repetitions: initialRepetitions,
      easeFactor: initialEaseFactor,
      previousInterval: initialInterval,
      lastReview: legacyLastReview ?? reviewTime,
      reviewLog: [logEntry],
    );

    return SM2Result(nextReview: nextReview, updatedData: updatedData);
  }

  double computeRecallProbability({
    required QuestionSRData data,
    DateTime? now,
  }) {
    if (data.lastReview == null || data.previousInterval == null) return 1.0;
    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(data.lastReview!);
    final intervalMs = data.previousInterval!.inMilliseconds.toDouble();
    if (intervalMs <= 0) return 1.0;

    final elapsedMs = elapsed.inMilliseconds.toDouble();
    final stability = intervalMs / log(2);
    final retrievability = exp(-elapsedMs / stability);

    return retrievability.clamp(0.0, 1.0);
  }

  int mapConfidenceToGrade({
    required bool isCorrect,
    required int confidence,
  }) {
    if (!isCorrect) {
      if (confidence <= 2) return 0;
      if (confidence <= 3) return 1;
      return 2;
    }
    switch (confidence) {
      case 1:
        return 3;
      case 2:
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      case 5:
        return 5;
      default:
        return isCorrect ? 4 : 1;
    }
  }
}
