import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/focus_mode/presentation/widgets/inline_practice_widget.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_session_question_card.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_feedback_widget.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryRecorderProvider;
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;
  _FakeQuestionRepository(this._questions);

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(List.from(_questions));
}

class _FakeMasteryRecorder extends MasteryRecorder {
  _FakeMasteryRecorder()
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

Widget _buildTestApp(
  Widget child, {
  QuestionRepository? questionRepo,
  MasteryRecorder? masteryRecorder,
}) {
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(
        questionRepo ?? _FakeQuestionRepository([]),
      ),
      masteryRecorderProvider.overrideWithValue(
        masteryRecorder ?? _FakeMasteryRecorder(),
      ),
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
  );
}

void _noopOnComplete(int correct, int total, Map<String, SubjectAccuracy> accuracies) {}

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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();
      expect(find.text('0 correct'), findsOneWidget);
    });

    testWidgets('shows submit button before answering', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete),
        questionRepo: _FakeQuestionRepository(questions),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Submit Answer'), findsOneWidget);
    });

    testWidgets('shows PracticeFeedbackWidget with Correct! after correct answer', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
      Map<String, SubjectAccuracy>? capturedAccuracies;
      final questions = [typedQuestion(id: 'q1')];

      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(
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

      expect(capturedCorrect, 1);
      expect(capturedTotal, 1);
      expect(capturedAccuracies, isNotNull);
      expect(capturedAccuracies!.keys, contains('sub-1'));
      expect(capturedAccuracies!['sub-1']!.correct, 1);
      expect(capturedAccuracies!['sub-1']!.total, 1);
    });

    testWidgets('shows completion card with score after finishing', (tester) async {
      final questions = [typedQuestion(id: 'q1')];
      await tester.pumpWidget(_buildTestApp(
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
        InlinePracticeWidget(onComplete: _noopOnComplete),
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
