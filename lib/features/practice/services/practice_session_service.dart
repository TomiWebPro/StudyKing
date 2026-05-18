import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/clock.dart';
import 'package:studyking/core/utils/logger.dart';

class PracticeSessionService {
  final Logger _logger = const Logger('PracticeSessionService');
  final SessionRepository _sessionRepo;
  final SpacedRepetitionService _srService;
  final StudentIdService _studentIdService;
  final Clock _clock;
  final String subjectId;
  Timer? _timer;
  DateTime _sessionStartTime = DateTime.now();
  final ValueNotifier<Duration> elapsedNotifier = ValueNotifier(Duration.zero);

  PracticeSessionService({
    required SessionRepository sessionRepo,
    required SpacedRepetitionService srService,
    required StudentIdService studentIdService,
    Clock? clock,
    required this.subjectId,
  })  : _sessionRepo = sessionRepo,
        _srService = srService,
        _studentIdService = studentIdService,
        _clock = clock ?? SystemClock();

  DateTime get sessionStartTime => _sessionStartTime;

  void startTimer() {
    _timer?.cancel();
    _sessionStartTime = _clock.now();
    elapsedNotifier.value = Duration.zero;
    _timer = Timer.periodic(Timeouts.second, (timer) {
      elapsedNotifier.value = _clock.now().difference(_sessionStartTime);
    });
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  Future<void> updateNextReview(String questionId, bool isCorrect) async {
    try {
      final masteryLevel = isCorrect ? 0.8 : 0.2;
      await _srService.updateNextReviewDate(questionId, masteryLevel);
    } catch (e) {
      _logger.e('Error updating next review date', e);
    }
  }

  Future<void> autoSaveSession({
    required int questionsAnswered,
    required int correctAnswers,
  }) async {
    try {
      final endTime = _clock.now();
      final duration = endTime.difference(_sessionStartTime).inMilliseconds;
      final id = '${endTime.millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 99999}';

      final session = Session(
        id: id,
        startTime: _sessionStartTime,
        endTime: endTime,
        actualDurationMs: duration,
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
        studentId: _studentIdService.getStudentId(),
        subjectId: subjectId,
        type: SessionType.practice,
      );
      await _sessionRepo.save(session.id, session);
    } catch (e) {
      _logger.e('Failed to auto-save session', e);
    }
  }

  void dispose() {
    cancelTimer();
    elapsedNotifier.dispose();
  }
}
