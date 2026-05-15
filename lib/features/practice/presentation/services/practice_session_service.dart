import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/study_session_model.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';

class PracticeSessionService {
  final Logger _logger = const Logger('PracticeSessionService');
  final StudySessionRepository _sessionRepo;
  final SpacedRepetitionRepository _srRepo;
  final String subjectId;
  Timer? _timer;
  DateTime _sessionStartTime = DateTime.now();
  String? _elapsedTimeFormatted;

  PracticeSessionService({
    required StudySessionRepository sessionRepo,
    required SpacedRepetitionRepository srRepo,
    required this.subjectId,
  })  : _sessionRepo = sessionRepo,
        _srRepo = srRepo;

  DateTime get sessionStartTime => _sessionStartTime;
  Timer? get timer => _timer;

  void startTimer(BuildContext context) {
    _timer?.cancel();
    _sessionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_sessionStartTime);
      _elapsedTimeFormatted = formatDurationFromContext(context, elapsed);
    });
  }

  String? get elapsedTimeFormatted => _elapsedTimeFormatted;

  void cancelTimer() {
    _timer?.cancel();
  }

  Future<void> updateNextReview(String questionId, bool isCorrect) async {
    try {
      final masteryLevel = isCorrect ? 0.8 : 0.2;
      await _srRepo.updateNextReviewDate(questionId, masteryLevel);
    } catch (e) {
      _logger.e('Error updating next review date', e);
    }
  }

  Future<void> autoSaveSession({
    required int questionsAnswered,
    required int correctAnswers,
  }) async {
    try {
      await _sessionRepo.init();
      final endTime = DateTime.now();
      final duration = endTime.difference(_sessionStartTime).inMilliseconds;
      final id = '${endTime.millisecondsSinceEpoch}_${Random().nextInt(99999)}';

      await _sessionRepo.create(StudySession(
        id: id,
        startTime: _sessionStartTime,
        endTime: endTime,
        timeSpentMs: duration,
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
        studentId: StudentIdService().getStudentId(),
        subjectId: subjectId,
      ));
    } catch (e) {
      _logger.e('Failed to auto-save session', e);
    }
  }
}
