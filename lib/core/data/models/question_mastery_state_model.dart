import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 18)
class QuestionMasteryState extends HiveObject {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final String questionId;

  @HiveField(2)
  int correctCount;

  @HiveField(3)
  int incorrectCount;

  @HiveField(4)
  int currentStreak;

  @HiveField(5)
  int bestStreak;

  @HiveField(6)
  double averageTimeMs;

  @HiveField(7)
  List<int> confidenceHistory;

  @HiveField(8)
  DateTime lastAttempt;

  @HiveField(9)
  DateTime? lastCorrect;

  @HiveField(10)
  DateTime? lastIncorrect;

  @HiveField(11)
  DateTime? nextReview;

  @HiveField(12)
  double masteryLevel;

  @HiveField(13)
  double reviewUrgency;

  @HiveField(14)
  int totalTimeMs;

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
  }) {
    final now = DateTime.now();
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

  void recordAttempt({
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
  }) {
    totalTimeMs += timeSpentMs;
    lastAttempt = DateTime.now();
    averageTimeMs = totalTimeMs / totalAttempts;

    if (isCorrect) {
      correctCount++;
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
      lastCorrect = DateTime.now();
    } else {
      incorrectCount++;
      currentStreak = 0;
      lastIncorrect = DateTime.now();
    }

    confidenceHistory.add(confidence);
    if (confidenceHistory.length > 20) confidenceHistory.removeAt(0);

    _updateMasteryLevel();
    _updateReviewUrgency();
    _calculateNextReview();
  }

  void _updateMasteryLevel() {
    final accuracyWeight = 0.6;
    final streakWeight = 0.2;
    final recencyWeight = 0.2;

    final streakNorm = (currentStreak / 5.0).clamp(0.0, 1.0);
    final recencyScore = _recencyScore();

    masteryLevel = (accuracy * accuracyWeight) +
        (streakNorm * streakWeight) +
        (recencyScore * recencyWeight);
  }

  double _recencyScore() {
    final hoursSince = DateTime.now().difference(lastAttempt).inHours;
    if (hoursSince < 1) return 1.0;
    if (hoursSince < 24) return 0.9;
    if (hoursSince < 48) return 0.7;
    if (hoursSince < 168) return 0.5;
    return 0.3;
  }

  void _updateReviewUrgency() {
    final baseUrgency = 1 - masteryLevel;

    if (currentStreak >= 3) {
      reviewUrgency = (baseUrgency * 0.5).clamp(0.0, 1.0);
    } else if (incorrectCount > correctCount) {
      reviewUrgency = (baseUrgency * 1.2).clamp(0.0, 1.0);
    } else {
      reviewUrgency = baseUrgency;
    }
  }

  void _calculateNextReview() {
    final multiplier = _getIntervalMultiplier();
    final hoursUntilNext = (multiplier * 24).round();
    nextReview = DateTime.now().add(Duration(hours: hoursUntilNext));
  }

  double _getIntervalMultiplier() {
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