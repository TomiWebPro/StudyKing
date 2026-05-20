import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 18)
class QuestionMasteryState extends HiveObject {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final String questionId;

  @HiveField(2)
  final int correctCount;

  @HiveField(3)
  final int incorrectCount;

  @HiveField(4)
  final int currentStreak;

  @HiveField(5)
  final int bestStreak;

  @HiveField(6)
  final double averageTimeMs;

  @HiveField(7)
  final List<int> confidenceHistory;

  @HiveField(8)
  final DateTime lastAttempt;

  @HiveField(9)
  final DateTime? lastCorrect;

  @HiveField(10)
  final DateTime? lastIncorrect;

  @HiveField(11)
  final DateTime? nextReview;

  @HiveField(12)
  final double masteryLevel;

  @HiveField(13)
  final double reviewUrgency;

  @HiveField(14)
  final int totalTimeMs;

  QuestionMasteryState({
    required this.studentId,
    required this.questionId,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.averageTimeMs = 0.0,
    this.confidenceHistory = const [],
    required this.lastAttempt,
    this.lastCorrect,
    this.lastIncorrect,
    this.nextReview,
    this.masteryLevel = 0.0,
    this.reviewUrgency = 1.0,
    this.totalTimeMs = 0,
  });

  factory QuestionMasteryState.initial({
    required String studentId,
    required String questionId,
    required DateTime now,
  }) {
    return QuestionMasteryState(
      studentId: studentId,
      questionId: questionId,
      lastAttempt: now,
      nextReview: now,
    );
  }

  int get totalAttempts => correctCount + incorrectCount;

  double get accuracy => totalAttempts == 0 ? 0.0 : correctCount / totalAttempts;

  double get averageConfidence => confidenceHistory.isEmpty
      ? 3.0
      : confidenceHistory.reduce((a, b) => a + b) / confidenceHistory.length;

  QuestionMasteryState recordAttempt({
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    required DateTime now,
    DateTime? sm2NextReview,
  }) {
    final newTotalTimeMs = totalTimeMs + timeSpentMs;
    final newTotalAttempts = totalAttempts + 1;
    final newAverageTimeMs = newTotalTimeMs / newTotalAttempts;

    int newCorrectCount;
    int newIncorrectCount;
    int newCurrentStreak;
    int newBestStreak;
    DateTime? newLastCorrect;
    DateTime? newLastIncorrect;

    if (isCorrect) {
      newCorrectCount = correctCount + 1;
      newIncorrectCount = incorrectCount;
      newCurrentStreak = currentStreak + 1;
      newBestStreak = newCurrentStreak > bestStreak ? newCurrentStreak : bestStreak;
      newLastCorrect = now;
      newLastIncorrect = lastIncorrect;
    } else {
      newCorrectCount = correctCount;
      newIncorrectCount = incorrectCount + 1;
      newCurrentStreak = 0;
      newBestStreak = bestStreak;
      newLastCorrect = lastCorrect;
      newLastIncorrect = now;
    }

    final newConfidenceHistory = [...confidenceHistory, confidence];
    if (newConfidenceHistory.length > 20) newConfidenceHistory.removeAt(0);

    final newMasteryLevel = _updateMasteryLevel(
      accuracy: newCorrectCount / newTotalAttempts,
      currentStreak: newCurrentStreak,
      lastAttempt: lastAttempt,
      now: now,
    );
    final newReviewUrgency = _updateReviewUrgency(
      masteryLevel: newMasteryLevel,
      currentStreak: newCurrentStreak,
      incorrectCount: newIncorrectCount,
      correctCount: newCorrectCount,
    );
    final newNextReview = sm2NextReview ?? _calculateNextReview(
      masteryLevel: newMasteryLevel,
      now: now,
    );

    return QuestionMasteryState(
      studentId: studentId,
      questionId: questionId,
      correctCount: newCorrectCount,
      incorrectCount: newIncorrectCount,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
      averageTimeMs: newAverageTimeMs,
      confidenceHistory: newConfidenceHistory,
      lastAttempt: now,
      lastCorrect: newLastCorrect,
      lastIncorrect: newLastIncorrect,
      nextReview: newNextReview,
      masteryLevel: newMasteryLevel,
      reviewUrgency: newReviewUrgency,
      totalTimeMs: newTotalTimeMs,
    );
  }

  static double _updateMasteryLevel({
    required double accuracy,
    required int currentStreak,
    required DateTime lastAttempt,
    required DateTime now,
  }) {
    final accuracyWeight = 0.6;
    final streakWeight = 0.2;
    final recencyWeight = 0.2;

    final streakNorm = (currentStreak / 5.0).clamp(0.0, 1.0);
    final recencyScore = _recencyScore(lastAttempt: lastAttempt, now: now);

    return (accuracy * accuracyWeight) +
        (streakNorm * streakWeight) +
        (recencyScore * recencyWeight);
  }

  static double _recencyScore({
    required DateTime lastAttempt,
    required DateTime now,
  }) {
    final hoursSince = now.difference(lastAttempt).inHours;
    if (hoursSince < 1) return 1.0;
    if (hoursSince < 24) return 0.9;
    if (hoursSince < 48) return 0.7;
    if (hoursSince < 168) return 0.5;
    return 0.3;
  }

  static double _updateReviewUrgency({
    required double masteryLevel,
    required int currentStreak,
    required int incorrectCount,
    required int correctCount,
  }) {
    final baseUrgency = 1 - masteryLevel;

    if (currentStreak >= 3) {
      return (baseUrgency * 0.5).clamp(0.0, 1.0);
    } else if (incorrectCount > correctCount) {
      return (baseUrgency * 1.2).clamp(0.0, 1.0);
    } else {
      return baseUrgency;
    }
  }

  /// Deprecated: SM-2 nextReview from [MasteryRecorder] is the single source of truth.
  /// This fallback is only used when caller does not provide [sm2NextReview].
  @Deprecated('Use MasteryRecorder SM-2 nextReview instead')
  static DateTime? _calculateNextReview({
    required double masteryLevel,
    required DateTime now,
  }) {
    final multiplier = _getIntervalMultiplier(masteryLevel: masteryLevel);
    final hoursUntilNext = (multiplier * 24).round();
    return now.add(Duration(hours: hoursUntilNext));
  }

  static double _getIntervalMultiplier({required double masteryLevel}) {
    if (masteryLevel >= 0.9) return 7.0;
    if (masteryLevel >= 0.8) return 3.0;
    if (masteryLevel >= 0.7) return 2.0;
    if (masteryLevel >= 0.5) return 1.0;
    if (masteryLevel >= 0.3) return 0.5;
    return 0.25;
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'questionId': questionId,
    'correctCount': correctCount,
    'incorrectCount': incorrectCount,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'averageTimeMs': averageTimeMs,
    'confidenceHistory': confidenceHistory,
    'lastAttempt': lastAttempt.toIso8601String(),
    'lastCorrect': lastCorrect?.toIso8601String(),
    'lastIncorrect': lastIncorrect?.toIso8601String(),
    'nextReview': nextReview?.toIso8601String(),
    'masteryLevel': masteryLevel,
    'reviewUrgency': reviewUrgency,
    'totalTimeMs': totalTimeMs,
  };

  factory QuestionMasteryState.fromJson(Map<String, dynamic> json) => QuestionMasteryState(
    studentId: json['studentId'],
    questionId: json['questionId'],
    correctCount: json['correctCount'] ?? 0,
    incorrectCount: json['incorrectCount'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    bestStreak: json['bestStreak'] ?? 0,
    averageTimeMs: (json['averageTimeMs'] ?? 0.0).toDouble(),
    confidenceHistory: List<int>.from(json['confidenceHistory'] ?? []),
    lastAttempt: DateTime.parse(json['lastAttempt']),
    lastCorrect: json['lastCorrect'] != null ? DateTime.parse(json['lastCorrect']) : null,
    lastIncorrect: json['lastIncorrect'] != null ? DateTime.parse(json['lastIncorrect']) : null,
    nextReview: json['nextReview'] != null ? DateTime.parse(json['nextReview']) : null,
    masteryLevel: (json['masteryLevel'] ?? 0.0).toDouble(),
    reviewUrgency: (json['reviewUrgency'] ?? 1.0).toDouble(),
    totalTimeMs: json['totalTimeMs'] ?? 0,
  );

  QuestionMasteryState copyWith({
    String? studentId,
    String? questionId,
    int? correctCount,
    int? incorrectCount,
    int? currentStreak,
    int? bestStreak,
    double? averageTimeMs,
    List<int>? confidenceHistory,
    DateTime? lastAttempt,
    DateTime? lastCorrect,
    DateTime? lastIncorrect,
    DateTime? nextReview,
    double? masteryLevel,
    double? reviewUrgency,
    int? totalTimeMs,
  }) {
    return QuestionMasteryState(
      studentId: studentId ?? this.studentId,
      questionId: questionId ?? this.questionId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      averageTimeMs: averageTimeMs ?? this.averageTimeMs,
      confidenceHistory: confidenceHistory ?? this.confidenceHistory,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastCorrect: lastCorrect ?? this.lastCorrect,
      lastIncorrect: lastIncorrect ?? this.lastIncorrect,
      nextReview: nextReview ?? this.nextReview,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      reviewUrgency: reviewUrgency ?? this.reviewUrgency,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
    );
  }
}
