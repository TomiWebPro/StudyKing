import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/presentation/screens/exam_session_screen.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart' show sessionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/clock.dart';

class _FakeClock implements Clock {
  final DateTime fixed;
  _FakeClock(this.fixed);
  @override
  DateTime now() => fixed;
}

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student-id';
}

class _FakeSessionRepo extends SessionRepository {
  _FakeSessionRepo() : super(clock: _FakeClock(DateTime(2024, 6, 15, 12, 0)));

  @override
  Future<Result<void>> save(String key, Session item) async {
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String key) async {
    return Result.success(null);
  }
}

Question _typedQuestion({String id = 'q1', String topicId = 't1', int difficulty = 1}) {
  final now = DateTime(2024, 1, 1);
  return Question(
    id: id,
    text: 'Text question $id?',
    type: QuestionType.typedAnswer,
    difficulty: difficulty,
    subjectId: 'sub1',
    topicId: topicId,
    markscheme: Markscheme(questionId: id, correctAnswer: 'Answer $id'),
    options: [],
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(_questions.where((q) => q.subjectId == subjectId).toList());
  }
}

class _FakeMasteryRecorder extends MasteryRecorder {
  _FakeMasteryRecorder() : super(
    attemptRepo: AttemptRepository(),
    masteryGraphService: MasteryGraphService(),
    srEngine: SpacedRepetitionEngine(),
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

class _FailingQuestionRepository extends QuestionRepository {
  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    throw Exception('Network error');
  }
}

Widget _buildTestApp({
  required List<Question> questions,
  NavigatorObserver? observer,
}) {
  final fakeQuestionRepo = _FakeQuestionRepository(questions);
  final fakeSessionRepo = _FakeSessionRepo();
  final fixedClock = _FakeClock(DateTime(2024, 6, 15, 12, 0));

  final examService = ExamSessionService(
    sessionRepo: fakeSessionRepo,
    studentIdService: _FakeStudentIdService(),
    clock: fixedClock,
  );

  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(fakeQuestionRepo),
      examSessionServiceProvider.overrideWithValue(examService),
      sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
      masteryRecorderProvider.overrideWith((ref) => _FakeMasteryRecorder()),
      studentIdServiceProvider.overrideWith((ref) => _FakeStudentIdService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: observer == null ? const [] : [observer],
      home: ExamSessionScreen(subjectId: 'sub1', subjectName: 'Mathematics'),
    ),
  );
}

Future<void> _startExam(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Start Exam'));
  await tester.pump();
  await tester.tap(find.text('Start Exam'));
  await tester.pump();
}

Future<void> _answerQuestion(WidgetTester tester, String answer) async {
  await tester.ensureVisible(find.byType(TextField));
  await tester.pump();
  await tester.enterText(find.byType(TextField), answer);
  await tester.pump();
  await tester.tap(find.text('Submit Answer'));
  await tester.pump();
}

Future<void> _goNext(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Next'));
  await tester.pump();
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('ExamSessionScreen - additional coverage', () {
    group('config screen', () {
      testWidgets('shows no questions upload screen when empty', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: []));
        await tester.pumpAndSettle();

expect(find.textContaining('Practice'), findsWidgets);
expect(find.textContaining('practice questions'), findsWidgets);
expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
expect(find.text('Upload Materials'), findsWidgets);
      });

      testWidgets('shows all duration options', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();

        expect(find.text('15m'), findsOneWidget);
        expect(find.text('30m'), findsOneWidget);
        expect(find.text('45m'), findsOneWidget);
        expect(find.text('60m'), findsOneWidget);
      });

      testWidgets('shows all question count options', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('5'));
        await tester.pump();
        await tester.ensureVisible(find.text('10'));
        await tester.pump();
        await tester.ensureVisible(find.text('15'));
        await tester.pump();
        await tester.ensureVisible(find.text('20'));
        await tester.pump();
        await tester.ensureVisible(find.text('30'));
        await tester.pump();

        expect(find.text('5'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
      });
    });

    group('difficulty distribution', () {
      testWidgets('shows difficulty section and random info', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [
          _typedQuestion(id: 'q1'),
          _typedQuestion(id: 'q2'),
        ]));
        await tester.pumpAndSettle();

        expect(find.text('Difficulty Distribution'), findsOneWidget);
        expect(find.text('Easy'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('Hard'), findsOneWidget);
      });
    });

    group('exam lifecycle', () {
      testWidgets('starts exam and shows submit button', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();

        await _startExam(tester);

        expect(find.text('Submit Answer'), findsOneWidget);
      });

      testWidgets('correct answer shows Correct! feedback', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();

        await _startExam(tester);
        await _answerQuestion(tester, 'Answer q1');

        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('incorrect answer shows Incorrect feedback', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();

        await _startExam(tester);
        await _answerQuestion(tester, 'Wrong answer');

        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('navigates to next question via Next', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [
          _typedQuestion(id: 'q1'),
          _typedQuestion(id: 'q2'),
        ]));
        await tester.pumpAndSettle();

        await _startExam(tester);
        await _answerQuestion(tester, 'Answer q1');
        await _goNext(tester);

        expect(find.text('Text question q2?'), findsOneWidget);
      });

      testWidgets('completes all questions and shows results', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [
          _typedQuestion(id: 'q1'),
          _typedQuestion(id: 'q2'),
        ]));
        await tester.pumpAndSettle();

        await _startExam(tester);
        await _answerQuestion(tester, 'Answer q1');
        await _goNext(tester);
        await _answerQuestion(tester, 'Answer q2');
        await _goNext(tester);

        expect(find.text('Session Results'), findsOneWidget);
        expect(find.text('Practice Complete!'), findsOneWidget);
      });

      testWidgets('shows progress indicator 1/2 during exam', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [
          _typedQuestion(id: 'q1'),
          _typedQuestion(id: 'q2'),
        ]));
        await tester.pumpAndSettle();

        await _startExam(tester);

        expect(find.text('1/2'), findsOneWidget);
        expect(find.byIcon(Icons.timer), findsOneWidget);
      });
    });

    group('results screen', () {
      Future<void> completeOneQuestion(WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();
        await _startExam(tester);
        await _answerQuestion(tester, 'Answer q1');
        await _goNext(tester);
      }

      testWidgets('shows done and practice again buttons', (tester) async {
        await completeOneQuestion(tester);
        await tester.ensureVisible(find.text('Done'));
        await tester.pump();
        expect(find.text('Done'), findsOneWidget);
        expect(find.text('Practice Again'), findsOneWidget);
      });
    });

    group('confidence selector', () {
      testWidgets('appears after submission', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [_typedQuestion()]));
        await tester.pumpAndSettle();
        await _startExam(tester);
        await _answerQuestion(tester, 'Answer q1');

        expect(find.text('How confident are you?'), findsOneWidget);
      });
    });

    group('error handling', () {
      testWidgets('load error shows no-questions dialog', (tester) async {
        await tester.pumpWidget(ProviderScope(
          overrides: [
            questionRepositoryProvider.overrideWithValue(_FailingQuestionRepository()),
            sessionRepositoryProvider.overrideWithValue(_FakeSessionRepo()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: ExamSessionScreen(subjectId: 'sub1', subjectName: 'Mathematics'),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('No Questions Available'), findsOneWidget);
        expect(find.text('Upload Materials'), findsWidgets);
        expect(find.text('OK'), findsOneWidget);
      });
    });

    group('null markscheme', () {
      testWidgets('answer with null markscheme shows Incorrect', (tester) async {
        final now = DateTime(2024, 1, 1);
        final q = Question(
          id: 'q-no', text: 'No markscheme?', type: QuestionType.typedAnswer,
          subjectId: 'sub1', topicId: 't1', markscheme: null, options: [],
          createdAt: now, updatedAt: now,
        );

        await tester.pumpWidget(_buildTestApp(questions: [q]));
        await tester.pumpAndSettle();
        await _startExam(tester);
        await _answerQuestion(tester, 'any answer');

        expect(find.text('Incorrect'), findsOneWidget);
      });
    });

    group('results stats', () {
      testWidgets('shows stat rows after multi-question exam', (tester) async {
        await tester.pumpWidget(_buildTestApp(questions: [
          _typedQuestion(id: 'q1'),
          _typedQuestion(id: 'q2'),
        ]));
        await tester.pumpAndSettle();

        await _startExam(tester);
        await _answerQuestion(tester, 'Answer q1');
        await _goNext(tester);
        await _answerQuestion(tester, 'Wrong');
        await _goNext(tester);

        await tester.ensureVisible(find.text('Total Questions'));
        await tester.pump();
        expect(find.text('Total Questions'), findsOneWidget);
        expect(find.text('Correct Answers'), findsOneWidget);
        expect(find.text('Incorrect'), findsOneWidget);
        expect(find.text('Skipped'), findsOneWidget);
        expect(find.text('Accuracy'), findsOneWidget);
      });
    });

    group('feedback explanation', () {
      testWidgets('shows explanation text in feedback', (tester) async {
        final now = DateTime(2024, 1, 1);
        final q = Question(
          id: 'q-exp', text: 'With explanation?', type: QuestionType.typedAnswer,
          subjectId: 'sub1', topicId: 't1',
          markscheme: Markscheme(questionId: 'q-exp', correctAnswer: 'Yes', explanation: 'Because of reason'),
          options: [], createdAt: now, updatedAt: now,
        );

        await tester.pumpWidget(_buildTestApp(questions: [q]));
        await tester.pumpAndSettle();
        await _startExam(tester);
        await _answerQuestion(tester, 'Yes');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.ensureVisible(find.text('Because of reason'));
        await tester.pump();
        expect(find.text('Because of reason'), findsOneWidget);
      });
    });
  });
}
