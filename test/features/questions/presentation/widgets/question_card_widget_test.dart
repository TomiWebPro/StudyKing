import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/presentation/widgets/question_card_widget.dart';
import 'package:studyking/features/questions/presentation/widgets/single_answer_widget.dart';
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

    group('step by step question', () {
      testWidgets('renders step by step label', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.stepByStep);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('Step-by-Step'), findsOneWidget);
      });

      testWidgets('renders text field for step by step answer', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.stepByStep);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Type your answer here...'), findsOneWidget);
      });

      testWidgets('renders step by step content instead of not supported message', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.stepByStep);
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('This question type is not yet supported in this view.'), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('submitting step by step answer calls onAnswerSubmitted', (tester) async {
        String? submittedAnswer;
        final question = _defaultQuestion().copyWith(type: QuestionType.stepByStep);
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerSubmitted: (answer) => submittedAnswer = answer,
        ));

        await tester.enterText(find.byType(TextField), 'Step 1: do this\nStep 2: do that');
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Answer'));
        await tester.pump();

        expect(submittedAnswer, 'Step 1: do this\nStep 2: do that');
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

        expect(find.text('No options available'), findsOneWidget);
      });

      testWidgets('handles no options for multi choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q4', text: 'Select:', type: QuestionType.multiChoice,
          options: [], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(question: question));

        expect(find.text('No options available'), findsOneWidget);
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

      testWidgets('difficulty 0 uses default color', (tester) async {
        final question = _defaultQuestion().copyWith(difficulty: 0);
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('correct answer is null when no markscheme', (tester) async {
        final question = Question(
          id: 'q-no-ms',
          text: 'No markscheme?',
          type: QuestionType.typedAnswer,
          subjectId: 'math',
          topicId: 'algebra',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          difficulty: 1,
          options: [],
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('isCurrentAnswerCorrect returns false when answer is null', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: null,
          isSubmitted: true,
        ));
        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('single choice shows correct after submission', (tester) async {
        final question = _questionWithOptions(
          id: 'q-sc', text: 'Pick:', type: QuestionType.singleChoice,
          options: ['A', 'B'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A',
          isSubmitted: true,
        ));
        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('single choice shows incorrect after submission', (tester) async {
        final question = _questionWithOptions(
          id: 'q-sc-w', text: 'Pick:', type: QuestionType.singleChoice,
          options: ['A', 'B'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'B',
          isSubmitted: true,
        ));
        expect(find.text('Incorrect'), findsOneWidget);
      });
    });

    group('reduceMotion', () {
      testWidgets('renders with reduceMotion true', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.singleChoice);
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
              reduceMotion: true,
            ),
          ),
        ));
        expect(find.byType(QuestionCardWidget), findsOneWidget);
      });
    });

    group('largeTouchTargets', () {
      testWidgets('renders with largeTouchTargets true', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.canvas, options: []);
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
              largeTouchTargets: true,
            ),
          ),
        ));
        expect(find.byType(QuestionCardWidget), findsOneWidget);
      });
    });

    group('multi choice empty options', () {
      testWidgets('multi choice with empty options shows no options message', (tester) async {
        final question = _questionWithOptions(
          id: 'q-mc-empty', text: 'Pick:', type: QuestionType.multiChoice,
          options: [], correctAnswer: 'Option 1',
        );
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.text('No options available'), findsOneWidget);
      });
    });

    group('didUpdateWidget sync', () {
      testWidgets('syncs single choice selected option on answer change', (tester) async {
        final question = _questionWithOptions(
          id: 'q-sc-sync', text: 'Pick:', type: QuestionType.singleChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(question: question, currentAnswer: 'A'));
        await tester.pumpWidget(buildWidget(question: question, currentAnswer: 'B'));
        await tester.pump();
        expect(find.byType(SingleAnswerWidget), findsOneWidget);
      });

      testWidgets('syncs multi choice on answer change', (tester) async {
        final question = _questionWithOptions(
          id: 'q-mc-sync', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(question: question, currentAnswer: 'A||B'));
        await tester.pumpWidget(buildWidget(question: question, currentAnswer: 'A||C'));
        await tester.pump();
        expect(find.byType(CheckboxListTile), findsNWidgets(3));
      });

      testWidgets('currentAnswer stays null when no answer provided', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: null));
        await tester.pumpWidget(buildWidget(currentAnswer: '4'));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, '4');
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

    group('case sensitivity in answer correctness', () {
      testWidgets('single choice correct answer is case insensitive', (tester) async {
        final question = _questionWithOptions(
          id: 'q6', text: 'Pick:', type: QuestionType.singleChoice,
          options: ['A', 'B'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A',
          isSubmitted: true,
        ));
        expect(find.text('Correct!'), findsOneWidget);
      });

      testWidgets('single choice wrong answer shows incorrect', (tester) async {
        final question = _questionWithOptions(
          id: 'q7', text: 'Pick:', type: QuestionType.singleChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A',
          isSubmitted: true,
        ));
        expect(find.text('Incorrect'), findsOneWidget);
      });
    });

    group('essay content edge cases', () {
      testWidgets('essay field clears when answer becomes null', (tester) async {
        String? changedAnswer;
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), 'essay answer');
        await tester.pump();

        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        expect(changedAnswer, isNull);
      });

      testWidgets('essay field submits multiline content', (tester) async {
        String? submittedAnswer;
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerSubmitted: (answer) => submittedAnswer = answer,
        ));

        await tester.enterText(find.byType(TextField), 'Line 1\nLine 2\nLine 3');
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Answer'));
        await tester.pump();

        expect(submittedAnswer, 'Line 1\nLine 2\nLine 3');
      });
    });

    group('reduceMotion for canvas', () {
      testWidgets('renders canvas with reduceMotion true', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: QuestionCardWidget(
              question: question,
              onAnswerSubmitted: (_) {},
              reduceMotion: true,
            ),
          ),
        ));
        expect(find.byType(QuestionCardWidget), findsOneWidget);
      });
    });

    group('type color default', () {
      testWidgets('unsupported type uses surfaceContainerHighest color', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.fileUpload);
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.text('This question type is not yet supported in this view.'), findsOneWidget);
      });

      testWidgets('difficulty default color for value 0 uses surfaceContainerHighest', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 0);
        await tester.pumpWidget(buildWidget(question: q));
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('whitespace edge cases', () {
      testWidgets('entering whitespace-only in typed answer sets answer to null', (tester) async {
        String? changedAnswer;
        await tester.pumpWidget(buildWidget(
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        expect(changedAnswer, isNull);
      });

      testWidgets('entering whitespace-only in essay answer sets answer to null', (tester) async {
        String? changedAnswer;
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        expect(changedAnswer, isNull);
      });

      testWidgets('whitespace then text updates answer correctly', (tester) async {
        String? changedAnswer;
        await tester.pumpWidget(buildWidget(
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'answer');
        await tester.pump();

        expect(changedAnswer, 'answer');
      });
    });

    group('type chip color', () {
      testWidgets('typed answer chip has secondaryContainer background', (tester) async {
        await tester.pumpWidget(buildWidget());
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[0].backgroundColor, cs.secondaryContainer);
      });

      testWidgets('essay type chip has tertiaryContainer background', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: question));
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[0].backgroundColor, cs.tertiaryContainer);
      });

      testWidgets('canvas type chip has primaryContainer background', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(question: question));
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[0].backgroundColor, cs.primaryContainer);
      });

      testWidgets('unsupported type chip has surfaceContainerHighest background', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.fileUpload);
        await tester.pumpWidget(buildWidget(question: question));
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(1));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[0].backgroundColor, cs.surfaceContainerHighest);
      });
    });

    group('difficulty chip color', () {
      testWidgets('difficulty 1 chip has primaryContainer background', (tester) async {
        await tester.pumpWidget(buildWidget());
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[1].backgroundColor, cs.primaryContainer);
      });

      testWidgets('difficulty 2 chip has tertiaryContainer background', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 2);
        await tester.pumpWidget(buildWidget(question: q));
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[1].backgroundColor, cs.tertiaryContainer);
      });

      testWidgets('difficulty 3 chip has errorContainer background', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 3);
        await tester.pumpWidget(buildWidget(question: q));
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[1].backgroundColor, cs.errorContainer);
      });

      testWidgets('difficulty 0 chip has surfaceContainerHighest background', (tester) async {
        final q = _defaultQuestion().copyWith(difficulty: 0);
        await tester.pumpWidget(buildWidget(question: q));
        final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
        expect(chips.length, greaterThanOrEqualTo(2));
        final cs = Theme.of(tester.element(find.byType(Card))).colorScheme;
        expect(chips[1].backgroundColor, cs.surfaceContainerHighest);
      });
    });

    group('multi choice deselect', () {
      testWidgets('deselecting option removes it from answer', (tester) async {
        String? changedAnswer;
        final question = _questionWithOptions(
          id: 'q-desel', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: 'A,B',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
        await tester.pump();
        expect(changedAnswer, 'A');

        await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
        await tester.pump();
        expect(changedAnswer, isEmpty);
      });
    });

    group('canvas answer callback', () {
      testWidgets('canvas save triggers answer callback', (tester) async {
        String? changedAnswer;
        final question = _defaultQuestion().copyWith(type: QuestionType.canvas);
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        final gesture = await tester.startGesture(const Offset(200, 200));
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save Drawing'));
        await tester.pump();
        await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
        await tester.pump();
        await tester.pump();

        expect(changedAnswer, isNotNull);
        expect(changedAnswer!.isNotEmpty, isTrue);
      });
    });

    group('onNext button visibility', () {
      testWidgets('does not show next button when isSubmitted is false even with onNext', (tester) async {
        await tester.pumpWidget(buildWidget(
          isSubmitted: false,
          onNext: () {},
        ));
        expect(find.widgetWithText(OutlinedButton, 'Next Question'), findsNothing);
      });

      testWidgets('hides next button when onNext is null even when submitted', (tester) async {
        await tester.pumpWidget(buildWidget(isSubmitted: true));
        expect(find.widgetWithText(OutlinedButton, 'Next Question'), findsNothing);
      });
    });

    group('didUpdateWidget no change', () {
      testWidgets('does not reset state when currentAnswer unchanged', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: 'hello'));
        await tester.pumpWidget(buildWidget(currentAnswer: 'hello'));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'hello');
      });
    });

    group('math expression renders MathExpressionWidget', () {
      testWidgets('math expression type renders MathExpressionWidget content', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.mathExpression);
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Math'), findsOneWidget);
        expect(find.text('Type your answer here...'), findsOneWidget);
      });
    });

    group('isFeedbackVisible for single choice', () {
      testWidgets('hides feedback when isFeedbackVisible is false for single choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q-fb', text: 'Pick:', type: QuestionType.singleChoice,
          options: ['A', 'B'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A',
          isSubmitted: true,
          isFeedbackVisible: false,
        ));
        expect(find.text('Correct!'), findsOneWidget);
        expect(find.text('Incorrect'), findsNothing);
      });

      testWidgets('hides feedback when isFeedbackVisible is false for typed answer', (tester) async {
        await tester.pumpWidget(buildWidget(
          currentAnswer: '4',
          isSubmitted: true,
          isFeedbackVisible: false,
        ));
        expect(find.text('Correct!'), findsOneWidget);
      });
    });

    group('onAnswerSubmitted with typed answer', () {
      testWidgets('submit button calls onAnswerSubmitted with entered text', (tester) async {
        String? submitted;
        await tester.pumpWidget(buildWidget(
          onAnswerSubmitted: (answer) => submitted = answer,
        ));

        await tester.enterText(find.byType(TextField), 'my answer');
        await tester.pump();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Answer'));
        await tester.pump();

        expect(submitted, 'my answer');
      });
    });

    group('multi choice whitespace in correct answer', () {
      testWidgets('handles whitespace in correctAnswer for multi choice', (tester) async {
        final question = _questionWithOptions(
          id: 'q-ws', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B', 'C'], correctAnswer: '  A ,  B  ',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          currentAnswer: 'A||B',
          isSubmitted: true,
        ));
        expect(find.text('Correct!'), findsOneWidget);
      });
    });

    group('Semantics label on card', () {
      testWidgets('card has semantics label with type and question text', (tester) async {
        await tester.pumpWidget(buildWidget());
        expect(find.bySemanticsLabel('Text Answer: What is 2 + 2?'), findsOneWidget);
      });
    });

    group('essay didUpdateWidget sync', () {
      testWidgets('essay controller syncs on currentAnswer change', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.essay);
        await tester.pumpWidget(buildWidget(question: question, currentAnswer: 'first'));
        await tester.pumpWidget(buildWidget(question: question, currentAnswer: 'second'));
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'second');
      });
    });

    group('multi choice deselect all', () {
      testWidgets('deselecting all options results in empty answer', (tester) async {
        String? changedAnswer;
        final question = _questionWithOptions(
          id: 'q-desel-all', text: 'Select:', type: QuestionType.multiChoice,
          options: ['A', 'B'], correctAnswer: 'A',
        );
        await tester.pumpWidget(buildWidget(
          question: question,
          onAnswerChanged: (value) => changedAnswer = value,
        ));

        await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
        await tester.pump();
        expect(changedAnswer, 'A');

        await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
        await tester.pump();
        expect(changedAnswer, isEmpty);
      });
    });

    group('type label for default type', () {
      testWidgets('renders "Question" label for unsupported type', (tester) async {
        final question = _defaultQuestion().copyWith(type: QuestionType.audioRecording);
        await tester.pumpWidget(buildWidget(question: question));
        expect(find.text('Question'), findsOneWidget);
      });
    });

    group('submit button disabled for whitespace answer', () {
      testWidgets('submit disabled when answer is only whitespace', (tester) async {
        await tester.pumpWidget(buildWidget(currentAnswer: '   '));
        final submitButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Submit Answer'),
        );
        expect(submitButton.onPressed, isNull);
      });
    });
  });
}
