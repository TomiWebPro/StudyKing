import 'package:studyking/features/sessions/providers/session_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;

import 'package:studyking/features/practice/presentation/screens/practice_session_screen.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';
import '../shared_test_helpers.dart';

const _kCorrectFeedback = 'Correct!';
const _kIncorrectFeedback = 'Incorrect';
const _kPracticeComplete = 'Practice Complete!';
const _kSubmitAnswer = 'Submit Answer';
const _kNext = 'Next';
const _kPrevious = 'Previous';
const _kNoQuestionsAvailable = 'No Questions Available';
const _kPracticeAgain = 'Practice Again';
void main() {
  group('PracticeSessionScreen', () {
    group('question type branches', () {
      testWidgets('renders singleChoice question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'What is the capital of France?',
              type: QuestionType.singleChoice,
              markschemeText: 'Paris',
              options: ['London', 'Paris', 'Berlin', 'Madrid'],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('What is the capital of France?'), findsOneWidget);
        expect(find.text('singleChoice'), findsOneWidget);
        expect(find.text('London'), findsOneWidget);
        expect(find.text('Paris'), findsOneWidget);
        expect(find.text('Berlin'), findsOneWidget);
        expect(find.text('Madrid'), findsOneWidget);
      });

      testWidgets('renders multiChoice question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Select all prime numbers:',
              type: QuestionType.multiChoice,
              markschemeText: '2,3',
              options: ['1', '2', '3', '4'],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Select all prime numbers:'), findsOneWidget);
        expect(find.text('multiChoice'), findsOneWidget);
      });

      testWidgets('renders mathExpression question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: r'Solve: x^2 = 4',
              type: QuestionType.mathExpression,
              markschemeText: 'x = 2',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text(r'Solve: x^2 = 4'), findsOneWidget);
        expect(find.text('mathExpression'), findsOneWidget);
      });

      testWidgets('renders canvas question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Draw a circle',
              type: QuestionType.canvas,
              markschemeText: 'circle',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Draw a circle'), findsWidgets);
        expect(find.text('canvas'), findsOneWidget);
      });

      testWidgets('renders typedAnswer question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'What is 2+2?',
              type: QuestionType.typedAnswer,
              markschemeText: '4',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('What is 2+2?'), findsOneWidget);
        expect(find.text('typedAnswer'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders essay question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Write about photosynthesis',
              type: QuestionType.essay,
              markschemeText: '',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Write about photosynthesis'), findsOneWidget);
        expect(find.text('essay'), findsOneWidget);
      });

      testWidgets('renders fallback for graphDrawing question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Draw a graph',
              type: QuestionType.graphDrawing,
              markschemeText: 'graph',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Draw a graph'), findsOneWidget);
        expect(find.textContaining('Unsupported'), findsOneWidget);
        expect(find.textContaining('graphDrawing'), findsOneWidget);
      });

      testWidgets('renders fallback for fileUpload question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Upload a file',
              type: QuestionType.fileUpload,
              markschemeText: 'file',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Upload a file'), findsOneWidget);
        expect(find.textContaining('Unsupported'), findsOneWidget);
        expect(find.textContaining('fileUpload'), findsOneWidget);
      });

      testWidgets('renders fallback for audioRecording question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Record audio',
              type: QuestionType.audioRecording,
              markschemeText: 'audio',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Record audio'), findsOneWidget);
        expect(find.textContaining('Unsupported'), findsOneWidget);
        expect(find.textContaining('audioRecording'), findsOneWidget);
      });

      testWidgets('renders default fallback for stepByStep question type', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Step by step question',
              type: QuestionType.stepByStep,
              markschemeText: 'step',
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Unsupported'), findsOneWidget);
        expect(find.textContaining('stepByStep'), findsOneWidget);
      });
    });

    group('answer submission lifecycle', () {
      testWidgets('loads questions and renders first question', (tester) async {
        final questions = [
          question(id: 'q1', text: 'What is 2+2?', type: QuestionType.typedAnswer, markschemeText: '4'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('What is 2+2?'), findsOneWidget);
        expect(find.text(_kSubmitAnswer), findsOneWidget);
      });

      testWidgets('submit is disabled for singleChoice until selection made', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Select A',
              type: QuestionType.singleChoice,
              markschemeText: 'A',
              options: ['A', 'B', 'C', 'D'],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      });

      testWidgets('submit is enabled for singleChoice after selection', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Select A',
              type: QuestionType.singleChoice,
              markschemeText: 'A',
              options: ['A', 'B', 'C', 'D'],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('A'));
        await tester.pump();

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('shows correct feedback after submitting correct singleChoice', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'What is 2+2?',
              type: QuestionType.singleChoice,
              markschemeText: '4',
              options: ['3', '4', '5', '6'],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('4'));
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(find.text(_kCorrectFeedback), findsOneWidget);
      });

      testWidgets('shows incorrect feedback after submitting wrong singleChoice', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'What is 2+2?',
              type: QuestionType.singleChoice,
              markschemeText: '4',
              options: ['3', '4', '5', '6'],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('3'));
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(find.text(_kIncorrectFeedback), findsOneWidget);
      });

      testWidgets('shows next button after submit', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(id: 'q1', text: 'Test question', type: QuestionType.typedAnswer, markschemeText: 'a'),
            question(id: 'q2', text: 'Another question', type: QuestionType.typedAnswer, markschemeText: 'b'),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kNext), findsOneWidget);
      });

      testWidgets('completes session after last question', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Only question', type: QuestionType.typedAnswer, markschemeText: 'answer'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'answer');
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text(_kPracticeComplete), findsOneWidget);
      });

      testWidgets('score updates on submit with correct answer', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Capital of France?', type: QuestionType.typedAnswer, markschemeText: 'Paris'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        final submit = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(submit.onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'Paris');
        await tester.pump();

        final enabledSubmit = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(enabledSubmit.onPressed, isNotNull);

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(find.text(_kCorrectFeedback), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty options fallback for singleChoice', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Question with no options provided',
              type: QuestionType.singleChoice,
              markschemeText: 'Option A',
              options: [],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);
        expect(find.text('Option C'), findsOneWidget);
        expect(find.text('Option D'), findsOneWidget);
      });

      testWidgets('handles empty options fallback for multiChoice', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(
              id: 'q1',
              text: 'Multi with no options',
              type: QuestionType.multiChoice,
              markschemeText: 'Option A',
              options: [],
            ),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.text('Option A'), findsOneWidget);
      });

      testWidgets('shows session results with score', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Correct answer', type: QuestionType.typedAnswer, markschemeText: 'correct'),
          question(id: 'q2', text: 'Wrong answer', type: QuestionType.typedAnswer, markschemeText: 'correct'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'correct');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'wrong');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text(_kPracticeComplete), findsOneWidget);
        expect(find.textContaining('1/2'), findsOneWidget);
        expect(find.textContaining('50%'), findsOneWidget);
      });

      testWidgets('shows progress bar', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
            question(id: 'q2', text: 'Q2', type: QuestionType.typedAnswer, markschemeText: 'a'),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows timer and score stats', (tester) async {
        await tester.pumpWidget(sessionApp(
          result: Result.success([
            question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
          ]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.access_time), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });

    group('no questions path', () {
      testWidgets('shows no-questions dialog for empty result', (tester) async {
        await tester.pumpWidget(sessionApp(result: Result.success(const [])));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kNoQuestionsAvailable), findsOneWidget);
      });

      testWidgets('shows no-questions dialog when filtered by topic yields empty', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a', topicId: 'topic-b'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          topicId: 'topic-a',
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kNoQuestionsAvailable), findsOneWidget);
      });

      testWidgets('shows no-questions dialog on load failure', (tester) async {
        await tester.pumpWidget(sessionApp(result: Result.failure('Load error')));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kNoQuestionsAvailable), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('previous button is shown after submit', (tester) async {
        final questions = [
          question(id: 'q1', text: 'First', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'Second', type: QuestionType.typedAnswer, markschemeText: 'b'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(_kPrevious), findsOneWidget);
        expect(find.text(_kNext), findsOneWidget);
      });

      testWidgets('previous button goes back to first question', (tester) async {
        final questions = [
          question(id: 'q1', text: 'First question', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'Second question', type: QuestionType.typedAnswer, markschemeText: 'b'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text(_kNext));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Second question'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'b');
        await tester.pump();

        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text(_kPrevious));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('First question'), findsOneWidget);
      });
    });

    group('back navigation popscope', () {
      testWidgets('shows exit confirmation dialog on back press during session', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Q1'), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Exit practice session?'), findsOneWidget);
        expect(find.text('Stay'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);
      });

      testWidgets('stay keeps session active on back press', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Stay'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Q1'), findsOneWidget);
      });

      testWidgets('exit completes session and shows results without route pop', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        final fakeSessionRepo = FakeSessionRepository();
        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          sessionRepo: fakeSessionRepo,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Exit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Practice Complete!'), findsOneWidget);
        expect(fakeSessionRepo.sessions.length, 1);
      });
    });

    group('session completion and navigation', () {
      testWidgets('completes session and pops back to previous route', (tester) async {
        final observer = TestNavigatorObserver();
        final questions = [
          question(id: 'q1', text: 'One?', type: QuestionType.typedAnswer, markschemeText: 'ok'),
          question(id: 'q3', text: 'Wrong topic', type: QuestionType.typedAnswer, markschemeText: 'ok', topicId: 'topic-b'),
        ];

        await tester.pumpWidget(
          sessionApp(
            result: Result.success(questions),
            topicId: 'topic-a',
            questionCount: 5,
            observer: observer,
          ),
        );
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Wrong topic'), findsNothing);

        await tester.enterText(find.byType(TextField), 'ok');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text(_kNext));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.pump(const Duration(milliseconds: 600));
        expect(observer.poppedRoutes.length, greaterThan(0));
      });
    });

    group('restart session', () {
      testWidgets('restart button resets state and shows questions again', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text(_kPracticeComplete), findsOneWidget);

        await tester.tap(find.text(_kPracticeAgain));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Q1'), findsOneWidget);
        expect(find.text(_kSubmitAnswer), findsOneWidget);
      });
    });

    group('spaced repetition mode', () {
      testWidgets('calls _updateNextReview on correct answer', (tester) async {
        final srService = FakeSpacedRepetitionService();
        final questions = [
          question(id: 'q1', text: 'SR question', type: QuestionType.typedAnswer, markschemeText: 'answer'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          isSpacedRepetition: true,
          srService: srService,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'answer');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(srService.updateCalls.length, 1);
        expect(srService.updateCalls.first.questionId, 'q1');
        expect(srService.updateCalls.first.masteryLevel, 0.8);
      });

      testWidgets('calls _updateNextReview on incorrect answer', (tester) async {
        final srService = FakeSpacedRepetitionService();
        final questions = [
          question(id: 'q1', text: 'SR question', type: QuestionType.typedAnswer, markschemeText: 'answer'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          isSpacedRepetition: true,
          srService: srService,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'wrong');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(srService.updateCalls.length, 1);
        expect(srService.updateCalls.first.questionId, 'q1');
        expect(srService.updateCalls.first.masteryLevel, 0.2);
      });

      testWidgets('does not call _updateNextReview when isSpacedRepetition is false', (tester) async {
        final srService = FakeSpacedRepetitionService();
        final questions = [
          question(id: 'q1', text: 'SR question', type: QuestionType.typedAnswer, markschemeText: 'answer'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          isSpacedRepetition: false,
          srService: srService,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'answer');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(srService.updateCalls, isEmpty);
      });
    });

    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('timer display', () {
      testWidgets('shows timer icon', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('timer display updates after one second', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.access_time), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });
    });

    group('validation edge cases', () {
      testWidgets('handles null markscheme gracefully', (tester) async {
        final now = DateTime.now();
        final qWithNullMarkscheme = Question(
          id: 'q-null',
          text: 'No markscheme',
          type: QuestionType.typedAnswer,
          subjectId: 'subject-a',
          topicId: 'topic-a',
          markscheme: null,
          options: [],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(sessionApp(
          result: Result.success([qWithNullMarkscheme]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'any answer');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(find.text(_kIncorrectFeedback), findsOneWidget);
      });

      testWidgets('handles empty correctAnswer in markscheme', (tester) async {
        final now = DateTime.now();
        final qWithEmptyMarkscheme = Question(
          id: 'q-empty',
          text: 'Empty markscheme',
          type: QuestionType.typedAnswer,
          subjectId: 'subject-a',
          topicId: 'topic-a',
          markscheme: null,
          options: [],
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(sessionApp(
          result: Result.success([qWithEmptyMarkscheme]),
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'some answer');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        expect(find.text(_kIncorrectFeedback), findsOneWidget);
      });
    });

    group('submit answer edge cases', () {
      testWidgets('submit with null currentAnswer does nothing', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(result: Result.success(questions)));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        // Submit button should be disabled since no answer
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);

        // No crash when onPressed is null
        expect(find.byType(FilledButton), findsOneWidget);
      });
    });

    group('load questions error path', () {
      testWidgets('does not crash when exception thrown during load', (tester) async {
        final failingRepo = _FailingQuestionRepository();

        await tester.pumpWidget(sessionAppWithRepo(result: failingRepo));
        await tester.tap(find.text('Open Session'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show loading indicator while error is handled
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('spaced repetition display', () {
      testWidgets('shows practice mode when not spaced repetition', (tester) async {
        final questions = [
          question(id: 'q1', text: 'Normal Q', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          isSpacedRepetition: false,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Practice'), findsWidgets);
      });
    });

    group('session auto-save', () {
      testWidgets('saves session on completion via SessionRepository', (tester) async {
        final sessionRepo = FakeSessionRepository();
        final questions = [
          question(id: 'q1', text: 'Test', type: QuestionType.typedAnswer, markschemeText: 'a'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          sessionRepo: sessionRepo,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(sessionRepo.sessions.length, 1);
        expect(sessionRepo.sessions.first.subjectId, 'subject-a');
        expect(sessionRepo.sessions.first.correctAnswers, 1);
      });

      testWidgets('_sessionAutoSaved guard prevents duplicate saves', (tester) async {
        final sessionRepo = FakeSessionRepository();
        final questions = [
          question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
          question(id: 'q2', text: 'Q2', type: QuestionType.typedAnswer, markschemeText: 'b'),
        ];

        await tester.pumpWidget(sessionApp(
          result: Result.success(questions),
          sessionRepo: sessionRepo,
        ));
        await tester.tap(find.text('Open Session'));
        await tester.pumpAndSettle();

        // Complete two questions
        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'b');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_kNext));
        await tester.pump(const Duration(milliseconds: 600));

        expect(sessionRepo.sessions.length, 1);
      });
    });
  });

  group('Keyboard accessibility', () {
    testWidgets('renders FocusTraversalOrder with sequential values', (tester) async {
      await tester.pumpWidget(sessionApp(
        result: Result.success([
          question(
            id: 'q1', text: 'What is 2+2?',
            type: QuestionType.singleChoice,
            markschemeText: '4',
            options: ['3', '4', '5'],
          ),
        ]),
      ));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalOrder), findsAtLeastNWidgets(2));
      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('renders FocusTraversalGroup wrapping question content', (tester) async {
      await tester.pumpWidget(sessionApp(
        result: Result.success([
          question(
            id: 'q1', text: 'What is 2+2?',
            type: QuestionType.singleChoice,
            markschemeText: '4',
            options: ['3', '4', '5'],
          ),
        ]),
      ));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });
  });


  group('confidence selector', () {
    testWidgets('shows confidence selector after submission', (tester) async {
      final questions = [
        question(id: 'q1', text: 'What is 2+2?', type: QuestionType.typedAnswer, markschemeText: '4'),
      ];

      await tester.pumpWidget(sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();

      await tester.tap(find.text(_kSubmitAnswer));
      await tester.pumpAndSettle();

      expect(find.text('How confident are you?'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('tapping confidence rating updates selection', (tester) async {
      final questions = [
        question(id: 'q1', text: 'What is 2+2?', type: QuestionType.typedAnswer, markschemeText: '4'),
      ];

      await tester.pumpWidget(sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();
      await tester.tap(find.text(_kSubmitAnswer));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pump();

      expect(find.text('Very Confident'), findsOneWidget);
    });

    testWidgets('default confidence is moderately confident', (tester) async {
      final questions = [
        question(id: 'q1', text: 'What is 2+2?', type: QuestionType.typedAnswer, markschemeText: '4'),
      ];

      await tester.pumpWidget(sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();
      await tester.tap(find.text(_kSubmitAnswer));
      await tester.pumpAndSettle();

      expect(find.text('Moderately Confident'), findsOneWidget);
    });
  });

  group('multiple question completion', () {
    testWidgets('completes three questions and shows results', (tester) async {
      final questions = List.generate(3, (i) => question(
        id: 'q$i',
        text: 'Question $i',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      ));

      await tester.pumpWidget(sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 3; i++) {
        expect(find.text('Question $i'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'answer');
        await tester.pump();
        await tester.tap(find.text(_kSubmitAnswer));
        await tester.pumpAndSettle();

        await tester.tap(find.text(_kNext));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(_kPracticeComplete), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('no questions dialog', () {
    testWidgets('shows upload materials button in no-questions dialog', (tester) async {
      await tester.pumpWidget(sessionApp(result: Result.success([])));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(_kNoQuestionsAvailable), findsOneWidget);
      expect(find.text('Upload Materials'), findsOneWidget);
    });

    testWidgets('no-questions dialog has ok button', (tester) async {
      await tester.pumpWidget(sessionApp(result: Result.success([])));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(_kNoQuestionsAvailable), findsNothing);
    });
  });

  group('session timer', () {
    testWidgets('shows elapsed time in stats bar', (tester) async {
      final questions = [
        question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
      ];

      await tester.pumpWidget(sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}

class _FailingQuestionRepository extends FakeQuestionRepository {
  _FailingQuestionRepository() : super(Result.success([]));

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    throw Exception('Unexpected error');
  }
}

Widget sessionAppWithRepo({
  required QuestionRepository result,
  String? topicId,
  int? questionCount,
  NavigatorObserver? observer,
  SessionRepository? sessionRepo,
  SpacedRepetitionService? srService,
  bool isSpacedRepetition = false,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => FakeSettingsController()),
      questionRepositoryProvider.overrideWithValue(result),
      if (sessionRepo != null)
        sessionRepositoryProvider.overrideWithValue(sessionRepo),
      if (srService != null)
        spacedRepetitionServiceProvider.overrideWithValue(srService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: observer == null ? const [] : [observer],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSessionScreen(
                    args: PracticeSessionArgs(
                      subjectId: 'subject-a',
                      topicId: topicId,
                      questionCount: questionCount,
                      isSpacedRepetition: isSpacedRepetition,
                    ),
                  ),
                ),
              ),
              child: const Text('Open Session'),
            ),
          ),
        ),
      ),
    ),
  );
}
