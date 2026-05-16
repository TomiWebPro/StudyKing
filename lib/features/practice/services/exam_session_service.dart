import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
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
}

class ExamSessionService {
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
      final easy = candidates.where((q) => q.difficulty <= 2).toList()..shuffle();
      final medium = candidates.where((q) => q.difficulty == 3).toList()..shuffle();
      final hard = candidates.where((q) => q.difficulty >= 4).toList()..shuffle();

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
    _examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    await _sessionRepo.save(session);

    return result;
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
