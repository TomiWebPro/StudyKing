import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/presentation/screens/exam_session_screen.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import '../../presentation/shared_test_helpers.dart' show FakeQuestionRepository, FakeSessionRepository;

// ---------------------------------------------------------------------------
// Fake dependencies
// ---------------------------------------------------------------------------

class FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student-id';
}

class FakeMasteryRecorder extends MasteryRecorder {
  FakeMasteryRecorder()
      : super(
          masteryGraphService: MasteryGraphService(),
          srEngine: SpacedRepetitionEngine(),
          attemptRepo: AttemptRepository(),
          questionMasteryRepo: QuestionMasteryStateRepository(),
          questionRepo: QuestionRepository(),
        );

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String questionId,
    required String subjectId,
    required String topicId,
    required bool isCorrect,
    required int timeSpentMs,
    required int confidence,
    required String userAnswer,
    DateTime? timestamp,
  }) async {
    return Result.success(null);
  }
}

class FakeExamSessionService extends ExamSessionService {
  bool _fakeIsTimeUp = false;

  FakeExamSessionService({
    SessionRepository? sessionRepo,
    StudentIdService? studentIdService,
  }) : super(
          sessionRepo: sessionRepo ?? FakeSessionRepository(),
          studentIdService: studentIdService ?? FakeStudentIdService(),
        );

  void setTimeUp() => _fakeIsTimeUp = true;

  @override
  List<Question> selectQuestions({
    required List<Question> pool,
    required ExamConfig config,
  }) {
    return pool.take(config.questionCount).toList();
  }

  @override
  void startExam(ExamConfig config) {
    examActiveNotifier.value = true;
    timeRemainingNotifier.value = Duration(minutes: config.durationMinutes);
  }

  @override
  bool isTimeUp() => _fakeIsTimeUp;

  @override
  Future<ExamResult> finishExam({
    required ExamConfig config,
    required List<ExamQuestionResult> questionResults,
    bool autoSubmitted = false,
  }) async {
    examActiveNotifier.value = false;
    return ExamResult(
      config: config,
      questionResults: questionResults,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      wasAutoSubmitted: autoSubmitted,
    );
  }

  @override
  void dispose() {
    timeRemainingNotifier.dispose();
    examActiveNotifier.dispose();
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget examSessionApp({
  required Result<List<Question>> result,
  FakeExamSessionService? examService,
}) {
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(FakeQuestionRepository(result)),
      examSessionServiceProvider.overrideWithValue(
        examService ?? FakeExamSessionService(),
      ),
      masteryRecorderProvider.overrideWithValue(FakeMasteryRecorder()),
      studentIdServiceProvider.overrideWithValue(FakeStudentIdService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: ExamSessionScreen(
        subjectId: 'subject-a',
        subjectName: 'Test Subject',
      ),
    ),
  );
}

Question _q({
  required String id,
  required String text,
  QuestionType type = QuestionType.singleChoice,
  String markschemeText = 'A',
  String topicId = 'topic-a',
  List<String> options = const [],
  String? explanation,
  int difficulty = 1,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: 'subject-a',
    topicId: topicId,
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: markschemeText,
      explanation: explanation,
    ),
    options: options,
    createdAt: now,
    updatedAt: now,
    explanation: explanation,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExamResult', () {
    group('accuracy', () {
      test('returns 1.0 when all correct', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: true, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 1.0);
      });

      test('returns 0.0 when all incorrect', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: false, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });

      test('returns 0.5 when half correct', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.5);
      });

      test('excludes skipped from denominator', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.5);
      });

      test('returns 0.0 when no non-skipped questions', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 1, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });

      test('returns 0.0 when questionResults is empty', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.accuracy, 0.0);
      });
    });

    group('topicBreakdown', () {
      test('groups results by topic', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 4, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q', topicId: 't1'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q', topicId: 't1'), isCorrect: false, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q', topicId: 't2'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q4', text: 'Q', topicId: 't2'), isCorrect: true, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown['t1'], 0.5);
        expect(result.topicBreakdown['t2'], 1.0);
      });

      test('excludes skipped from topic breakdown', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 2, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q', topicId: 't1'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q', topicId: 't1'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown['t1'], 1.0);
      });

      test('returns empty map for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.topicBreakdown, isEmpty);
      });
    });

    group('averageTimePerQuestionMs', () {
      test('calculates average correctly', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 10000),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: true, timeSpentMs: 20000),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: true, timeSpentMs: 30000),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.averageTimePerQuestionMs, 20000);
      });

      test('returns 0.0 for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 0, subjectId: 's'),
          questionResults: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.averageTimePerQuestionMs, 0.0);
      });
    });

    group('counts', () {
      test('totalCorrect, totalIncorrect, totalSkipped', () {
        final result = ExamResult(
          config: const ExamConfig(durationMinutes: 30, questionCount: 3, subjectId: 's'),
          questionResults: [
            ExamQuestionResult(question: _q(id: 'q1', text: 'Q'), isCorrect: true, timeSpentMs: 100),
            ExamQuestionResult(question: _q(id: 'q2', text: 'Q'), isCorrect: false, timeSpentMs: 0, wasSkipped: true),
            ExamQuestionResult(question: _q(id: 'q3', text: 'Q'), isCorrect: false, timeSpentMs: 100),
          ],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );
        expect(result.totalCorrect, 1);
        expect(result.totalIncorrect, 1);
        expect(result.totalSkipped, 1);
      });
    });
  });

  group('ExamSessionScreen', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator initially', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('transitions to config screen after loading', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Exam Configuration'), findsOneWidget);
      });
    });

    group('config screen', () {
      testWidgets('shows subject name in app bar', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        expect(find.textContaining('Test Subject'), findsOneWidget);
      });

      testWidgets('shows duration chips', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        expect(find.text('15 min'), findsOneWidget);
        expect(find.text('30 min'), findsOneWidget);
        expect(find.text('45 min'), findsOneWidget);
        expect(find.text('60 min'), findsOneWidget);
      });

      testWidgets('shows question count chips', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        expect(find.text('5'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
      });

      testWidgets('start button is enabled when questions are loaded', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        final startButton = find.text('Start Exam');
        expect(startButton, findsOneWidget);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
      });

      testWidgets('changing duration updates selection', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        await tester.tap(find.text('45 min'));
        await tester.pump();

        // 45 min chip should be selected (use ChoiceChip.selected)
        final chips = find.byType(ChoiceChip);
        final chip45 = chips.at(2); // 15,30,45,60 → index 2
        expect(tester.widget<ChoiceChip>(chip45).selected, isTrue);
      });
    });

    group('no questions path', () {
      testWidgets('shows no-questions dialog for empty result', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([]),
        ));
        await tester.pump();

        expect(find.text('No Questions Available'), findsOneWidget);
      });

      testWidgets('dismisses no-questions dialog on ok', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([]),
        ));
        await tester.pump();

        expect(find.text('No Questions Available'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('No Questions Available'), findsNothing);
      });
    });

    group('exam flow', () {
      testWidgets('start exam transitions to exam screen', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'First question')]),
        ));
        await tester.pump();

        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        expect(find.text('First question'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('submit button is disabled when no answer selected', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', options: ['A', 'B', 'C']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        final filledButtons = find.byType(FilledButton);
        // Should be disabled (no answer selected yet)
        expect(
          tester.widget<FilledButton>(filledButtons.last).onPressed,
          isNull,
        );
      });

      testWidgets('submit button is enabled after selecting an answer', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B', 'C']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();

        final filledButtons = find.byType(FilledButton);
        // Should be enabled now
        expect(
          tester.widget<FilledButton>(filledButtons.last).onPressed,
          isNotNull,
        );
      });

      testWidgets('shows correct feedback after correct answer', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'What is 2+2?', markschemeText: '4', options: ['3', '4', '5', '6']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('4'));
        await tester.pump();

        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('shows incorrect feedback after wrong answer', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'What is 2+2?', markschemeText: '4', options: ['3', '4', '5', '6']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('3'));
        await tester.pump();

        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('navigates to next question and shows results at end', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Practice Complete!'), findsOneWidget);
      });

      testWidgets('shows accuracy and count on results screen', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Total Questions'), findsOneWidget);
        expect(find.text('Correct Answers'), findsOneWidget);
        expect(find.text('Accuracy'), findsOneWidget);
        // topic breakdown also shows 100% for the topic
        expect(find.text('100%'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows done button on results screen', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Done'), findsOneWidget);
      });
    });

    group('results screen details', () {
      testWidgets('shows skipped count', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
          _q(id: 'q2', text: 'Q2', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        // Submit first question
        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        // Submit second question
        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Skipped'), findsOneWidget);
        expect(find.text('0'), findsWidgets);
      });
    });

    group('timer display', () {
      testWidgets('shows timer icon during exam', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        expect(find.byIcon(Icons.timer), findsOneWidget);
      });
    });

    group('progress indicator', () {
      testWidgets('shows progress indicator during exam', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1'),
          _q(id: 'q2', text: 'Q2'),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('mistake review', () {
      testWidgets('shows practice again button on results screen', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Practice Again'), findsOneWidget);
      });

      testWidgets('shows mistake review bottom sheet when practice again tapped with incorrect answers', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        // Select wrong answer
        await tester.tap(find.text('B'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        // Tap Practice Again -> triggers _showMistakeReview
        await tester.tap(find.text('Practice Again'));
        await tester.pumpAndSettle();

        expect(find.text('Review Mistakes'), findsOneWidget);
      });
    });

    group('question count selector', () {
      testWidgets('changing question count triggers load', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([
            _q(id: 'q1', text: 'Q1'),
            _q(id: 'q2', text: 'Q2'),
          ]),
        ));
        await tester.pump();

        // Select a different count
        await tester.tap(find.text('15'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Exam Configuration'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles null markscheme gracefully', (tester) async {
        final now = DateTime.utc(2024, 1, 1);
        final qWithNullMarkscheme = Question(
          id: 'q-null',
          text: 'No markscheme',
          type: QuestionType.singleChoice,
          subjectId: 'subject-a',
          topicId: 'topic-a',
          markscheme: null,
          options: ['A', 'B'],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(examSessionApp(
          result: Result.success([qWithNullMarkscheme]),
        ));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        // Both PracticeFeedbackWidget and SingleAnswerWidget show "Incorrect"
        expect(find.text('Incorrect'), findsAtLeastNWidgets(1));
      });

      testWidgets('handles empty correctAnswer in markscheme', (tester) async {
        final now = DateTime.utc(2024, 1, 1);
        final qWithEmptyMarkscheme = Question(
          id: 'q-empty',
          text: 'Empty markscheme',
          type: QuestionType.singleChoice,
          subjectId: 'subject-a',
          topicId: 'topic-a',
          markscheme: Markscheme(questionId: 'q-empty', correctAnswer: ''),
          options: ['A', 'B'],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(examSessionApp(
          result: Result.success([qWithEmptyMarkscheme]),
        ));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();

        expect(find.text('Incorrect'), findsAtLeastNWidgets(1));
      });

      testWidgets('does not crash with multiple questions navigation', (tester) async {
        final questions = List.generate(3, (i) => _q(
          id: 'q$i',
          text: 'Question $i',
          markschemeText: 'A',
          options: ['A', 'B'],
        ));

        await tester.pumpWidget(examSessionApp(result: Result.success(questions)));
        await tester.pump();
        await tester.tap(find.text('Start Exam'));
        await tester.pump();

        for (int i = 0; i < 3; i++) {
          expect(find.text('Question $i'), findsOneWidget);

          await tester.tap(find.text('A'));
          await tester.pump();
          await tester.tap(find.text('Submit Answer'));
          await tester.pump();

          await tester.tap(find.text('Next'));
          await tester.pump();
        }

        expect(find.text('Practice Complete!'), findsOneWidget);
      });
    });
  });

  group('ExamConfig', () {
    test('creates with required fields', () {
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 10,
        subjectId: 's1',
      );
      expect(config.durationMinutes, 30);
      expect(config.questionCount, 10);
      expect(config.subjectId, 's1');
      expect(config.topicIds, isNull);
      expect(config.easyCount, isNull);
    });

    test('creates with all optional fields', () {
      const config = ExamConfig(
        durationMinutes: 45,
        questionCount: 20,
        subjectId: 's1',
        easyCount: 5,
        mediumCount: 10,
        hardCount: 5,
        topicIds: ['t1', 't2'],
      );
      expect(config.easyCount, 5);
      expect(config.mediumCount, 10);
      expect(config.hardCount, 5);
      expect(config.topicIds, ['t1', 't2']);
    });
  });

  group('ExamQuestionResult', () {
    test('creates with required fields', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        isCorrect: true,
        timeSpentMs: 5000,
      );
      expect(result.question, q);
      expect(result.isCorrect, isTrue);
      expect(result.timeSpentMs, 5000);
      expect(result.userAnswer, isNull);
      expect(result.wasSkipped, isFalse);
    });

    test('creates with all fields', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        userAnswer: 'A',
        isCorrect: true,
        timeSpentMs: 5000,
        wasSkipped: false,
      );
      expect(result.userAnswer, 'A');
      expect(result.wasSkipped, isFalse);
    });

    test('creates with skipped flag', () {
      final q = _q(id: 'q1', text: 'Test');
      final result = ExamQuestionResult(
        question: q,
        isCorrect: false,
        timeSpentMs: 0,
        wasSkipped: true,
      );
      expect(result.wasSkipped, isTrue);
    });
  });
}
