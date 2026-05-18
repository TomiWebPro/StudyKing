class FocusSession {
  final String id;
  final String studentId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracy;
  final List<String> subjectIds;
  final Map<String, double> masteryChanges;

  FocusSession({
    required this.id,
    required this.studentId,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 25,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.accuracy = 0.0,
    this.subjectIds = const [],
    this.masteryChanges = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationMinutes': durationMinutes,
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'accuracy': accuracy,
    'subjectIds': subjectIds,
    'masteryChanges': masteryChanges,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'],
    studentId: json['studentId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    durationMinutes: json['durationMinutes'] ?? 25,
    questionsAnswered: json['questionsAnswered'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    subjectIds: List<String>.from(json['subjectIds'] ?? []),
    masteryChanges: Map<String, double>.from(json['masteryChanges'] ?? {}),
  );

  FocusSession copyWith({
    String? id,
    String? studentId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? questionsAnswered,
    int? correctAnswers,
    double? accuracy,
    List<String>? subjectIds,
    Map<String, double>? masteryChanges,
  }) {
    return FocusSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      accuracy: accuracy ?? this.accuracy,
      subjectIds: subjectIds ?? this.subjectIds,
      masteryChanges: masteryChanges ?? this.masteryChanges,
    );
  }
}
