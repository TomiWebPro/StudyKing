import 'package:hive_flutter/hive_flutter.dart';
import '../enums.dart';

@HiveType(typeId: 26)
class Source extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final SourceType type;

  @HiveField(3, defaultValue: '')
  final String content;

  @HiveField(4, defaultValue: '')
  final String subjectId;

  @HiveField(5, defaultValue: '')
  final String topicId;

  @HiveField(6, defaultValue: '')
  final String syllabusId;

  @HiveField(7, defaultValue: '')
  final String sourceUrl;

  @HiveField(8, defaultValue: '')
  final String studentId;

  @HiveField(9, defaultValue: '')
  final String language;

  @HiveField(10, defaultValue: '')
  final String summary;

  Source({
    required this.id,
    required this.title,
    required this.type,
    this.content = '',
    this.subjectId = '',
    this.topicId = '',
    this.syllabusId = '',
    this.sourceUrl = '',
    this.studentId = '',
    this.language = '',
    this.summary = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'content': content,
    'subjectId': subjectId,
    'topicId': topicId,
    'syllabusId': syllabusId,
    'sourceUrl': sourceUrl,
    'studentId': studentId,
    'language': language,
    'summary': summary,
  };

  factory Source.fromJson(Map<String, dynamic> json) => Source(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    type: SourceType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => SourceType.pdf,
    ),
    content: json['content'] as String? ?? '',
    subjectId: json['subjectId'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    syllabusId: json['syllabusId'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    studentId: json['studentId'] as String? ?? '',
    language: json['language'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
  );

  Source copyWith({
    String? id,
    String? title,
    SourceType? type,
    String? content,
    String? subjectId,
    String? topicId,
    String? syllabusId,
    String? sourceUrl,
    String? studentId,
    String? language,
    String? summary,
  }) {
    return Source(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      syllabusId: syllabusId ?? this.syllabusId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      studentId: studentId ?? this.studentId,
      language: language ?? this.language,
      summary: summary ?? this.summary,
    );
  }
}
