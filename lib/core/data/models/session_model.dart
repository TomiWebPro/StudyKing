enum SessionType { practice, focus, tutoring, manual }

class Session {
  final String id;
  final String studentId;
  final String? subjectId;
  final String? topicId;
  final SessionType type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? plannedDurationMinutes;
  final int actualDurationMs;
  final int questionsAnswered;
  final int correctAnswers;
  final bool completed;
  final String? sourceId;
  final List<String> tags;
  final DateTime createdAt;

  Session({
    required this.id,
    required this.studentId,
    this.subjectId,
    this.topicId,
    this.type = SessionType.practice,
    required this.startTime,
    this.endTime,
    this.plannedDurationMinutes,
    this.actualDurationMs = 0,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.completed = false,
    this.sourceId,
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => !completed && endTime == null;
  Duration get actualDuration => Duration(milliseconds: actualDurationMs);
  Duration? get plannedDuration =>
      plannedDurationMinutes != null
          ? Duration(minutes: plannedDurationMinutes!)
          : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'subjectId': subjectId,
    'topicId': topicId,
    'type': type.name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'plannedDurationMinutes': plannedDurationMinutes,
    'actualDurationMs': actualDurationMs,
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'completed': completed,
    'sourceId': sourceId,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    studentId: json['studentId'] ?? '',
    subjectId: json['subjectId'],
    topicId: json['topicId'],
    type: json['type'] != null
        ? SessionType.values.firstWhere(
            (e) => e.name == json['type'],
            orElse: () => SessionType.practice)
        : SessionType.practice,
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    plannedDurationMinutes: json['plannedDurationMinutes'],
    actualDurationMs: json['actualDurationMs'] ?? 0,
    questionsAnswered: json['questionsAnswered'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    completed: json['completed'] ?? false,
    sourceId: json['sourceId'],
    tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  Session copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? topicId,
    SessionType? type,
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDurationMinutes,
    int? actualDurationMs,
    int? questionsAnswered,
    int? correctAnswers,
    bool? completed,
    String? sourceId,
    List<String>? tags,
    DateTime? createdAt,
    bool clearEndTime = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
    bool clearSourceId = false,
    bool clearPlannedDuration = false,
  }) {
    return Session(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      plannedDurationMinutes: clearPlannedDuration
          ? null
          : (plannedDurationMinutes ?? this.plannedDurationMinutes),
      actualDurationMs: actualDurationMs ?? this.actualDurationMs,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      completed: completed ?? this.completed,
      sourceId: clearSourceId ? null : (sourceId ?? this.sourceId),
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
