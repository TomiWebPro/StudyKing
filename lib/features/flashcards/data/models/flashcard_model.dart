import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 38)
class Flashcard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourceId;

  @HiveField(2)
  final String topicId;

  @HiveField(3)
  final String subjectId;

  @HiveField(4)
  final String front;

  @HiveField(5)
  final String back;

  @HiveField(6, defaultValue: [])
  final List<String> tags;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  final DateTime? nextReview;

  @HiveField(10, defaultValue: 0)
  final double mastery;

  final String? srDataJson;

  Flashcard({
    required this.id,
    required this.sourceId,
    required this.topicId,
    required this.subjectId,
    required this.front,
    required this.back,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.nextReview,
    this.mastery = 0.0,
    this.srDataJson,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'topicId': topicId,
    'subjectId': subjectId,
    'front': front,
    'back': back,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'nextReview': nextReview?.toIso8601String(),
    'mastery': mastery,
    'srDataJson': srDataJson,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    subjectId: json['subjectId'] as String? ?? '',
    front: json['front'] as String? ?? '',
    back: json['back'] as String? ?? '',
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    nextReview: json['nextReview'] != null ? DateTime.tryParse(json['nextReview'] as String) : null,
    mastery: (json['mastery'] as num?)?.toDouble() ?? 0.0,
    srDataJson: json['srDataJson'] as String?,
  );

  Flashcard copyWith({
    String? id,
    String? sourceId,
    String? topicId,
    String? subjectId,
    String? front,
    String? back,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextReview,
    double? mastery,
    String? srDataJson,
    bool clearSrData = false,
    bool clearNextReview = false,
  }) {
    return Flashcard(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      topicId: topicId ?? this.topicId,
      subjectId: subjectId ?? this.subjectId,
      front: front ?? this.front,
      back: back ?? this.back,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextReview: clearNextReview ? null : (nextReview ?? this.nextReview),
      mastery: mastery ?? this.mastery,
      srDataJson: clearSrData ? null : (srDataJson ?? this.srDataJson),
    );
  }
}
