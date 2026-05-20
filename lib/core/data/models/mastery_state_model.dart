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
  final double accuracy;

  @HiveField(3)
  final double confidenceTrend;

  @HiveField(4)
  final double speedTrend;

  @HiveField(5)
  final double forgettingRisk;

  @HiveField(6)
  final int totalAttempts;

  @HiveField(7)
  final int correctAttempts;

  @HiveField(8)
  final double averageTimeMs;

  @HiveField(9)
  final DateTime lastAttempt;

  @HiveField(10)
  final DateTime lastUpdated;

  @HiveField(11)
  final int currentStreak;

  @HiveField(12)
  final int bestStreak;

  @HiveField(13)
  final List<int> recentConfidence;

  @HiveField(14)
  final List<double> recentAccuracy;

  @HiveField(15)
  final MasteryLevel masteryLevel;

  @HiveField(16)
  final double readinessScore;

  @HiveField(17)
  final double reviewUrgency;

  @HiveField(18)
  final List<String> weakSubtopics;

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
