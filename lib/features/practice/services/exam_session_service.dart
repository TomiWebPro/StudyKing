import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';

class ExamConfig {
  final int durationMinutes;
  final int questionCount;
  final int? easyCount;
  final int? mediumCount;
  final int? hardCount;
  final List<String>? topicIds;
  final String subjectId;

  const ExamConfig({
    required this.durationMinutes,
    required this.questionCount,
    this.easyCount,
    this.mediumCount,
    this.hardCount,
    this.topicIds,
    required this.subjectId,
  });
}

class ExamQuestionResult {
  final Question question;
  final String? userAnswer;
  final bool isCorrect;
  final int timeSpentMs;
  final bool wasSkipped;

  ExamQuestionResult({
    required this.question,
    this.userAnswer,
    required this.isCorrect,
    required this.timeSpentMs,
    this.wasSkipped = false,
  });

  Map<String, dynamic> toJson() => {
    'questionId': question.id,
    'userAnswer': userAnswer,
    'isCorrect': isCorrect,
    'timeSpentMs': timeSpentMs,
    'wasSkipped': wasSkipped,
  };

  factory ExamQuestionResult.fromJson(Map<String, dynamic> json, Question q) => ExamQuestionResult(
    question: q,
    userAnswer: json['userAnswer'] as String?,
    isCorrect: json['isCorrect'] as bool,
    timeSpentMs: json['timeSpentMs'] as int,
    wasSkipped: json['wasSkipped'] as bool? ?? false,
  );
}

class ExamResult {
  final ExamConfig config;
  final List<ExamQuestionResult> questionResults;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalSkipped;
  final DateTime startTime;
  final DateTime endTime;
  final bool wasAutoSubmitted;

  ExamResult({
    required this.config,
    required this.questionResults,
    required this.startTime,
    required this.endTime,
    this.wasAutoSubmitted = false,
  })  : totalCorrect = questionResults.where((r) => r.isCorrect).length,
        totalIncorrect = questionResults.where((r) => !r.isCorrect && !r.wasSkipped).length,
        totalSkipped = questionResults.where((r) => r.wasSkipped).length;

  double get accuracy {
    if (questionResults.isEmpty) return 0.0;
    final denominator = questionResults.length - totalSkipped;
    if (denominator <= 0) return 0.0;
    return totalCorrect / denominator;
  }

  Map<String, double> get topicBreakdown {
    final byTopic = <String, List<bool>>{};
    for (final r in questionResults) {
      if (r.wasSkipped) continue;
      byTopic.putIfAbsent(r.question.topicId, () => []);
      byTopic[r.question.topicId]!.add(r.isCorrect);
    }
    return byTopic.map((topic, results) => MapEntry(
      topic,
      results.isEmpty ? 0.0 : results.where((c) => c).length / results.length,
    ));
  }

  double get averageTimePerQuestionMs {
    if (questionResults.isEmpty) return 0.0;
    final total = questionResults.fold<int>(0, (sum, r) => sum + r.timeSpentMs);
    return total / questionResults.length;
  }

  Map<String, dynamic> toJson() => {
    'configDurationMinutes': config.durationMinutes,
    'configQuestionCount': config.questionCount,
    'configSubjectId': config.subjectId,
    'configEasyCount': config.easyCount,
    'configMediumCount': config.mediumCount,
    'configHardCount': config.hardCount,
    'totalCorrect': totalCorrect,
    'totalIncorrect': totalIncorrect,
    'totalSkipped': totalSkipped,
    'accuracy': accuracy,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'wasAutoSubmitted': wasAutoSubmitted,
  };

  factory ExamResult.fromJson(Map<String, dynamic> json, List<ExamQuestionResult> results) => ExamResult(
    config: ExamConfig(
      durationMinutes: json['configDurationMinutes'] as int,
      questionCount: json['configQuestionCount'] as int,
      subjectId: json['configSubjectId'] as String,
      easyCount: json['configEasyCount'] as int?,
      mediumCount: json['configMediumCount'] as int?,
      hardCount: json['configHardCount'] as int?,
    ),
    questionResults: results,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    wasAutoSubmitted: json['wasAutoSubmitted'] as bool? ?? false,
  );
}

class ExamSessionService {
  static final Logger _logger = const Logger('ExamSessionService');
  final SessionRepository _sessionRepo;
  final StudentIdService _studentIdService;
  final Clock _clock;

  Timer? _examTimer;
  DateTime _examStartTime = DateTime.now();
  bool _isActive = false;

  final ValueNotifier<Duration> timeRemainingNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> examActiveNotifier = ValueNotifier(false);

  ExamSessionService({
    required SessionRepository sessionRepo,
    required StudentIdService studentIdService,
    Clock? clock,
  })  : _sessionRepo = sessionRepo,
        _studentIdService = studentIdService,
        _clock = clock ?? SystemClock();

  bool get isActive => _isActive;
  DateTime get examStartTime => _examStartTime;

  List<Question> selectQuestions({
    required List<Question> pool,
    required ExamConfig config,
  }) {
    var candidates = pool.where((q) => q.subjectId == config.subjectId).toList();

    if (config.topicIds != null && config.topicIds!.isNotEmpty) {
      candidates = candidates.where((q) => config.topicIds!.contains(q.topicId)).toList();
    }

    candidates.shuffle();

    if (config.easyCount != null ||
        config.mediumCount != null ||
        config.hardCount != null) {
      const easyMaxDifficulty = 2;
      const mediumDifficulty = 3;
      const hardMinDifficulty = 4;
      final easy = candidates.where((q) => q.difficulty <= easyMaxDifficulty).toList()..shuffle();
      final medium = candidates.where((q) => q.difficulty == mediumDifficulty).toList()..shuffle();
      final hard = candidates.where((q) => q.difficulty >= hardMinDifficulty).toList()..shuffle();

      final selected = <Question>[];
      selected.addAll(easy.take(config.easyCount ?? 0));
      selected.addAll(medium.take(config.mediumCount ?? 0));
      selected.addAll(hard.take(config.hardCount ?? 0));

      if (selected.length < config.questionCount) {
        final remaining = candidates
            .where((q) => !selected.contains(q))
            .toList()
          ..shuffle();
        selected.addAll(remaining.take(config.questionCount - selected.length));
      }

      return selected.take(config.questionCount).toList();
    }

    return candidates.take(config.questionCount).toList();
  }

  void startExam(ExamConfig config) {
    _examStartTime = _clock.now();
    _isActive = true;
    examActiveNotifier.value = true;
    timeRemainingNotifier.value = Duration(minutes: config.durationMinutes);

    _examTimer?.cancel();
    _examTimer = Timer.periodic(Timeouts.second, (_) {
      final elapsed = _clock.now().difference(_examStartTime);
      final remaining = Duration(
        minutes: config.durationMinutes,
      ) - elapsed;
      if (remaining.isNegative) {
        timeRemainingNotifier.value = Duration.zero;
      } else {
        timeRemainingNotifier.value = remaining;
      }
    });
  }

  bool isTimeUp() {
    return timeRemainingNotifier.value.isNegative ||
        timeRemainingNotifier.value == Duration.zero;
  }

  Future<ExamResult> finishExam({
    required ExamConfig config,
    required List<ExamQuestionResult> questionResults,
    bool autoSubmitted = false,
  }) async {
    _examTimer?.cancel();
    _isActive = false;
    examActiveNotifier.value = false;

    final endTime = _clock.now();
    final result = ExamResult(
      config: config,
      questionResults: questionResults,
      startTime: _examStartTime,
      endTime: endTime,
      wasAutoSubmitted: autoSubmitted,
    );

    final studentId = _studentIdService.getStudentId();
    final session = Session(
      id: 'exam_${_examStartTime.millisecondsSinceEpoch}',
      studentId: studentId,
      subjectId: config.subjectId,
      type: SessionType.practice,
      startTime: _examStartTime,
      endTime: endTime,
      actualDurationMs: endTime.difference(_examStartTime).inMilliseconds,
      questionsAnswered: questionResults.length,
      correctAnswers: result.totalCorrect,
      completed: true,
      tags: ['exam', 'auto_submit:${autoSubmitted ? 'true' : 'false'}'],
    );
    await _sessionRepo.save(session.id, session);

    await _saveExamResult(result);

    return result;
  }

  static Future<List<Map<String, dynamic>>> getSavedExamResults() async {
    try {
      final box = await Hive.openBox(HiveBoxNames.examResults);
      return box.values.cast<Map<String, dynamic>>().toList()
        ..sort((a, b) {
          final aTime = a['result']?['startTime'] as String? ?? '';
          final bTime = b['result']?['startTime'] as String? ?? '';
          return bTime.compareTo(aTime);
        });
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveExamResult(ExamResult result) async {
    try {
      final box = await Hive.openBox(HiveBoxNames.examResults);
      final id = 'exam_${result.startTime.millisecondsSinceEpoch}';
      final data = <String, dynamic>{
        'id': id,
        'result': result.toJson(),
        'questionResults': result.questionResults.map((qr) => qr.toJson()).toList(),
        'questionIds': result.questionResults.map((qr) => qr.question.id).toList(),
      };
      await box.put(id, data);
    } catch (e) {
      _logger.w('Failed to save exam result', e);
    }
  }

  void cancelExam() {
    _examTimer?.cancel();
    _isActive = false;
    examActiveNotifier.value = false;
    timeRemainingNotifier.value = Duration.zero;
  }

  void dispose() {
    _examTimer?.cancel();
    timeRemainingNotifier.dispose();
    examActiveNotifier.dispose();
  }
}
