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

  @HiveField(7)
  final String? chapterTitle;

  @HiveField(8)
  final String? sectionTitle;

  @HiveField(9)
  final int? chapterOrder;

  @HiveField(10)
  final int? sectionOrder;

  @HiveField(11)
  final SlideType? slideType;

  LessonBlock({
    required this.id,
    required this.subjectId,
    required this.lessonId,
    required this.type,
    required this.content,
    this.order = 0,
    this.answerKey = '',
    this.chapterTitle,
    this.sectionTitle,
    this.chapterOrder,
    this.sectionOrder,
    this.slideType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'lessonId': lessonId,
    'type': type.index,
    'content': content,
    'order': order,
    'answerKey': answerKey,
    'chapterTitle': chapterTitle,
    'sectionTitle': sectionTitle,
    'chapterOrder': chapterOrder,
    'sectionOrder': sectionOrder,
    'slideType': slideType?.index,
  };

  factory LessonBlock.fromJson(Map<String, dynamic> json) => LessonBlock(
    id: json['id'],
    subjectId: json['subjectId'],
    lessonId: json['lessonId'],
    type: LessonBlockType.values[json['type']],
    content: json['content'],
    order: json['order'] ?? 0,
    answerKey: json['answerKey'] ?? '',
    chapterTitle: json['chapterTitle'],
    sectionTitle: json['sectionTitle'],
    chapterOrder: json['chapterOrder'],
    sectionOrder: json['sectionOrder'],
    slideType: json['slideType'] != null
        ? SlideType.values[json['slideType'] as int]
        : null,
  );

  LessonBlock copyWith({
    String? id,
    String? subjectId,
    String? lessonId,
    LessonBlockType? type,
    String? content,
    int? order,
    String? answerKey,
    String? chapterTitle,
    String? sectionTitle,
    int? chapterOrder,
    int? sectionOrder,
    SlideType? slideType,
  }) {
    return LessonBlock(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      lessonId: lessonId ?? this.lessonId,
      type: type ?? this.type,
      content: content ?? this.content,
      order: order ?? this.order,
      answerKey: answerKey ?? this.answerKey,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      chapterOrder: chapterOrder ?? this.chapterOrder,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      slideType: slideType ?? this.slideType,
    );
  }
}
