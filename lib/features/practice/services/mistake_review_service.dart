import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class MistakeEntry {
  final Question question;
  final StudentAttempt? attempt;
  final String correctAnswer;
  final String? explanation;

  MistakeEntry({
    required this.question,
    this.attempt,
    required this.correctAnswer,
    this.explanation,
  });
}

class MistakeReviewService {
  final Logger _logger = const Logger('MistakeReviewService');
  final AttemptRepository _attemptRepo;
  final QuestionRepository _questionRepo;

  MistakeReviewService({
    required AttemptRepository attemptRepo,
    required QuestionRepository questionRepo,
  })  : _attemptRepo = attemptRepo,
        _questionRepo = questionRepo;

  Future<List<MistakeEntry>> getMistakesFromSession({
    required String studentId,
    required String subjectId,
    DateTime? after,
  }) async {
    try {
      final allAttempts = await _attemptRepo.getByStudentAndSubject(
        studentId,
        subjectId,
      );

      var incorrectAttempts = allAttempts.where((a) => !a.isCorrect).toList();

      if (after != null) {
        incorrectAttempts = incorrectAttempts.where((a) => a.timestamp.isAfter(after)).toList();
      }

      final mistakes = <MistakeEntry>[];
      final processedQuestions = <String>{};

      for (final attempt in incorrectAttempts) {
        if (processedQuestions.contains(attempt.questionId)) continue;
        processedQuestions.add(attempt.questionId);

        final question = await _questionRepo.get(attempt.questionId);
        if (question == null) continue;

        mistakes.add(MistakeEntry(
          question: question,
          attempt: attempt,
          correctAnswer: question.markscheme?.correctAnswer ?? '',
          explanation: question.explanation ?? question.markscheme?.explanation,
        ));
      }

      return mistakes;
    } catch (e) {
      _logger.e('Error getting mistakes from session', e);
      return [];
    }
  }

  Future<List<MistakeEntry>> getPendingMistakes({
    required String studentId,
    required String subjectId,
  }) async {
    try {
      final allAttempts = await _attemptRepo.getByStudentAndSubject(
        studentId,
        subjectId,
      );

      final questionLastAttempts = <String, List<StudentAttempt>>{};
      for (final attempt in allAttempts) {
        questionLastAttempts.putIfAbsent(attempt.questionId, () => []);
        questionLastAttempts[attempt.questionId]!.add(attempt);
      }

      final pendingMistakes = <MistakeEntry>[];
      for (final entry in questionLastAttempts.entries) {
        entry.value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final lastAttempt = entry.value.first;

        final recentCorrectIndex = entry.value.indexWhere(
          (a) => a.isCorrect && a.id != lastAttempt.id,
        );

        if (!lastAttempt.isCorrect && recentCorrectIndex == -1) {
          final question = await _questionRepo.get(entry.key);
          if (question == null) continue;

          pendingMistakes.add(MistakeEntry(
            question: question,
            attempt: lastAttempt,
            correctAnswer: question.markscheme?.correctAnswer ?? '',
            explanation: question.explanation ?? question.markscheme?.explanation,
          ));
        }
      }

      return pendingMistakes;
    } catch (e) {
      _logger.e('Error getting pending mistakes', e);
      return [];
    }
  }

  Future<bool> isQuestionCorrected(String questionId) async {
    try {
      final attempts = await _attemptRepo.getByQuestion(questionId);
      return attempts.any((a) => a.isCorrect);
    } catch (e) {
      _logger.e('Error checking question corrected status', e);
      return false;
    }
  }

  List<Question> extractRedoQuestions(List<MistakeEntry> mistakes) {
    return mistakes.map((m) => m.question).toList();
  }
}
