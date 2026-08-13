import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 39)
class StudyGuide extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourceId;

  @HiveField(2)
  final String topicId;

  @HiveField(3)
  final String subjectId;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String content;

  @HiveField(6)
  final DateTime createdAt;

  StudyGuide({
    required this.id,
    required this.sourceId,
    required this.topicId,
    required this.subjectId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceId': sourceId,
    'topicId': topicId,
    'subjectId': subjectId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory StudyGuide.fromJson(Map<String, dynamic> json) => StudyGuide(
    id: json['id'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    subjectId: json['subjectId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt']),
  );
}
