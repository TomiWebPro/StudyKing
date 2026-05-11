import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/presentation/practice_session_screen.dart';

class _FakeQuestionRepository extends QuestionRepository {
  _FakeQuestionRepository(this.result);
  final Result<List<Question>> result;

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async => result;
}

Question _question({
  required String id,
  required String text,
  required QuestionType type,
  required String markschemeText,
  List<String> options = const [],
  String topicId = 'topic-a',
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    subjectId: 'subject-a',
    topicId: topicId,
    markscheme: Markscheme(questionId: id, correctAnswer: markschemeText),
    options: options,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _sessionApp({
  required Result<List<Question>> result,
  String? topicId,
  int? questionCount,
}) {
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(_FakeQuestionRepository(result)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSessionScreen(
                    subjectId: 'subject-a',
                    topicId: topicId,
                    questionCount: questionCount,
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

void main() {
  group('PracticeSessionScreen - Question Type Branches', () {
    testWidgets('renders singleChoice question type', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'What is the capital of France?',
          type: QuestionType.singleChoice,
          markschemeText: 'Paris',
          options: ['London', 'Paris', 'Berlin', 'Madrid'],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
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
      final questions = [
        _question(
          id: 'q1',
          text: 'Select all prime numbers:',
          type: QuestionType.multiChoice,
          markschemeText: '2,3',
          options: ['1', '2', '3', '4'],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text('Select all prime numbers:'), findsOneWidget);
      expect(find.text('multiChoice'), findsOneWidget);
    });

    testWidgets('renders mathExpression question type', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: r'Solve: x^2 = 4',
          type: QuestionType.mathExpression,
          markschemeText: 'x = 2',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text(r'Solve: x^2 = 4'), findsOneWidget);
      expect(find.text('mathExpression'), findsOneWidget);
    });

    testWidgets('renders canvas question type', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Draw a circle',
          type: QuestionType.canvas,
          markschemeText: 'circle',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text('Draw a circle'), findsWidgets);
      expect(find.text('canvas'), findsOneWidget);
    });

    testWidgets('renders typedAnswer question type', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'What is 2+2?',
          type: QuestionType.typedAnswer,
          markschemeText: '4',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text('What is 2+2?'), findsOneWidget);
      expect(find.text('typedAnswer'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders essay question type', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Write about photosynthesis',
          type: QuestionType.essay,
          markschemeText: '',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text('Write about photosynthesis'), findsOneWidget);
      expect(find.text('essay'), findsOneWidget);
    });

    testWidgets('renders default fallback for unknown question type', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Unknown type question',
          type: QuestionType.stepByStep,
          markschemeText: 'step',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Unsupported'), findsOneWidget);
    });
  });

  group('PracticeSessionScreen - Answer Submission Lifecycle', () {
    testWidgets('submit is disabled for singleChoice until selection made', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Select A',
          type: QuestionType.singleChoice,
          markschemeText: 'A',
          options: ['A', 'B', 'C', 'D'],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('submit is enabled for singleChoice after selection', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Select A',
          type: QuestionType.singleChoice,
          markschemeText: 'A',
          options: ['A', 'B', 'C', 'D'],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows feedback after submit for singleChoice correct answer', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'What is 2+2?',
          type: QuestionType.singleChoice,
          markschemeText: '4',
          options: ['3', '4', '5', '6'],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
    });

    testWidgets('shows feedback after submit for singleChoice wrong answer', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'What is 2+2?',
          type: QuestionType.singleChoice,
          markschemeText: '4',
          options: ['3', '4', '5', '6'],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pump();

      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('shows next button after submit', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Test question',
          type: QuestionType.typedAnswer,
          markschemeText: 'a',
        ),
        _question(
          id: 'q2',
          text: 'Another question',
          type: QuestionType.typedAnswer,
          markschemeText: 'b',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();

      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('completes session after last question', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Only question',
          type: QuestionType.typedAnswer,
          markschemeText: 'answer',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'answer');
      await tester.pump();

      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Practice Complete!'), findsOneWidget);
    });
  });

  group('PracticeSessionScreen - Edge Cases', () {
    testWidgets('handles empty options fallback for singleChoice', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Question with no options provided',
          type: QuestionType.singleChoice,
          markschemeText: 'Option A',
          options: [],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
      expect(find.text('Option D'), findsOneWidget);
    });

    testWidgets('handles empty options fallback for multiChoice', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Multi with no options',
          type: QuestionType.multiChoice,
          markschemeText: 'Option A',
          options: [],
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('shows session results with score', (tester) async {
      final questions = [
        _question(
          id: 'q1',
          text: 'Correct answer',
          type: QuestionType.typedAnswer,
          markschemeText: 'correct',
        ),
        _question(
          id: 'q2',
          text: 'Wrong answer',
          type: QuestionType.typedAnswer,
          markschemeText: 'correct',
        ),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'correct');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Practice Complete!'), findsOneWidget);
      expect(find.textContaining('1/2'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('shows progress bar', (tester) async {
      final questions = [
        _question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
        _question(id: 'q2', text: 'Q2', type: QuestionType.typedAnswer, markschemeText: 'a'),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows timer and score stats', (tester) async {
      final questions = [
        _question(id: 'q1', text: 'Q1', type: QuestionType.typedAnswer, markschemeText: 'a'),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}