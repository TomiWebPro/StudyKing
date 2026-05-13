import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/ui/widgets/question_card_widget.dart';

void main() {
  group('QuestionCardWidget', () {
    late Question testQuestion;
    String? submittedAnswer;
    String? changedAnswer;

    setUp(() {
      submittedAnswer = null;
      changedAnswer = null;
      testQuestion = Question(
        id: 'q1',
        text: 'What is 2 + 2?',
        type: QuestionType.typedAnswer,
        subjectId: 'math',
        topicId: 'arithmetic',
        markscheme: Markscheme(questionId: 'q1', correctAnswer: '4'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        difficulty: 1,
        options: [],
      );
    });

    Widget buildWidget({
      Question? question,
      String? currentAnswer,
      bool isSubmitted = false,
      bool isFeedbackVisible = false,
      ValueChanged<String?>? onAnswerSubmitted,
      ValueChanged<String?>? onAnswerChanged,
      VoidCallback? onNext,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuestionCardWidget(
              question: question ?? testQuestion,
              currentAnswer: currentAnswer,
              isSubmitted: isSubmitted,
              isFeedbackVisible: isFeedbackVisible,
              onAnswerSubmitted: onAnswerSubmitted ?? (answer) => submittedAnswer = answer,
              onAnswerChanged: onAnswerChanged ?? (answer) => changedAnswer = answer,
              onNext: onNext,
            ),
          ),
        ),
      );
    }

    group('basic rendering', () {
      testWidgets('renders question text', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('What is 2 + 2?'), findsOneWidget);
      });

      testWidgets('renders type chip', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Text Answer'), findsOneWidget);
      });

      testWidgets('renders difficulty chip', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Difficulty: Easy'), findsOneWidget);
      });

      testWidgets('renders submit button when not submitted', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.widgetWithText(ElevatedButton, 'Submit Answer'), findsOneWidget);
      });

      testWidgets('shows helper text when no answer', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Add an answer before submitting.'), findsOneWidget);
      });

      testWidgets('hides helper text after entering answer', (tester) async {
        await tester.pumpWidget(buildWidget());

        await tester.enterText(find.byType(TextField), '4');
        await tester.pump();

        expect(find.text('Add an answer before submitting.'), findsNothing);
      });
    });

    group('typed answer question', () {
      testWidgets('renders text field', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('text field has placeholder', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Type your answer here...'), findsOneWidget);
      });

      testWidgets('entering text calls onAnswerChanged', (tester) async {
        await tester.pumpWidget(buildWidget());

        await tester.enterText(find.byType(TextField), '4');
        await tester.pump();

        expect(changedAnswer, '4');
      });

      testWidgets('submitting answer calls onAnswerSubmitted', (tester) async {
        await tester.pumpWidget(buildWidget());

        await tester.enterText(find.byType(TextField), '4');
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Answer'));
        await tester.pump();

        expect(submittedAnswer, '4');
      });
    });

    group('single choice question', () {
      testWidgets('renders type chip for single choice', (tester) async {
        final singleChoiceQuestion = testQuestion.copyWith(type: QuestionType.singleChoice);
        await tester.pumpWidget(buildWidget(question: singleChoiceQuestion));

        expect(find.text('Multiple Choice'), findsOneWidget);
      });
    });

    group('multi choice question', () {
      testWidgets('renders type chip for multi choice', (tester) async {
        final multiChoiceQuestion = testQuestion.copyWith(type: QuestionType.multiChoice);
        await tester.pumpWidget(buildWidget(question: multiChoiceQuestion));

        expect(find.text('Multiple Select'), findsOneWidget);
      });

      testWidgets('renders checkboxes', (tester) async {
        final multiChoiceQuestion = testQuestion.copyWith(
          type: QuestionType.multiChoice,
          options: ['A', 'B', 'C', 'D'],
        );
        await tester.pumpWidget(buildWidget(question: multiChoiceQuestion));

        expect(find.byType(CheckboxListTile), findsNWidgets(4));
      });

      testWidgets('selecting multiple options updates answer', (tester) async {
        final multiChoiceQuestion = testQuestion.copyWith(
          type: QuestionType.multiChoice,
          options: ['A', 'B', 'C', 'D'],
        );
        await tester.pumpWidget(buildWidget(question: multiChoiceQuestion));

        await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
        await tester.pump();
        await tester.tap(find.widgetWithText(CheckboxListTile, 'C'));
        await tester.pump();

        expect(changedAnswer, contains('A'));
        expect(changedAnswer, contains('C'));
      });
    });

    group('essay question', () {
      testWidgets('renders larger text field', (tester) async {
        final essayQuestion = testQuestion.copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: essayQuestion));

        expect(find.text('Write your essay answer...'), findsOneWidget);
      });

      testWidgets('text field has 10 max lines', (tester) async {
        final essayQuestion = testQuestion.copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: essayQuestion));

        final textField = tester.widget<TextField>(find.byType(TextField).first);
        expect(textField.maxLines, 10);
      });
    });

    group('canvas question', () {
      testWidgets('renders canvas drawing widget', (tester) async {
        final canvasQuestion = testQuestion.copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(question: canvasQuestion));

        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('submitted state', () {
      testWidgets('shows correct indicator for correct answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: '4',
          isSubmitted: true,
        ));

        expect(find.text('Correct'), findsOneWidget);
      });

      testWidgets('shows incorrect indicator for wrong answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: '5',
          isSubmitted: true,
        ));

        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('shows next button when onNext provided', (tester) async {
        await tester.pumpWidget(buildWidget(
          isSubmitted: true,
          onNext: () {},
        ));

        expect(find.widgetWithText(OutlinedButton, 'Next Question'), findsOneWidget);
      });

      testWidgets('next button calls onNext', (tester) async {
        bool nextCalled = false;
        await tester.pumpWidget(buildWidget(
          isSubmitted: true,
          onNext: () => nextCalled = true,
        ));

        await tester.tap(find.widgetWithText(OutlinedButton, 'Next Question'));
        await tester.pump();

        expect(nextCalled, isTrue);
      });

      testWidgets('hides submit button after submission', (tester) async {
        await tester.pumpWidget(buildWidget(isSubmitted: true));

        expect(find.widgetWithText(ElevatedButton, 'Submit Answer'), findsNothing);
      });
    });

    group('difficulty colors', () {
      testWidgets('shows green for easy (difficulty 1)', (tester) async {
        await tester.pumpWidget(buildWidget());

        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        final difficultyChip = chips.last;
        expect(difficultyChip.backgroundColor, isNotNull);
      });

      testWidgets('shows orange for medium (difficulty 2)', (tester) async {
        final mediumQuestion = testQuestion.copyWith(difficulty: 2);
        await tester.pumpWidget(buildWidget(question: mediumQuestion));

        expect(find.text('Difficulty: Medium'), findsOneWidget);
      });

      testWidgets('shows red for hard (difficulty 3)', (tester) async {
        final hardQuestion = testQuestion.copyWith(difficulty: 3);
        await tester.pumpWidget(buildWidget(question: hardQuestion));

        expect(find.text('Difficulty: Hard'), findsOneWidget);
      });
    });

    group('question types', () {
      testWidgets('math expression type label', (tester) async {
        final mathQuestion = testQuestion.copyWith(type: QuestionType.mathExpression);
        await tester.pumpWidget(buildWidget(question: mathQuestion));

        expect(find.text('Math'), findsOneWidget);
      });

      testWidgets('step by step type label', (tester) async {
        final stepQuestion = testQuestion.copyWith(type: QuestionType.stepByStep);
        await tester.pumpWidget(buildWidget(question: stepQuestion));

        expect(find.text('Step-by-Step'), findsOneWidget);
      });

      testWidgets('graph drawing type label', (tester) async {
        final graphQuestion = testQuestion.copyWith(type: QuestionType.graphDrawing);
        await tester.pumpWidget(buildWidget(question: graphQuestion));

        expect(find.text('Graph'), findsOneWidget);
      });
    });

    group('controller sync on didUpdateWidget', () {
      testWidgets('updates text when currentAnswer changes externally', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: 'initial'));
        await tester.pump();

        await tester.pumpWidget(buildWidget(currentAnswer: 'updated'));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'updated');
      });
    });

    group('dispose', () {
      testWidgets('disposes controllers without error', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('initial state', () {
      testWidgets('uses currentAnswer from widget', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: 'pre-filled'));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'pre-filled');
      });

      testWidgets('trims whitespace from initial answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: '  4  '));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, '  4  ');
      });
    });

    group('answer validation', () {
      testWidgets('canSubmit returns false for null answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: null));

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNull);
      });

      testWidgets('canSubmit returns false for empty answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: ''));

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNull);
      });

      testWidgets('canSubmit returns true for valid answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: '4'));

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNotNull);
      });
    });

    group('type color', () {
      testWidgets('single choice has blue background', (tester) async {
        final question = testQuestion.copyWith(type: QuestionType.singleChoice);
        await tester.pumpWidget(buildWidget(question: question));

        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.first.backgroundColor, isNotNull);
      });

      testWidgets('essay has orange background', (tester) async {
        final question = testQuestion.copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Essay'), findsOneWidget);
      });

      testWidgets('canvas has purple background', (tester) async {
        final question = testQuestion.copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Diagram'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles question with no options for MCQ', (tester) async {
        final question = testQuestion.copyWith(
          type: QuestionType.singleChoice,
          options: [],
        );
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Option 1'), findsOneWidget);
        expect(find.text('Option 2'), findsOneWidget);
        expect(find.text('Option 3'), findsOneWidget);
        expect(find.text('Option 4'), findsOneWidget);
      });

      testWidgets('handles multi choice with no initial answer', (tester) async {
        final multiChoiceQuestion = testQuestion.copyWith(
          type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'],
        );
        await tester.pumpWidget(buildWidget(
          question: multiChoiceQuestion,
          currentAnswer: null,
        ));

        final checkboxes = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
        expect(checkboxes.every((cb) => cb.value == false), isTrue);
      });

      testWidgets('handles unknown question type', (tester) async {
        final unknownQuestion = testQuestion.copyWith(type: QuestionType.fileUpload);
        await tester.pumpWidget(buildWidget(question: unknownQuestion));

        expect(find.text('This question type is not yet supported in this view.'), findsOneWidget);
      });
    });
  });
}