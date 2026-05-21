import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/presentation/widgets/mistake_review_widget.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

MistakeEntry _createMistake({
  String questionText = 'What is 2+2?',
  String userAnswer = '3',
  String correctAnswer = '4',
  String? explanation = '2+2 equals 4',
  bool hasAttempt = true,
}) {
  return MistakeEntry(
    question: Question(
      id: 'q1',
      text: questionText,
      type: QuestionType.typedAnswer,
      subjectId: 's1',
      topicId: 't1',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
    attempt: hasAttempt
        ? StudentAttempt(
            id: 'a1',
            studentId: 'stu1',
            questionId: 'q1',
            subjectId: 's1',
            userAnswer: userAnswer,
            timestamp: DateTime(2024),
          )
        : null,
    correctAnswer: correctAnswer,
    explanation: explanation,
  );
}

void main() {
  group('MistakeReviewWidget', () {
    testWidgets('shows empty state when no mistakes', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const MistakeReviewWidget(mistakes: []),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('No mistakes to review'), findsOneWidget);
    });

    testWidgets('shows mistake cards when mistakes are present', (tester) async {
      final mistakes = [
        _createMistake(questionText: 'What is 2+2?'),
        _createMistake(questionText: 'What is 3+3?', correctAnswer: '6'),
      ];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('What is 2+2?'), findsOneWidget);
      expect(find.text('What is 3+3?'), findsOneWidget);
    });

    testWidgets('shows redo button when mistakes are present', (tester) async {
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Redo Incorrect Questions'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('calls onRedo when redo button is tapped', (tester) async {
      bool redoCalled = false;
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(
          mistakes: mistakes,
          onRedo: () => redoCalled = true,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redo Incorrect Questions'));
      await tester.pumpAndSettle();
      expect(redoCalled, isTrue);
    });

    testWidgets('shows dismiss button when onDismiss is provided', (tester) async {
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(
          mistakes: mistakes,
          onDismiss: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('calls onDismiss when dismiss button is tapped', (tester) async {
      bool dismissCalled = false;
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(
          mistakes: mistakes,
          onDismiss: () => dismissCalled = true,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(dismissCalled, isTrue);
    });

    testWidgets('does not show dismiss button when onDismiss is null', (tester) async {
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss'), findsNothing);
    });

    testWidgets('shows user answer label', (tester) async {
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Your Answer'), findsOneWidget);
    });

    testWidgets('shows correct answer label', (tester) async {
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Correct Answer'), findsOneWidget);
    });

    testWidgets('shows user answer value', (tester) async {
      final mistakes = [_createMistake(userAnswer: '5')];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows no answer text when userAnswer is empty', (tester) async {
      final mistakes = [_createMistake(userAnswer: '', hasAttempt: true)];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No answer provided'), findsOneWidget);
    });

    testWidgets('shows no answer text when attempt is null', (tester) async {
      final mistakes = [_createMistake(hasAttempt: false)];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No answer provided'), findsOneWidget);
    });

    testWidgets('shows correct answer value', (tester) async {
      final mistakes = [_createMistake(correctAnswer: '42')];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows explanation when provided', (tester) async {
      final mistakes = [_createMistake(explanation: 'Adding 2 and 2 gives 4')];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Adding 2 and 2 gives 4'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    });

    testWidgets('does not show explanation section when explanation is null', (tester) async {
      final mistakes = [_createMistake(explanation: null)];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lightbulb), findsNothing);
    });

    testWidgets('shows title and description', (tester) async {
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        MistakeReviewWidget(mistakes: mistakes),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Review Mistakes'), findsOneWidget);
      expect(find.text('Review 1 mistakes from this session'), findsOneWidget);
    });

    testWidgets('static show displays bottom sheet with mistakes', (tester) async {
      bool redoCalled = false;
      final mistakes = [_createMistake(questionText: 'What is 2+2?')];
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              MistakeReviewWidget.show(
                context,
                mistakes: mistakes,
                onRedo: () => redoCalled = true,
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('What is 2+2?'), findsOneWidget);

      await tester.tap(find.text('Redo Incorrect Questions'));
      await tester.pumpAndSettle();
      expect(redoCalled, isTrue);
    });

    testWidgets('static show dismiss button works', (tester) async {
      bool dismissCalled = false;
      final mistakes = [_createMistake()];
      await tester.pumpWidget(_buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              MistakeReviewWidget.show(
                context,
                mistakes: mistakes,
                onDismiss: () => dismissCalled = true,
              );
            },
            child: const Text('Show Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(dismissCalled, isTrue);
    });
  });
}
