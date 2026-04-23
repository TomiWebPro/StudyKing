import 'package:hive_flutter/hive_flutter.dart';
import '../enums.dart';
import 'lesson_block_model.dart';

@HiveType(typeId: 7)
class Lesson extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String topicId;

  @HiveField(4, defaultValue: [])
  final List<LessonBlock> blocks;

  @HiveField(5, defaultValue: 1)
  final int difficulty;

  @HiveField(6)
  final GeneratedBy generatedBy;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8, defaultValue: '')
  final String? markscheme;

  Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.topicId,
    List<LessonBlock>? blocks,
    this.difficulty = 1,
    this.generatedBy = GeneratedBy.manual,
    required this.createdAt,
    this.markscheme,
  }) : blocks = blocks ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'topicId': topicId,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'difficulty': difficulty,
    'generatedBy': generatedBy.index,
    'createdAt': createdAt.toIso8601String(),
    'markscheme': markscheme,
  };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'],
    subjectId: json['subjectId'],
    title: json['title'],
    topicId: json['topicId'],
    blocks: (json['blocks'] as List? ?? []).map((b) => LessonBlock.fromJson(b)).toList(),
    difficulty: json['difficulty'] ?? 1,
    generatedBy: GeneratedBy.values[json['generatedBy'] ?? 0],
    createdAt: DateTime.parse(json['createdAt']),
    markscheme: json['markscheme'],
  );
}
