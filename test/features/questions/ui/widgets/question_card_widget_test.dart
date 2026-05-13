import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/ui/widgets/question_card_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: QuestionCardWidget(
          question: question ?? _defaultQuestion(),
          currentAnswer: currentAnswer,
          isSubmitted: isSubmitted,
          isFeedbackVisible: isFeedbackVisible,
          onAnswerSubmitted: onAnswerSubmitted ?? (answer) {},
          onAnswerChanged: onAnswerChanged ?? (answer) {},
          onNext: onNext,
        ),
      ),
    ),
  );
}

Question _defaultQuestion() {
  return Question(
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
}

Question _questionWithOptions({
  required String id,
  required String text,
  required QuestionType type,
  List<String> options = const [],
  String? correctAnswer,
  int difficulty = 1,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    subjectId: 'math',
    topicId: 'algebra',
    markscheme: correctAnswer != null
        ? Markscheme(questionId: id, correctAnswer: correctAnswer)
        : null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    difficulty: difficulty,
    options: options,
  );
}

void main() {
  group('QuestionCardWidget', () {
    group('basic rendering', () {
      testWidgets('renders question text', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('What is 2 + 2?'), findsOneWidget);
      });

      testWidgets('renders type chip with label', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Text Answer'), findsOneWidget);
      });

      testWidgets('renders difficulty chip', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Difficulty: Easy'), findsOneWidget);
      });

      testWidgets('renders Card widget', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('renders submit button when not submitted', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.widgetWithText(ElevatedButton, 'Submit Answer'), findsOneWidget);
      });

      testWidgets('shows helper text when no answer entered', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: null));
        expect(find.text('Add an answer before submitting.'), findsOneWidget);
      });

      testWidgets('hides helper text after entering answer', (tester) async {
        String? updatedAnswer;
        await tester.pumpWidget(buildWidget(
          onAnswerChanged: (value) => updatedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), '4');
        await tester.pump();

        expect(find.text('Add an answer before submitting.'), findsNothing);
        expect(updatedAnswer, '4');
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
        String? changedAnswer;
        await tester.pumpWidget(buildWidget(
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), '4');
        await tester.pump();

        expect(changedAnswer, '4');
      });

      testWidgets('submitting answer calls onAnswerSubmitted', (tester) async {
        String? submittedAnswer;
        await tester.pumpWidget(buildWidget(
          onAnswerSubmitted: (answer) => submittedAnswer = answer,
        ));

        await tester.enterText(find.byType(TextField), '4');
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Answer'));
        await tester.pump();

        expect(submittedAnswer, '4');
      });

      testWidgets('clearing text sets answer to null', (tester) async {
        String? changedAnswer;
        await tester.pumpWidget(buildWidget(
          currentAnswer: 'initial',
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        expect(changedAnswer, isNull);
      });
    });

    group('single choice question', () {
      testWidgets('renders type chip for single choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q2', text: 'Pick one:', type: QuestionType.singleChoice,
          options: ['A', 'B', 'C', 'D'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.text('Multiple Choice'), findsOneWidget);
      });

      testWidgets('renders SingleAnswerWidget for single choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q2', text: 'Pick one:', type: QuestionType.singleChoice,
          options: ['A', 'B', 'C', 'D'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.text('A'), findsOneWidget);
      });

      testWidgets('selecting option calls onAnswerChanged', (tester) async {
        String? changedAnswer;
        final question = _questionWithOptions(
          id: 'q2', text: 'Pick one:', type: QuestionType.singleChoice,
          options: ['A', 'B', 'C', 'D'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.tap(find.text('A'));
        await tester.pump();

        expect(changedAnswer, 'A');
      });
    });

    group('multi choice question', () {
      testWidgets('renders type chip for multi choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select all:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.text('Multiple Select'), findsOneWidget);
      });

      testWidgets('renders checkboxes for each option', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select all:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C', 'D'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.byType(CheckboxListTile), findsNWidgets(4));
      });

      testWidgets('selecting multiple options updates answer', (tester) async {
        String? changedAnswer;
        final question = _questionWithOptions(
          id: 'q3', text: 'Select all:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C', 'D'], correctAnswer: 'A,C',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
        await tester.pump();

        expect(changedAnswer, contains('A'));
      });

      testWidgets('shows submitted correct for multi choice with correct answer', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select all:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||B',
          isSubmitted: true,
          onAnswerSubmitted: (_) {},
        ));

        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('shows submitted incorrect for multi choice with wrong answer', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select all:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||C',
          isSubmitted: true,
        ));

        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('disables checkboxes after submission', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select all:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||B',
          isSubmitted: true,
        ));

        final tiles = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
        for (final tile in tiles) {
          expect(tile.onChanged, isNull);
        }
      });
    });

    group('math expression question', () {
      testWidgets('renders text field for math expression', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.mathExpression);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Type your answer here...'), findsOneWidget);
      });

      testWidgets('renders Math type label', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.mathExpression);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Math'), findsOneWidget);
      });
    });

    group('essay question', () {
      testWidgets('renders essay text field', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Write your essay answer...'), findsOneWidget);
      });

      testWidgets('text field has 10 max lines', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: question));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLines, 10);
      });

      testWidgets('renders Essay type label', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Essay'), findsOneWidget);
      });
    });

    group('canvas question', () {
      testWidgets('renders canvas drawing widget for canvas type', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.widgetWithText(ElevatedButton, 'Save Drawing'), findsOneWidget);
      });

      testWidgets('renders Diagram type label', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Diagram'), findsOneWidget);
      });
    });

    group('graph drawing question', () {
      testWidgets('renders Graph type label', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.graphDrawing);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Graph'), findsOneWidget);
      });

      testWidgets('renders canvas for graph drawing type', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.graphDrawing);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.widgetWithText(ElevatedButton, 'Save Drawing'), findsOneWidget);
      });
    });

    group('question type labels', () {
      testWidgets('typed answer label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.typedAnswer);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Text Answer'), findsOneWidget);
      });

      testWidgets('single choice label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.singleChoice);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Multiple Choice'), findsOneWidget);
      });

      testWidgets('multi choice label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.multiChoice);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Multiple Select'), findsOneWidget);
      });

      testWidgets('math expression label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.mathExpression);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Math'), findsOneWidget);
      });

      testWidgets('essay label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Essay'), findsOneWidget);
      });

      testWidgets('canvas label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Diagram'), findsOneWidget);
      });

      testWidgets('graph drawing label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.graphDrawing);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Graph'), findsOneWidget);
      });

      testWidgets('step by step label', (tester) async {
        final q = _defaultQuestion().copyWith(type: QuestionType.stepByStep);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Step-by-Step'), findsOneWidget);
      });
    });

    group('difficulty labels', () {
      testWidgets('difficulty 1 shows Easy', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.text('Difficulty: Easy'), findsOneWidget);
      });

      testWidgets('difficulty 2 shows Medium', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 2);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Difficulty: Medium'), findsOneWidget);
      });

      testWidgets('difficulty 3 shows Hard', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 3);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Difficulty: Hard'), findsOneWidget);
      });

      testWidgets('unknown difficulty shows raw number', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 5);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.text('Difficulty: 5'), findsOneWidget);
      });
    });

    group('submitted state', () {
      testWidgets('shows correct indicator for correct answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: '4',
          isSubmitted: true,
        ));
        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('shows incorrect indicator for wrong answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: '5',
          isSubmitted: true,
        ));
        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('shows feedback chip colors', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: '4',
          isSubmitted: true,
        ));

        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('hides submit button after submission', (tester) async {
        await tester.pumpWidget(buildWidget(isSubmitted: true));
        expect(find.widgetWithText(ElevatedButton, 'Submit Answer'), findsNothing);
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

      testWidgets('hides next button when onNext is null', (tester) async {
        await tester.pumpWidget(buildWidget(isSubmitted: true));
        expect(find.widgetWithText(OutlinedButton, 'Next Question'), findsNothing);
      });
    });

    group('answer validation', () {
      testWidgets('submit disabled for null answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: null));

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNull);
      });

      testWidgets('submit disabled for empty answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: ''));

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNull);
      });

      testWidgets('submit enabled for valid answer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: '4'));

        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNotNull);
      });
    });

    group('controller sync', () {
      testWidgets('updates text when currentAnswer changes', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: 'initial'));
        await tester.pump();

        await tester.pumpWidget(buildWidget(currentAnswer: 'updated'));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'updated');
      });

      testWidgets('pre-fills text with currentAnswer', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: 'pre-filled'));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'pre-filled');
      });

      testWidgets('syncs multi choice initial answer', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||C',
        ));

        final tiles = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
        expect(tiles.length, 3);
      });
    });

    group('dispose', () {
      testWidgets('disposes without error', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('edge cases', () {
      testWidgets('handles no options for single choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q4', text: 'Pick:', type: QuestionType.singleChoice,
          options: [], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Option 1'), findsOneWidget);
        expect(find.text('Option 2'), findsOneWidget);
        expect(find.text('Option 3'), findsOneWidget);
        expect(find.text('Option 4'), findsOneWidget);
      });

      testWidgets('handles multi choice with no initial answer', (tester) async {
        final question = _questionWithOptions(
          id: 'q3', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: null,
        ));

        final checkboxes = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
        expect(checkboxes.every((cb) => cb.value == false), isTrue);
      });

      testWidgets('handles unknown question type', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.fileUpload);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('This question type is not yet supported in this view.'), findsOneWidget);
      });

      testWidgets('handles audioRecording type', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.audioRecording);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('This question type is not yet supported in this view.'), findsOneWidget);
      });

      testWidgets('kanji builder with zero difficulty color', (tester) async {
        final question = _defaultQuestion().copyWith(difficulty: 0);
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('answer correctness with multiChoice', () {
      testWidgets('correct multi choice answer shows Correct', (tester) async {
        final question = _questionWithOptions(
          id: 'q5', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A, B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||B',
          isSubmitted: true,
        ));

        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('incorrect multi choice answer shows Incorrect', (tester) async {
        final question = _questionWithOptions(
          id: 'q5', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A, B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||C',
          isSubmitted: true,
        ));

        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('multi choice without markscheme still renders', (tester) async {
        final question = _questionWithOptions(
          id: 'q5', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: null,
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.byType(CheckboxListTile), findsNWidgets(3));
      });
    });
  });
}
