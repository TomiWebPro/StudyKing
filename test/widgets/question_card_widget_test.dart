import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/questions/models/markscheme_model.dart';
import 'package:studyking/features/questions/ui/widgets/question_card_widget.dart';

Question _question({
  required String id,
  required String text,
  required QuestionType type,
  String? markschemeText,
  List<String> options = const [],
  int difficulty = 1,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    subjectId: 'subject-a',
    topicId: 'topic-a',
    markscheme: markschemeText != null ? Markscheme(questionId: id, correctAnswer: markschemeText) : null,
    options: options,
    difficulty: difficulty,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('QuestionCardWidget', () {
    testWidgets('renders question text and type label', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'What is the capital of France?',
        type: QuestionType.singleChoice,
        markschemeText: 'Paris',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('What is the capital of France?'), findsOneWidget);
      expect(find.text('Multiple Choice'), findsOneWidget);
    });

    testWidgets('submit button is disabled when no answer provided', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test question?',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button is disabled initially for typed answer', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Add an answer before submitting.'), findsOneWidget);
    });

    testWidgets('submit button is enabled when answer is provided', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'my answer',
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('Add an answer before submitting.'), findsNothing);
    });

    testWidgets('calls onAnswerSubmitted when submit button is pressed', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      );

      String? submittedAnswer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'my answer',
              onAnswerSubmitted: (answer) {
                submittedAnswer = answer;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit Answer'));
      await tester.pump();

      expect(submittedAnswer, 'my answer');
    });

    testWidgets('shows correctness chip after submission', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        markschemeText: 'A',
        options: ['A', 'B', 'C', 'D'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'A',
              isSubmitted: true,
              isFeedbackVisible: true,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Correct'), findsOneWidget);
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('shows Incorrect chip for wrong answer after submission', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        markschemeText: 'A',
        options: ['A', 'B', 'C', 'D'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'B',
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit Answer'));
      await tester.pump();

      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('shows next button after submission when onNext is provided', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      );

      bool nextPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'answer',
              isSubmitted: true,
              onAnswerSubmitted: (_) {},
              onNext: () {
                nextPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Next Question'), findsOneWidget);

      await tester.tap(find.text('Next Question'));
      await tester.pump();

      expect(nextPressed, isTrue);
    });

    testWidgets('updates local answer when currentAnswer changes via didUpdateWidget', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'initial',
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      final initialTextField = tester.widget<TextField>(find.byType(TextField));
      expect(initialTextField.controller?.text, 'initial');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'updated answer',
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      final updatedTextField = tester.widget<TextField>(find.byType(TextField));
      expect(updatedTextField.controller?.text, 'updated answer');
    });

    testWidgets('multi-choice answer serialization with || separator', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Select all that apply:',
        type: QuestionType.multiChoice,
        markschemeText: 'A,B',
        options: ['A', 'B', 'C', 'D'],
      );

      String? lastAnswer;
      // Verify checkbox tiles render correctly
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'A||B',
              onAnswerSubmitted: (_) {},
              onAnswerChanged: (answer) {
                lastAnswer = answer;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsNothing);

      expect(find.byType(CheckboxListTile), findsNWidgets(4));
      // Verify the initial state - answer hasn't changed from current
      expect(lastAnswer, equals('A||B'));
    });

    testWidgets('multi-choice parses || separated answer correctly', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Select:',
        type: QuestionType.multiChoice,
        markschemeText: 'Option A,Option B',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              currentAnswer: 'Option A||Option C',
              isSubmitted: true,
              isFeedbackVisible: true,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('shows fallback for unsupported question types', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.stepByStep,
        markschemeText: 'step',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('not yet supported'), findsOneWidget);
    });

    testWidgets('shows difficulty label', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Hard question',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
        difficulty: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Difficulty: Hard'), findsOneWidget);
    });

    testWidgets('shows Easy difficulty for difficulty 1', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Easy question',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
        difficulty: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Difficulty: Easy'), findsOneWidget);
    });

    testWidgets('shows Medium difficulty for difficulty 2', (tester) async {
      final question = _question(
        id: 'q1',
        text: 'Medium question',
        type: QuestionType.typedAnswer,
        markschemeText: 'answer',
        difficulty: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Difficulty: Medium'), findsOneWidget);
    });
  });
}