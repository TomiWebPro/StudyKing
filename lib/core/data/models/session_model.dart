enum SessionType { practice, focus, tutoring, manual }
enum SessionStatus { planned, inProgress, completed, cancelled }

class TutorMetadata {
  final String? topicTitle;
  final String? lessonPlanJson;
  final int confidenceRating;
  final String? tutorNotes;
  final List<String> topicsCovered;
  final int totalMessages;
  final int totalTokensUsed;

  const TutorMetadata({
    this.topicTitle,
    this.lessonPlanJson,
    this.confidenceRating = 0,
    this.tutorNotes,
    this.topicsCovered = const [],
    this.totalMessages = 0,
    this.totalTokensUsed = 0,
  });

  Map<String, dynamic> toJson() => {
    'topicTitle': topicTitle,
    'lessonPlanJson': lessonPlanJson,
    'confidenceRating': confidenceRating,
    'tutorNotes': tutorNotes,
    'topicsCovered': topicsCovered,
    'totalMessages': totalMessages,
    'totalTokensUsed': totalTokensUsed,
  };

  factory TutorMetadata.fromJson(Map<String, dynamic> json) => TutorMetadata(
    topicTitle: json['topicTitle'] as String?,
    lessonPlanJson: json['lessonPlanJson'] as String?,
    confidenceRating: json['confidenceRating'] as int? ?? 0,
    tutorNotes: json['tutorNotes'] as String?,
    topicsCovered: json['topicsCovered'] != null
        ? List<String>.from(json['topicsCovered'])
        : const [],
    totalMessages: json['totalMessages'] as int? ?? 0,
    totalTokensUsed: json['totalTokensUsed'] as int? ?? 0,
  );

  TutorMetadata copyWith({
    String? topicTitle,
    String? lessonPlanJson,
    int? confidenceRating,
    String? tutorNotes,
    List<String>? topicsCovered,
    int? totalMessages,
    int? totalTokensUsed,
    bool clearTopicTitle = false,
    bool clearLessonPlan = false,
    bool clearTutorNotes = false,
  }) {
    return TutorMetadata(
      topicTitle: clearTopicTitle ? null : (topicTitle ?? this.topicTitle),
      lessonPlanJson: clearLessonPlan ? null : (lessonPlanJson ?? this.lessonPlanJson),
      confidenceRating: confidenceRating ?? this.confidenceRating,
      tutorNotes: clearTutorNotes ? null : (tutorNotes ?? this.tutorNotes),
      topicsCovered: topicsCovered ?? this.topicsCovered,
      totalMessages: totalMessages ?? this.totalMessages,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorMetadata &&
          runtimeType == other.runtimeType &&
          topicTitle == other.topicTitle &&
          lessonPlanJson == other.lessonPlanJson &&
          confidenceRating == other.confidenceRating &&
          tutorNotes == other.tutorNotes &&
          topicsCovered == other.topicsCovered &&
          totalMessages == other.totalMessages &&
          totalTokensUsed == other.totalTokensUsed;

  @override
  int get hashCode => Object.hash(
    topicTitle,
    lessonPlanJson,
    confidenceRating,
    tutorNotes,
    Object.hashAll(topicsCovered),
    totalMessages,
    totalTokensUsed,
  );
}

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
  final List<String> sourceIds;
  final List<String> lessonIds;
  final List<String> tags;
  final DateTime createdAt;
  final String? tutorSessionId;
  final SessionStatus status;
  final TutorMetadata? tutorMetadata;

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
    this.sourceIds = const [],
    this.lessonIds = const [],
    this.tags = const [],
    DateTime? createdAt,
    this.tutorSessionId,
    this.status = SessionStatus.planned,
    this.tutorMetadata,
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
    'tutorSessionId': tutorSessionId,
    'status': status.name,
    'sourceIds': sourceIds,
    'lessonIds': lessonIds,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'tutorMetadata': tutorMetadata?.toJson(),
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
    tutorSessionId: json['tutorSessionId'],
    status: json['status'] != null
        ? SessionStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => SessionStatus.planned)
        : SessionStatus.planned,
    sourceIds: json['sourceIds'] != null ? List<String>.from(json['sourceIds']) : [],
    lessonIds: json['lessonIds'] != null ? List<String>.from(json['lessonIds']) : [],
    tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    tutorMetadata: json['tutorMetadata'] != null
        ? TutorMetadata.fromJson(json['tutorMetadata'])
        : null,
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
    String? tutorSessionId,
    SessionStatus? status,
    List<String>? sourceIds,
    List<String>? lessonIds,
    List<String>? tags,
    DateTime? createdAt,
    TutorMetadata? tutorMetadata,
    bool clearEndTime = false,
    bool clearSubjectId = false,
    bool clearTopicId = false,
    bool clearSourceId = false,
    bool clearTutorSessionId = false,
    bool clearPlannedDuration = false,
    bool clearTutorMetadata = false,
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
      tutorSessionId: clearTutorSessionId ? null : (tutorSessionId ?? this.tutorSessionId),
      status: status ?? this.status,
      sourceIds: sourceIds ?? this.sourceIds,
      lessonIds: lessonIds ?? this.lessonIds,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      tutorMetadata: clearTutorMetadata ? null : (tutorMetadata ?? this.tutorMetadata),
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
