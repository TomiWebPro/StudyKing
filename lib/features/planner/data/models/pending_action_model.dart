import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 5)
class PendingActionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String actionType;

  @HiveField(3)
  final String topicTitle;

  @HiveField(4)
  final String? sessionId;

  @HiveField(5)
  final Map<String, dynamic> payload;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String status;

  PendingActionModel({
    required this.id,
    required this.studentId,
    required this.actionType,
    this.topicTitle = '',
    this.sessionId,
    this.payload = const {},
    DateTime? createdAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'actionType': actionType,
    'topicTitle': topicTitle,
    'sessionId': sessionId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory PendingActionModel.fromJson(Map<String, dynamic> json) => PendingActionModel(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    actionType: json['actionType'] as String,
    topicTitle: json['topicTitle'] as String? ?? '',
    sessionId: json['sessionId'] as String?,
    payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : {},
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    status: json['status'] as String? ?? 'pending',
  );

  PendingActionModel copyWith({
    String? id,
    String? studentId,
    String? actionType,
    String? topicTitle,
    String? sessionId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    String? status,
  }) {
    return PendingActionModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      actionType: actionType ?? this.actionType,
      topicTitle: topicTitle ?? this.topicTitle,
      sessionId: sessionId ?? this.sessionId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

enum PendingActionType {
  schedule,
  reschedule,
  planAdjustment,
}
