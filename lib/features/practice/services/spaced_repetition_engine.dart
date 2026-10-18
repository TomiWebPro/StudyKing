import 'dart:math';

/// Calendar-day difference `a - b` in whole days. Both
/// arguments are local timestamps; the computation is done
/// on UTC-normalized dates so a DST transition (a 23h or
/// 25h calendar day) cannot shift the result the way
/// elapsed-time `difference().inDays` does.
int _calendarDayDiff(DateTime a, DateTime b) {
  final utcA = DateTime.utc(a.year, a.month, a.day);
  final utcB = DateTime.utc(b.year, b.month, b.day);
  return utcA.difference(utcB).inDays;
}

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

  /// Serialises every field, including the [reviewLog], so that scheduling
  /// decisions survive an app restart.
  ///
  /// The abbreviated keys (`r`, `ef`, `pi`, `lr`) are retained for backward
  /// compatibility with previously persisted payloads; `log` is additive, so
  /// legacy data without it deserialises to an empty log.
  Map<String, dynamic> toJson() => {
        'r': repetitions,
        'ef': easeFactor,
        if (previousInterval != null)
          'pi': previousInterval!.inMilliseconds,
        if (lastReview != null) 'lr': lastReview!.millisecondsSinceEpoch,
        'log': reviewLog.map((e) => e.toJson()).toList(),
      };

  /// Deserialises a payload produced by [toJson] (or a legacy payload lacking
  /// a `log` key). Never throws — returns an empty [QuestionSRData] instead.
  factory QuestionSRData.fromJson(Map<String, dynamic> json) => QuestionSRData(
        repetitions: json['r'] as int? ?? 0,
        easeFactor: (json['ef'] as num?)?.toDouble() ?? 2.5,
        previousInterval: (json['pi'] as int?) != null
            ? Duration(milliseconds: json['pi'] as int)
            : null,
        lastReview: (json['lr'] as int?) != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lr'] as int)
            : null,
        reviewLog: (json['log'] as List<dynamic>?)
            ?.map((e) =>
                ReviewLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
            const [],
      );
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

  /// Maximum interval between reviews. SM-2 intervals grow by `prev × EF`
  /// on every correct review with no inherent upper bound; without a cap a
  /// well-known item can drift to multi-year gaps and effectively stop being
  /// reviewed, which defeats "optimize for retention and mastery" (vision §86).
  /// 200 days keeps every item revisited at least ~twice a year.
  static const Duration maxInterval = Duration(days: 200);

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
        if (newInterval > maxInterval) {
          newInterval = maxInterval;
        }
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
      // Calendar-day count: elapsed-time `difference().inDays`
      // truncates a 23h/25h DST day, so a window spanning a
      // spring-forward transition counts one day short and
      // seeds the wrong SM-2 branch (and interval).
      final daysUntilReview =
          _calendarDayDiff(legacyNextReview, reviewTime);
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

    // Clamp legacy intervals to the same ceiling as live scheduling so a
    // migrated item does not start with a multi-year gap.
    if (initialInterval != null && initialInterval > maxInterval) {
      initialInterval = maxInterval;
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

  /// Recall probability for a whole variant family.
  ///
  /// A concept should be re-tested when *any* of its surface forms is at risk of
  /// being forgotten, so this returns the **lowest** recall probability across
  /// the supplied per-variant [QuestionSRData] (i.e. the most vulnerable
  /// variant drives review priority). Returns 1.0 when [datas] is empty (no
  /// scheduling data yet).
  double variantGroupRecallProbability(
    List<QuestionSRData> datas, {
    DateTime? now,
  }) {
    if (datas.isEmpty) return 1.0;
    var lowest = 1.0;
    for (final data in datas) {
      final recall = computeRecallProbability(data: data, now: now);
      if (recall < lowest) lowest = recall;
    }
    return lowest;
  }

  /// The earliest next-review time across a variant family.
  ///
  /// Use this to schedule the next practice of the underlying concept: the
  /// family becomes due as soon as its most urgent variant is due.
  DateTime variantGroupNextReview(List<QuestionSRData> datas) {
    if (datas.isEmpty) return DateTime.now();
    var earliest = datas.first.lastReview?.add(const Duration(days: 1)) ??
        DateTime.now();
    for (final data in datas) {
      final review = data.reviewLog.isNotEmpty
          ? data.reviewLog.last.nextReview
          : (data.lastReview?.add(const Duration(days: 1)) ?? DateTime.now());
      if (review.isBefore(earliest)) earliest = review;
    }
    return earliest;
  }

  /// Whether a variant family needs review now.
  ///
  /// Returns true when any variant is past its [QuestionSRData] last review
  /// interval (due for review) or has no scheduling data yet (never practiced).
  bool isConceptDue(List<QuestionSRData> datas, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    if (datas.isEmpty) return true;
    for (final data in datas) {
      final next = data.reviewLog.isNotEmpty
          ? data.reviewLog.last.nextReview
          : currentTime;
      if (!next.isAfter(currentTime)) return true;
    }
    return false;
  }
}
