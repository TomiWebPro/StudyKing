import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 11)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? syllabus;

  @HiveField(4)
  final String? code; // e.g., 'IB-PHYS'

  @HiveField(5)
  final String? teacher;

  @HiveField(6)
  final List<String> topicIds;

  @HiveField(7)
  final String color; // Hex color for UI

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? examDate;

  Subject({
    required this.id,
    required this.name,
    this.description,
    this.syllabus,
    this.code,
    this.teacher,
    List<String>? topicIds,
    this.color = '#2196F3',
    DateTime? createdAt,
    this.examDate,
  })  : topicIds = topicIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'syllabus': syllabus,
        'code': code,
        'teacher': teacher,
        'topicIds': topicIds,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'examDate': examDate?.toIso8601String(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        syllabus: json['syllabus'],
        code: json['code'],
        teacher: json['teacher'],
        topicIds: List<String>.from(json['topicIds'] ?? []),
        color: json['color'] ?? '#2196F3',
        createdAt: DateTime.parse(json['createdAt']),
        examDate: json['examDate'] != null ? DateTime.parse(json['examDate']) : null,
      );

  Subject copyWith({
    String? id,
    String? name,
    String? description,
    String? syllabus,
    String? code,
    String? teacher,
    List<String>? topicIds,
    String? color,
    DateTime? createdAt,
    DateTime? examDate,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      syllabus: syllabus ?? this.syllabus,
      code: code ?? this.code,
      teacher: teacher ?? this.teacher,
      topicIds: topicIds ?? this.topicIds,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      examDate: examDate ?? this.examDate,
    );
  }

  @override
  String toString() => 'Subject(id: $id, name: $name)';
}
