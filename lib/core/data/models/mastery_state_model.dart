import 'package:hive_flutter/hive_flutter.dart';

enum MasteryLevel {
  novice,
  browsing,
  developing,
  proficient,
  expert,
}

@HiveType(typeId: 16)
class MasteryState extends HiveObject {
  @HiveField(0)
  final String studentId;

  @HiveField(1)
  final String topicId;

  @HiveField(2)
  double accuracy;

  @HiveField(3)
  double confidenceTrend;

  @HiveField(4)
  double speedTrend;

  @HiveField(5)
  double forgettingRisk;

  @HiveField(6)
  int totalAttempts;

  @HiveField(7)
  int correctAttempts;

  @HiveField(8)
  double averageTimeMs;

  @HiveField(9)
  DateTime lastAttempt;

  @HiveField(10)
  DateTime lastUpdated;

  @HiveField(11)
  int currentStreak;

  @HiveField(12)
  int bestStreak;

  @HiveField(13)
  List<int> recentConfidence;

  @HiveField(14)
  List<double> recentAccuracy;

  @HiveField(15)
  MasteryLevel masteryLevel;

  @HiveField(16)
  double readinessScore;

  @HiveField(17)
  double reviewUrgency;

  @HiveField(18)
  List<String> weakSubtopics;

  MasteryState({
    required this.studentId,
    required this.topicId,
    this.accuracy = 0.0,
    this.confidenceTrend = 0.5,
    this.speedTrend = 0.5,
    this.forgettingRisk = 0.0,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.averageTimeMs = 0.0,
    required this.lastAttempt,
    required this.lastUpdated,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.recentConfidence = const [],
    this.recentAccuracy = const [],
    this.masteryLevel = MasteryLevel.novice,
    this.readinessScore = 0.0,
    this.reviewUrgency = 0.0,
    this.weakSubtopics = const [],
  });

  factory MasteryState.initial({
    required String studentId,
    required String topicId,
  }) {
    final now = DateTime.now();
    return MasteryState(
      studentId: studentId,
      topicId: topicId,
      lastAttempt: now,
      lastUpdated: now,
    );
  }

  void recordAttempt({
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) {
    totalAttempts++;
    if (isCorrect) correctAttempts++;

    final newAvgTime = (averageTimeMs * (totalAttempts - 1) + timeSpentMs) / totalAttempts;
    averageTimeMs = newAvgTime;

    recentConfidence.add(confidence);
    if (recentConfidence.length > 20) recentConfidence.removeAt(0);

    final recentAccuracyVal = isCorrect ? 1.0 : 0.0;
    recentAccuracy.add(recentAccuracyVal);
    if (recentAccuracy.length > 20) recentAccuracy.removeAt(0);

    if (isCorrect) {
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    } else {
      currentStreak = 0;
    }

    _updateAccuracy();
    _updateConfidenceTrend();
    _updateSpeedTrend();
    _updateForgettingRisk();
    _updateMasteryLevel();
    _updateReadinessScore();
    _updateReviewUrgency();

    if (subtopicId != null && !isCorrect && !weakSubtopics.contains(subtopicId)) {
      weakSubtopics.add(subtopicId);
    }

    lastAttempt = DateTime.now();
    lastUpdated = DateTime.now();
  }

  void _updateAccuracy() {
    if (totalAttempts == 0) {
      accuracy = 0.0;
    } else {
      accuracy = correctAttempts / totalAttempts;
    }
  }

  void _updateConfidenceTrend() {
    if (recentConfidence.isEmpty) {
      confidenceTrend = 0.5;
    } else {
      confidenceTrend = recentConfidence.reduce((a, b) => a + b) / recentConfidence.length / 5.0;
    }
  }

  void _updateSpeedTrend() {
    const expectedTimeMs = 60000.0;
    if (averageTimeMs > 0) {
      speedTrend = (expectedTimeMs / averageTimeMs).clamp(0.0, 1.0);
    }
  }

  void _updateForgettingRisk() {
    final daysSinceLastAttempt = DateTime.now().difference(lastAttempt).inDays;
    final retentionDecay = accuracy * (1 - (daysSinceLastAttempt / 30.0).clamp(0.0, 1.0));
    forgettingRisk = 1 - retentionDecay;
  }

  void _updateMasteryLevel() {
    if (accuracy >= 0.9 && currentStreak >= 5 && totalAttempts >= 10) {
      masteryLevel = MasteryLevel.expert;
    } else if (accuracy >= 0.8 && totalAttempts >= 5) {
      masteryLevel = MasteryLevel.proficient;
    } else if (accuracy >= 0.6 && totalAttempts >= 3) {
      masteryLevel = MasteryLevel.developing;
    } else if (totalAttempts >= 1) {
      masteryLevel = MasteryLevel.browsing;
    } else {
      masteryLevel = MasteryLevel.novice;
    }
  }

  void _updateReadinessScore() {
    final accuracyWeight = 0.4;
    final streakWeight = 0.2;
    final confidenceWeight = 0.2;
    final recencyWeight = 0.2;

    final streakNorm = (currentStreak / 10.0).clamp(0.0, 1.0);
    final recencyScore = _recencyScore();

    readinessScore = (accuracy * accuracyWeight) +
        (streakNorm * streakWeight) +
        (confidenceTrend * confidenceWeight) +
        (recencyScore * recencyWeight);
  }

  double _recencyScore() {
    final daysSince = DateTime.now().difference(lastAttempt).inDays;
    if (daysSince == 0) return 1.0;
    if (daysSince <= 1) return 0.9;
    if (daysSince <= 3) return 0.7;
    if (daysSince <= 7) return 0.5;
    if (daysSince <= 14) return 0.3;
    return 0.1;
  }

  void _updateReviewUrgency() {
    final decayFactor = forgettingRisk;
    final daysSinceAttempt = DateTime.now().difference(lastAttempt).inDays;

    double urgency;
    if (daysSinceAttempt == 0) {
      urgency = 0.1;
    } else if (daysSinceAttempt <= 1) {
      urgency = 0.3;
    } else if (daysSinceAttempt <= 3) {
      urgency = 0.5 + (decayFactor * 0.2);
    } else if (daysSinceAttempt <= 7) {
      urgency = 0.7 + (decayFactor * 0.15);
    } else {
      urgency = 0.9 + (decayFactor * 0.1);
    }

    reviewUrgency = urgency.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'topicId': topicId,
    'accuracy': accuracy,
    'confidenceTrend': confidenceTrend,
    'speedTrend': speedTrend,
    'forgettingRisk': forgettingRisk,
    'totalAttempts': totalAttempts,
    'correctAttempts': correctAttempts,
    'averageTimeMs': averageTimeMs,
    'lastAttempt': lastAttempt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'recentConfidence': recentConfidence,
    'recentAccuracy': recentAccuracy,
    'masteryLevel': masteryLevel.index,
    'readinessScore': readinessScore,
    'reviewUrgency': reviewUrgency,
    'weakSubtopics': weakSubtopics,
  };

  factory MasteryState.fromJson(Map<String, dynamic> json) => MasteryState(
    studentId: json['studentId'],
    topicId: json['topicId'],
    accuracy: (json['accuracy'] ?? 0.0).toDouble(),
    confidenceTrend: (json['confidenceTrend'] ?? 0.5).toDouble(),
    speedTrend: (json['speedTrend'] ?? 0.5).toDouble(),
    forgettingRisk: (json['forgettingRisk'] ?? 0.0).toDouble(),
    totalAttempts: json['totalAttempts'] ?? 0,
    correctAttempts: json['correctAttempts'] ?? 0,
    averageTimeMs: (json['averageTimeMs'] ?? 0.0).toDouble(),
    lastAttempt: DateTime.parse(json['lastAttempt']),
    lastUpdated: DateTime.parse(json['lastUpdated']),
    currentStreak: json['currentStreak'] ?? 0,
    bestStreak: json['bestStreak'] ?? 0,
    recentConfidence: List<int>.from(json['recentConfidence'] ?? []),
    recentAccuracy: (json['recentAccuracy'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    masteryLevel: MasteryLevel.values[json['masteryLevel'] ?? 0],
    readinessScore: (json['readinessScore'] ?? 0.0).toDouble(),
    reviewUrgency: (json['reviewUrgency'] ?? 0.0).toDouble(),
    weakSubtopics: List<String>.from(json['weakSubtopics'] ?? []),
  );

  MasteryState copyWith({
    String? studentId,
    String? topicId,
    double? accuracy,
    double? confidenceTrend,
    double? speedTrend,
    double? forgettingRisk,
    int? totalAttempts,
    int? correctAttempts,
    double? averageTimeMs,
    DateTime? lastAttempt,
    DateTime? lastUpdated,
    int? currentStreak,
    int? bestStreak,
    List<int>? recentConfidence,
    List<double>? recentAccuracy,
    MasteryLevel? masteryLevel,
    double? readinessScore,
    double? reviewUrgency,
    List<String>? weakSubtopics,
  }) {
    return MasteryState(
      studentId: studentId ?? this.studentId,
      topicId: topicId ?? this.topicId,
      accuracy: accuracy ?? this.accuracy,
      confidenceTrend: confidenceTrend ?? this.confidenceTrend,
      speedTrend: speedTrend ?? this.speedTrend,
      forgettingRisk: forgettingRisk ?? this.forgettingRisk,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      averageTimeMs: averageTimeMs ?? this.averageTimeMs,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      recentConfidence: recentConfidence ?? this.recentConfidence,
      recentAccuracy: recentAccuracy ?? this.recentAccuracy,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      readinessScore: readinessScore ?? this.readinessScore,
      reviewUrgency: reviewUrgency ?? this.reviewUrgency,
      weakSubtopics: weakSubtopics ?? this.weakSubtopics,
    );
  }
}