import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 9)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3, defaultValue: 'todo')
  final String status; // todo, inprogress, done, blocked

  @HiveField(4)
  final String? assignee;

  @HiveField(5, defaultValue: 'medium')
  final String priority; // low, medium, high

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final DateTime? createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.status = 'todo',
    this.assignee,
    this.priority = 'medium',
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  TaskModel.empty()
      : id = 'empty',
        title = '',
        description = '',
        status = 'todo',
        assignee = null,
        priority = 'medium',
        dueDate = null,
        createdAt = null,
        updatedAt = null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
    'assignee': assignee,
    'priority': priority,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'todo',
    assignee: json['assignee'] as String?,
    priority: json['priority'] as String? ?? 'medium',
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? assignee,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  TaskModel toModel() {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      status: status,
      assignee: assignee,
      priority: priority,
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
