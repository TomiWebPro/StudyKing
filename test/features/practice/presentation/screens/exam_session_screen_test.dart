import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
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
import '../../../../helpers/navigator_observer_helper.dart';

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

class _FakeSessionRepository extends SessionRepository {
  _FakeSessionRepository() : super(clock: _FakeClock(DateTime(2024, 6, 15, 12, 0)));

  @override
  Future<Result<void>> save(String key, Session item) async {
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String key) async {
    return Result.success(null);
  }
}

Question _createQuestion({String id = 'q1', String topicId = 't1', int difficulty = 1}) {
  final now = DateTime(2024, 1, 1);
  return Question(
    id: id,
    text: 'Test question $id?',
    type: QuestionType.singleChoice,
    difficulty: difficulty,
    subjectId: 'sub1',
    topicId: topicId,
    markscheme: Markscheme(questionId: id, correctAnswer: 'Answer $id'),
    options: ['A', 'B', 'C', 'D'],
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(
      _questions.where((q) => q.subjectId == subjectId).toList(),
    );
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

Widget _buildTestApp({
  required List<Question> questions,
  NavigatorObserver? observer,
}) {
  final fakeQuestionRepo = _FakeQuestionRepository(questions);
  final fakeSessionRepo = _FakeSessionRepository();
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
      home: ExamSessionScreen(
        subjectId: 'sub1',
        subjectName: 'Mathematics',
      ),
    ),
  );
}

void main() {
  group('ExamSessionScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(),
      ]));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders config screen with questions', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
        _createQuestion(id: 'q3'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Exam Configuration'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('Start Exam'), findsOneWidget);
    });

    testWidgets('config screen shows subject name', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(),
      ]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mathematics'), findsOneWidget);
    });

    testWidgets('shows no questions screen when no questions available', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        questions: [],
        observer: observer,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Questions Available'), findsOneWidget);
      expect(find.text('Upload Materials'), findsOneWidget);
    });

    testWidgets('duration selector changes duration', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();
    });

    testWidgets('question count selector reloads questions', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
    });

    testWidgets('starts exam when Start Exam is tapped', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1', difficulty: 1),
        _createQuestion(id: 'q2', difficulty: 2),
        _createQuestion(id: 'q3', difficulty: 3),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      expect(find.text('Submit Answer'), findsOneWidget);
    });

    testWidgets('shows timer display during exam', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1', difficulty: 1),
        _createQuestion(id: 'q2', difficulty: 2),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('shows question progress during exam', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
        _createQuestion(id: 'q3'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('answer submission shows feedback', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      await tester.tap(find.text('Answer q1'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();

      expect(find.textContaining('Correct'), findsWidgets);
    });

    testWidgets('navigates to next question after submission', (tester) async {
      await tester.pumpWidget(_buildTestApp(questions: [
        _createQuestion(id: 'q1'),
        _createQuestion(id: 'q2'),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      await tester.tap(find.text('Answer q1'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('2/2'), findsOneWidget);
    });

    testWidgets('shows results screen after completing all questions', (tester) async {
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(_buildTestApp(
        questions: [
          _createQuestion(id: 'q1'),
          _createQuestion(id: 'q2'),
        ],
        observer: observer,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pump();

      await tester.tap(find.text('Answer q1'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      await tester.tap(find.text('Answer q2'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Session Results'), findsOneWidget);
      expect(find.textContaining('Correct'), findsWidgets);
    });
  });
}
