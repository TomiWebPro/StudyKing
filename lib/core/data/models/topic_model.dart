import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 0)
class Topic extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String? parentId;

  @HiveField(5)
  final int sortOrder;

  @HiveField(6)
  final String syllabusText;

  @HiveField(7, defaultValue: [])
  final List<String> childTopicIds;

  Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    this.parentId,
    this.sortOrder = 0,
    required this.syllabusText,
    this.childTopicIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'parentId': parentId,
        'sortOrder': sortOrder,
        'syllabusText': syllabusText,
        'childTopicIds': childTopicIds,
      };

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'],
        subjectId: json['subjectId'],
        title: json['title'],
        description: json['description'],
        parentId: json['parentId'],
        sortOrder: json['sortOrder'] ?? 0,
        syllabusText: json['syllabusText'],
        childTopicIds: List<String>.from(json['childTopicIds'] ?? []),
      );

  Topic copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? parentId,
    int? sortOrder,
    String? syllabusText,
    List<String>? childTopicIds,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      syllabusText: syllabusText ?? this.syllabusText,
      childTopicIds: childTopicIds ?? this.childTopicIds,
    );
  }
}
