import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/practice.dart';

void main() {
  test('practice barrel exports PracticeScreen', () {
    expect(PracticeScreen, isNotNull);
  });

  test('practice barrel exports PracticeSessionScreen', () {
    expect(PracticeSessionScreen, isNotNull);
  });

  test('practice barrel exports PracticeResultsScreen', () {
    expect(PracticeResultsScreen, isNotNull);
  });

  test('practice barrel exports PracticeSessionService', () {
    expect(PracticeSessionService, isNotNull);
  });

  test('practice barrel exports PracticeDataService', () {
    expect(PracticeDataService, isNotNull);
  });

  test('practice barrel exports SpacedRepetitionService', () {
    expect(SpacedRepetitionService, isNotNull);
  });

  test('practice barrel exports SpacedRepetitionEngine', () {
    expect(SpacedRepetitionEngine, isNotNull);
  });

  test('practice barrel exports ReadinessScorer', () {
    expect(ReadinessScorer, isNotNull);
  });

  test('practice barrel exports MasteryRecorder', () {
    expect(MasteryRecorder, isNotNull);
  });

  test('practice barrel exports MistakeReviewService', () {
    expect(MistakeReviewService, isNotNull);
  });

  test('practice barrel exports DifficultyController', () {
    expect(DifficultyController, isNotNull);
  });

  test('practice barrel exports ExamSessionService', () {
    expect(ExamSessionService, isNotNull);
  });

  test('practice barrel exports ExamSessionScreen', () {
    expect(ExamSessionScreen, isNotNull);
  });

  test('practice barrel exports PracticeAnswerRecord', () {
    expect(PracticeAnswerRecord, isNotNull);
  });

  test('practice barrel exports PracticeSessionResult', () {
    expect(PracticeSessionResult, isNotNull);
  });

  test('PracticeAnswerRecord stores values', () {
    final record = PracticeAnswerRecord(
      questionId: 'q1',
      questionType: QuestionType.singleChoice,
      isCorrect: true,
      timeSpent: const Duration(seconds: 30),
      userAnswer: 'A',
    );
    expect(record.questionId, 'q1');
    expect(record.questionType, QuestionType.singleChoice);
    expect(record.isCorrect, true);
    expect(record.timeSpent, const Duration(seconds: 30));
    expect(record.userAnswer, 'A');
  });

  test('PracticeSessionResult stores values', () {
    final result = PracticeSessionResult(
      questionsAnswered: 10,
      correctAnswers: 8,
      topicBreakdown: {'topic_1': 0.8},
    );
    expect(result.questionsAnswered, 10);
    expect(result.correctAnswers, 8);
    expect(result.topicBreakdown['topic_1'], 0.8);
  });

  test('QuestionMasteryState stores values', () {
    final now = DateTime(2025, 1, 15);
    final state = QuestionMasteryState(
      studentId: 'student_1',
      questionId: 'q1',
      correctCount: 3,
      incorrectCount: 1,
      currentStreak: 2,
      bestStreak: 3,
      masteryLevel: 0.6,
      lastAttempt: now,
    );
    expect(state.studentId, 'student_1');
    expect(state.questionId, 'q1');
    expect(state.totalAttempts, 4);
    expect(state.masteryLevel, 0.6);
  });

  test('QuestionMasteryState.initial creates default state', () {
    final now = DateTime(2025, 1, 15);
    final state = QuestionMasteryState.initial(
      studentId: 'student_1',
      questionId: 'q1',
      now: now,
    );
    expect(state.correctCount, 0);
    expect(state.incorrectCount, 0);
    expect(state.masteryLevel, 0.0);
  });

  test('QuestionMasteryState.recordAttempt updates mastery', () {
    final now = DateTime(2025, 1, 15);
    final state = QuestionMasteryState.initial(
      studentId: 'student_1',
      questionId: 'q1',
      now: now,
    );
    final updated = state.recordAttempt(
      isCorrect: true,
      confidence: 4,
      timeSpentMs: 30000,
      now: now.add(const Duration(hours: 1)),
    );
    expect(updated.correctCount, 1);
    expect(updated.totalAttempts, 1);
    expect(updated.currentStreak, 1);
  });

  test('MasteryState stores values', () {
    final now = DateTime(2025, 1, 15);
    final state = MasteryState(
      studentId: 'student_1',
      topicId: 'topic_1',
      accuracy: 0.75,
      totalAttempts: 20,
      correctAttempts: 15,
      lastAttempt: now,
      lastUpdated: now,
      masteryLevel: MasteryLevel.proficient,
    );
    expect(state.studentId, 'student_1');
    expect(state.topicId, 'topic_1');
    expect(state.accuracy, 0.75);
    expect(state.totalAttempts, 20);
    expect(state.masteryLevel, MasteryLevel.proficient);
  });

  test('MasteryState.initial creates default state', () {
    final state = MasteryState.initial(
      studentId: 'student_1',
      topicId: 'topic_1',
    );
    expect(state.accuracy, 0.0);
    expect(state.masteryLevel, MasteryLevel.novice);
  });

  test('StudentAttempt stores values', () {
    final attempt = StudentAttempt(
      id: 'attempt_1',
      studentId: 'student_1',
      questionId: 'q1',
      subjectId: 'subj_1',
      isCorrect: true,
      timeSpentMs: 45000,
      confidence: 4,
      timestamp: DateTime(2025, 1, 15),
      userAnswer: '42',
    );
    expect(attempt.id, 'attempt_1');
    expect(attempt.isCorrect, true);
    expect(attempt.timeSpentMs, 45000);
    expect(attempt.confidence, 4);
  });

  test('MasteryLevel enum has all expected values', () {
    expect(MasteryLevel.values, hasLength(5));
    expect(MasteryLevel.novice, MasteryLevel.novice);
    expect(MasteryLevel.expert, MasteryLevel.expert);
  });

  test('DifficultyController manages difficulty correctly', () {
    final controller = DifficultyController(
      initialDifficulty: 2,
      correctStreakThreshold: 2,
      incorrectStreakThreshold: 1,
    );
    expect(controller.currentDifficulty, 2);

    controller.recordResult(true);
    controller.recordResult(true);
    expect(controller.suggestNextDifficulty(), 3);

    controller.recordResult(false);
    expect(controller.suggestNextDifficulty(), 2);
  });

  test('DifficultyController resets state', () {
    final controller = DifficultyController();
    controller.recordResult(true);
    controller.recordResult(true);
    controller.recordResult(true);
    controller.suggestNextDifficulty();
    controller.reset(initialDifficulty: 3);
    expect(controller.currentDifficulty, 3);
  });

  test('SpacedRepetitionEngine schedules review correctly', () {
    final engine = SpacedRepetitionEngine();
    final result = engine.scheduleReview(
      questionId: 'q1',
      grade: 4,
    );
    expect(result.nextReview, isNotNull);
    expect(result.updatedData.repetitions, 1);
    expect(result.updatedData.easeFactor, greaterThan(1.3));
  });

  test('SpacedRepetitionEngine handles failed review', () {
    final engine = SpacedRepetitionEngine();
    final result = engine.scheduleReview(
      questionId: 'q1',
      grade: 1,
    );
    expect(result.updatedData.repetitions, 0);
    expect(result.nextReview, isNotNull);
  });

  test('SpacedRepetitionEngine maps confidence to grade', () {
    final engine = SpacedRepetitionEngine();
    expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 4), 5);
    expect(engine.mapConfidenceToGrade(isCorrect: false, confidence: 2), 0);
    expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 2), 3);
  });

  test('QuestionSRData has sensible defaults', () {
    final data = const QuestionSRData();
    expect(data.repetitions, 0);
    expect(data.easeFactor, 2.5);
    expect(data.previousInterval, isNull);
    expect(data.lastReview, isNull);
  });

  test('ReviewLogEntry stores review data', () {
    final now = DateTime(2025, 1, 15);
    final entry = ReviewLogEntry(
      questionId: 'q1',
      timestamp: now,
      grade: 4,
      easeFactor: 2.5,
      interval: const Duration(days: 1),
      nextReview: now.add(const Duration(days: 1)),
    );
    expect(entry.questionId, 'q1');
    expect(entry.grade, 4);
    expect(entry.easeFactor, 2.5);
  });

  test('SM2Result stores result values', () {
    final now = DateTime(2025, 1, 15);
    final data = const QuestionSRData();
    final result = SM2Result(nextReview: now, updatedData: data);
    expect(result.nextReview, now);
    expect(result.updatedData, data);
  });

  test('ExamConfig stores configuration', () {
    final config = const ExamConfig(
      durationMinutes: 60,
      questionCount: 20,
      easyCount: 5,
      mediumCount: 10,
      hardCount: 5,
      subjectId: 'subj_1',
    );
    expect(config.durationMinutes, 60);
    expect(config.questionCount, 20);
    expect(config.easyCount, 5);
    expect(config.mediumCount, 10);
    expect(config.hardCount, 5);
    expect(config.subjectId, 'subj_1');
  });

  test('ExamQuestionResult stores result', () {
    final now = DateTime(2025, 1, 15);
    final result = ExamQuestionResult(
      question: Question(
        id: 'q1',
        text: 'What is 2+2?',
        type: QuestionType.singleChoice,
        subjectId: 'subj_1',
        topicId: 'topic_1',
        createdAt: now,
        updatedAt: now,
      ),
      userAnswer: '4',
      isCorrect: true,
      timeSpentMs: 15000,
    );
    expect(result.question.id, 'q1');
    expect(result.isCorrect, true);
    expect(result.timeSpentMs, 15000);
    expect(result.wasSkipped, false);
  });

  test('ExamResult computes accuracy correctly', () {
    final config = const ExamConfig(durationMinutes: 60, questionCount: 3, subjectId: 'subj_1');
    final now = DateTime(2025, 1, 15);
    final results = [
      ExamQuestionResult(
        question: Question(id: 'q1', text: '', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
        isCorrect: true, timeSpentMs: 10000,
      ),
      ExamQuestionResult(
        question: Question(id: 'q2', text: '', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
        isCorrect: false, timeSpentMs: 10000,
      ),
      ExamQuestionResult(
        question: Question(id: 'q3', text: '', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
        isCorrect: true, timeSpentMs: 10000,
      ),
    ];
    final examResult = ExamResult(
      config: config,
      questionResults: results,
      startTime: now,
      endTime: now.add(const Duration(minutes: 30)),
    );
    expect(examResult.totalCorrect, 2);
    expect(examResult.totalIncorrect, 1);
    expect(examResult.accuracy, 2 / 3);
  });

  test('ExamResult handles skipped questions', () {
    final config = const ExamConfig(durationMinutes: 60, questionCount: 2, subjectId: 'subj_1');
    final now = DateTime(2025, 1, 15);
    final results = [
      ExamQuestionResult(
        question: Question(id: 'q1', text: '', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
        isCorrect: true, timeSpentMs: 10000,
      ),
      ExamQuestionResult(
        question: Question(id: 'q2', text: '', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
        isCorrect: false, timeSpentMs: 0, wasSkipped: true,
      ),
    ];
    final examResult = ExamResult(
      config: config,
      questionResults: results,
      startTime: now,
      endTime: now.add(const Duration(minutes: 30)),
    );
    expect(examResult.totalCorrect, 1);
    expect(examResult.totalSkipped, 1);
    expect(examResult.accuracy, 1.0);
  });

  test('MistakeEntry stores mistake data', () {
    final now = DateTime(2025, 1, 15);
    final entry = MistakeEntry(
      question: Question(id: 'q1', text: '2+2?', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
      correctAnswer: '4',
      explanation: 'Addition of 2 and 2',
    );
    expect(entry.question.id, 'q1');
    expect(entry.correctAnswer, '4');
    expect(entry.explanation, 'Addition of 2 and 2');
  });

  test('ScoredQuestion stores question and score', () {
    final now = DateTime(2025, 1, 15);
    final scored = ScoredQuestion(
      question: Question(id: 'q1', text: '', type: QuestionType.singleChoice, subjectId: 'subj_1', topicId: 't1', createdAt: now, updatedAt: now),
      score: 0.85,
    );
    expect(scored.question.id, 'q1');
    expect(scored.score, 0.85);
    expect(scored.topicMastery, isNull);
    expect(scored.questionMastery, isNull);
  });
}
