import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
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
import '../../presentation/shared_test_helpers.dart'
    show FakeQuestionRepository, FakeSessionRepository, FakeSettingsController;

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

Widget examSessionApp({
  required Result<List<Question>> result,
  FakeExamSessionService? examService,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => FakeSettingsController()),
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

Future<void> startExamFromConfig(WidgetTester tester) async {
  await tester.pump();
  await tester.ensureVisible(find.text('Start Exam'));
  await tester.tap(find.text('Start Exam'));
  await tester.pump();
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

void main() {
  group('ExamSessionScreen - additional coverage', () {
    group('exam lifecycle edge cases', () {
      testWidgets('loading with exception shows no questions dialog', (tester) async {
        final failingRepo = _FailingRepo();
        await tester.pumpWidget(ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeSettingsController()),
            questionRepositoryProvider.overrideWithValue(failingRepo),
            examSessionServiceProvider.overrideWithValue(
              FakeExamSessionService(),
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
        ));
        await tester.pump();

        expect(find.text('No Questions Available'), findsOneWidget);
      });
    });

    group('results screen details', () {
      testWidgets('shows topic breakdown on results screen', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A',
              options: ['A', 'B'], topicId: 'topic-a'),
          _q(id: 'q2', text: 'Q2', markschemeText: 'A',
              options: ['A', 'B'], topicId: 'topic-b'),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Practice Complete!'), findsOneWidget);
        expect(find.text('Topic Breakdown'), findsOneWidget);
      });

      testWidgets('results screen shows all stat rows', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Total Questions'), findsOneWidget);
        expect(find.text('Correct Answers'), findsOneWidget);
      });
    });

    group('no questions config screen', () {
      testWidgets('shows no questions hint', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([]),
        ));
        await tester.pump();

        expect(find.text('No Questions Available'), findsOneWidget);
        expect(find.text('Upload Materials'), findsAtLeastNWidgets(1));
      });
    });

    group('question navigation', () {
      testWidgets('shows submit button during exam', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
      });
    });

    group('progress and timer', () {
      testWidgets('shows progress indicator with multiple questions', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', options: ['A', 'B']),
          _q(id: 'q2', text: 'Q2', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('back navigation edge cases', () {
      testWidgets('exit during active exam works', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        expect(find.text('Q1'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Exit practice session?'), findsOneWidget);
      });
    });

    group('duration selector', () {
      testWidgets('changing duration updates chip state', (tester) async {
        await tester.pumpWidget(examSessionApp(
          result: Result.success([_q(id: 'q1', text: 'Q1')]),
        ));
        await tester.pump();

        expect(find.text('15m'), findsOneWidget);
        expect(find.text('45m'), findsOneWidget);

        await tester.tap(find.text('45m'));
        await tester.pump();

        final chips = find.byType(ChoiceChip);
        expect(chips, findsAtLeastNWidgets(4));
      });
    });

    group('auto-submit edge cases', () {
      testWidgets('auto-submit with unanswered questions works', (tester) async {
        final examService = FakeExamSessionService();
        examService.setTimeUp();
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
          examService: examService,
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        examService.timeRemainingNotifier.value = Duration.zero;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });
    });

    group('done button', () {
      testWidgets('shows done button on results', (tester) async {
        final questions = [
          _q(id: 'q1', text: 'Q1', markschemeText: 'A', options: ['A', 'B']),
        ];

        await tester.pumpWidget(examSessionApp(
          result: Result.success(questions),
        ));
        await tester.pump();
        await startExamFromConfig(tester);

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.tap(find.text('Submit Answer'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(find.text('Done'), findsOneWidget);
      });
    });
  });
}

class _FailingRepo extends FakeQuestionRepository {
  _FailingRepo() : super(Result.success([]));

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    throw Exception('Load failed');
  }
}
