import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/inline_practice_widget.dart';
import 'package:studyking/features/focus_mode/services/focus_practice_service.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart' show focusPracticeServiceProvider;
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryRecorderProvider, spacedRepetitionServiceProvider, masteryGraphServiceProvider;
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/core/providers/service_providers.dart' show studentIdValueProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeSessionRepository extends SessionRepository {
  @override
  Future<Result<void>> save(String key, Session item) async => Result.success(null);

  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);
}

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    _attempts.add(attempt);
    return Result.success(null);
  }

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    return Result.success(_attempts.where((a) => a.studentId == studentId).toList());
  }

  @override
  Future<Result<List<StudentAttempt>>> getBySubject(String subjectId) async {
    return Result.success(_attempts.where((a) => a.subjectId == subjectId).toList());
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final QuestionRepository _fakeQRepo;

  _FakeSpacedRepetitionService({required super.questionRepo})
      : _fakeQRepo = questionRepo,
        super(attemptRepo: _FakeAttemptRepository());

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
    final allResult = await _fakeQRepo.getAll();
    final all = allResult.data ?? [];
    final reviewDate = asOf ?? DateTime.now();
    final due = all.where((q) => (q.nextReview ?? DateTime.now()).isBefore(reviewDate)).toList();
    return Result.success(due);
  }
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(List.from(_questions));
}

class _FakeMasteryRecorder extends MasteryRecorder {
  int recordAttemptCallCount = 0;
  bool? lastIsCorrect;

  _FakeMasteryRecorder()
      : super(
          masteryGraphService: MasteryGraphService(
            masteryStateRepo: null,
            questionMasteryRepo: null,
            topicDependencyRepo: null,
            questionEvaluationRepo: null,
            calculationService: null,
          ),
          srEngine: SpacedRepetitionEngine(),
          attemptRepo: _FakeAttemptRepository(),
          questionMasteryRepo: _FakeQuestionMasteryStateRepository(),
          questionRepo: _FakeQuestionRepository([]),
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
    recordAttemptCallCount++;
    lastIsCorrect = isCorrect;
    return Result.success(null);
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success([]);
  }
}

class _FakeQuestionMasteryStateRepository extends QuestionMasteryStateRepository {
  final Map<String, QuestionMasteryState> _states = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    final key = '${studentId}_$questionId';
    final existing = _states[key];
    if (existing != null) return Result.success(existing);
    final newState = QuestionMasteryState.initial(
      studentId: studentId,
      questionId: questionId,
      now: DateTime.now(),
    );
    _states[key] = newState;
    return Result.success(newState);
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(QuestionMasteryState state) async {
    final key = '${state.studentId}_${state.questionId}';
    _states[key] = state;
    return Result.success(null);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAllForStudent(String studentId) async {
    return Result.success(
      _states.values.where((s) => s.studentId == studentId).toList(),
    );
  }
}

Widget _buildTestApp(
  Widget child, {
  QuestionRepository? questionRepo,
  MasteryRecorder? masteryRecorder,
}) {
  final fakeQRepo = questionRepo ?? _FakeQuestionRepository([]);
  final srService = _FakeSpacedRepetitionService(questionRepo: fakeQRepo);
  final mgService = _FakeMasteryGraphService();
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(fakeQRepo),
      masteryRecorderProvider.overrideWithValue(
        masteryRecorder ?? _FakeMasteryRecorder(),
      ),
      spacedRepetitionServiceProvider.overrideWithValue(srService),
      masteryGraphServiceProvider.overrideWithValue(mgService),
      focusPracticeServiceProvider.overrideWithValue(
        FocusPracticeService(
          srService: srService,
          masteryGraphService: mgService,
          sessionRepository: _FakeSessionRepository(),
          questionRepository: fakeQRepo,
        ),
      ),
      studentIdValueProvider.overrideWithValue('test-student'),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

Question typedQuestion({
  required String id,
  String correctAnswer = 'Paris',
  String explanation = 'Paris is the capital of France.',
  DateTime? nextReview,
}) {
  return Question(
    id: id,
    text: 'What is the capital of France?',
    type: QuestionType.typedAnswer,
    subjectId: 'sub-1',
    topicId: 'top-1',
    markscheme: Markscheme(
      correctAnswer: correctAnswer,
      explanation: explanation,
    ),
    createdAt: DateTime(2026, 5, 19),
    updatedAt: DateTime(2026, 5, 19),
    nextReview: nextReview,
  );
}

void _noopOnComplete(int correct, int total, Map<String, TopicAccuracy> accuracies) {}

void main() {
  group('InlinePracticeWidget', () {
    testWidgets('can be constructed with required parameters', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(InlinePracticeWidget), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no questions available', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
      expect(find.text('No Questions Available'), findsOneWidget);
    });

    testWidgets('renders PracticeSessionQuestionCard when questions available', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionQuestionCard), findsOneWidget);
    });

    testWidgets('loads due questions when not quick practice mode', (tester) async {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      final future = DateTime.now().add(const Duration(days: 1));
      final questions = [
        typedQuestion(id: 'q1', nextReview: past),
        typedQuestion(id: 'q2', nextReview: future),
      ];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.spacedRepetition),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSessionQuestionCard), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator with correct progress', (tester) async {
      final questions = [
        typedQuestion(id: 'q1'),
        typedQuestion(id: 'q2'),
      ];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.5, 0.01));
    });

    testWidgets('shows answer count text with correct label', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();
      expect(find.text('0 correct'), findsOneWidget);
    });

    testWidgets('shows submit button before answering', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Submit Answer'), findsOneWidget);
    });

    testWidgets('shows PracticeFeedbackWidget with Correct! after correct answer', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeFeedbackWidget), findsOneWidget);
      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('shows PracticeFeedbackWidget with Incorrect after wrong answer', (tester) async {
      final questions = [typedQuestion(id: 'q1', correctAnswer: 'Berlin')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'London');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeFeedbackWidget), findsOneWidget);
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('shows explanation in feedback widget after correct answer', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Paris is the capital of France.'), findsOneWidget);
    });

    testWidgets('shows Next button after correct answer when more questions remain', (tester) async {
      final questions = [
        typedQuestion(id: 'q1'),
        typedQuestion(id: 'q2'),
      ];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows Done button on last question after correct answer', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('calls onComplete with correct and total when all questions answered', (tester) async {
      int? capturedCorrect;
      int? capturedTotal;
      Map<String, TopicAccuracy>? capturedAccuracies;
      final questions = [typedQuestion(id: 'q1')];

      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(
          sessionType: FocusSessionType.quickPractice,
          onComplete: (correct, total, accuracies) {
            capturedCorrect = correct;
            capturedTotal = total;
            capturedAccuracies = accuracies;
          },
        ),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(capturedCorrect, 1);
      expect(capturedTotal, 1);
      expect(capturedAccuracies, isNotNull);
      expect(capturedAccuracies!.keys, contains('top-1'));
      expect(capturedAccuracies!['top-1']!.correct, 1);
      expect(capturedAccuracies!['top-1']!.total, 1);
    });

    testWidgets('shows completion card with score after finishing', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Correct!'), findsOneWidget);
      expect(find.textContaining('1 / 1'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('records all attempts (correct and incorrect) via MasteryRecorder', (tester) async {
      final recorder = _FakeMasteryRecorder();
      final questions = [typedQuestion(id: 'q1', correctAnswer: 'Berlin')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
        masteryRecorder: recorder,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'London');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(recorder.recordAttemptCallCount, 1);
      expect(recorder.lastIsCorrect, false);
    });

    testWidgets('filters questions by subjectId when provided', (tester) async {
      final questions = [
        typedQuestion(id: 'q1'),
        Question(
          id: 'q2',
          text: 'What is 2+2?',
          type: QuestionType.typedAnswer,
          subjectId: 'sub-2',
          topicId: 'top-1',
          markscheme: Markscheme(correctAnswer: '4'),
          createdAt: DateTime(2026, 5, 19),
          updatedAt: DateTime(2026, 5, 19),
        ),
      ];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(
          subjectId: 'sub-2',
          sessionType: FocusSessionType.quickPractice,
          onComplete: _noopOnComplete,
        ),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      expect(find.text('What is 2+2?'), findsOneWidget);
      expect(find.text('What is the capital of France?'), findsNothing);
    });

    testWidgets('uses default questionCount of 10', (tester) async {
      final questions = List.generate(15, (i) => typedQuestion(id: 'q$i'));
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete, sessionType: FocusSessionType.quickPractice),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(1 / 10, 0.01));
    });
  });
}
