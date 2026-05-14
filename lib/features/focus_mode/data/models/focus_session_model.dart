class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDurationMinutes;
  final int actualDurationSeconds;
  final String? subjectId;
  final String? topicId;
  final bool completed;
  final DateTime createdAt;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.plannedDurationMinutes,
    this.actualDurationSeconds = 0,
    this.subjectId,
    this.topicId,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Duration get actualDuration => Duration(seconds: actualDurationSeconds);
  Duration get plannedDuration => Duration(minutes: plannedDurationMinutes);
  bool get isActive => !completed && endTime == null;

  FocusSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDurationMinutes,
    int? actualDurationSeconds,
    String? subjectId,
    String? topicId,
    bool? completed,
    DateTime? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'plannedDurationMinutes': plannedDurationMinutes,
    'actualDurationSeconds': actualDurationSeconds,
    'subjectId': subjectId,
    'topicId': topicId,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'],
    startTime: DateTime.parse(json['startTime']),
    endTime:
        json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    plannedDurationMinutes: json['plannedDurationMinutes'],
    actualDurationSeconds: json['actualDurationSeconds'] ?? 0,
    subjectId: json['subjectId'],
    topicId: json['topicId'],
    completed: json['completed'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
  );
}
