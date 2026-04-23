import 'package:hive_flutter/hive_flutter.dart';
import '../enums.dart';

@HiveType(typeId: 6)
class LessonBlock extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectId;

  @HiveField(2)
  final String lessonId;

  @HiveField(3)
  final LessonBlockType type;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final int order;

  LessonBlock({
    required this.id,
    required this.subjectId,
    required this.lessonId,
    required this.type,
    required this.content,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'lessonId': lessonId,
    'type': type.index,
    'content': content,
    'order': order,
  };

  factory LessonBlock.fromJson(Map<String, dynamic> json) => LessonBlock(
    id: json['id'],
    subjectId: json['subjectId'],
    lessonId: json['lessonId'],
    type: LessonBlockType.values[json['type']],
    content: json['content'],
    order: json['order'] ?? 0,
  );
}
