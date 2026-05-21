import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Shared model used by 4 features (subjects, practice, ingestion, questions).
/// Retained in core because it is shared across >=3 features.
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
  final String? code;

  @HiveField(5)
  final String? teacher;

  @HiveField(6)
  final List<String> topicIds;

  @HiveField(7)
  final String color;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? examDate;

  @HiveField(10)
  final String? iconName;

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
    this.iconName,
  })  : topicIds = topicIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  IconData get icon {
    if (iconName == null || iconName!.isEmpty) return Icons.school;
    switch (iconName) {
      case 'Icons.science':
        return Icons.science;
      case 'Icons.language':
        return Icons.language;
      case 'Icons.calculate':
        return Icons.calculate;
      case 'Icons.history_edu':
        return Icons.history_edu;
      case 'Icons.art_track':
        return Icons.art_track;
      case 'Icons.music_note':
        return Icons.music_note;
      case 'Icons.code':
        return Icons.code;
      case 'Icons.book':
        return Icons.book;
      case 'Icons.menu_book':
        return Icons.menu_book;
      case 'Icons.biotech':
        return Icons.biotech;
      case 'Icons.public':
        return Icons.public;
      case 'Icons.psychology':
        return Icons.psychology;
      case 'Icons.euro':
        return Icons.euro;
      case 'Icons.palette':
        return Icons.palette;
      case 'Icons.fitness_center':
        return Icons.fitness_center;
      case 'Icons.computer':
        return Icons.computer;
      default:
        return Icons.school;
    }
  }

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
        'iconName': iconName,
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
        iconName: json['iconName'] as String?,
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
    String? iconName,
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
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  String toString() => 'Subject(id: $id, name: $name)';
}
