import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/enums.dart';

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

  @HiveField(6, defaultValue: '')
  final String answerKey;

  LessonBlock({
    required this.id,
    required this.subjectId,
    required this.lessonId,
    required this.type,
    required this.content,
    this.order = 0,
    this.answerKey = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'lessonId': lessonId,
    'type': type.index,
    'content': content,
    'order': order,
    'answerKey': answerKey,
  };

  factory LessonBlock.fromJson(Map<String, dynamic> json) => LessonBlock(
    id: json['id'],
    subjectId: json['subjectId'],
    lessonId: json['lessonId'],
    type: LessonBlockType.values[json['type']],
    content: json['content'],
    order: json['order'] ?? 0,
    answerKey: json['answerKey'] ?? '',
  );

  LessonBlock copyWith({
    String? id,
    String? subjectId,
    String? lessonId,
    LessonBlockType? type,
    String? content,
    int? order,
    String? answerKey,
  }) {
    return LessonBlock(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      lessonId: lessonId ?? this.lessonId,
      type: type ?? this.type,
      content: content ?? this.content,
      order: order ?? this.order,
      answerKey: answerKey ?? this.answerKey,
    );
  }
}
