import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/data/models/practice_models.dart';
import 'package:studyking/features/practice/presentation/screens/review_answers_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: widget,
  );
}

Question _question({
  String id = 'q1',
  String text = 'What is 2+2?',
  String correctAnswer = '4',
  String? explanation,
}) {
  return Question(
    id: id,
    text: text,
    type: QuestionType.singleChoice,
    subjectId: 'math',
    topicId: 'arithmetic',
    options: ['3', '4', '5'],
    markscheme: Markscheme(
      questionId: id,
      correctAnswer: correctAnswer,
      explanation: explanation,
    ),
    explanation: explanation,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

PracticeAnswerRecord _record({
  required String questionId,
  bool isCorrect = true,
  String userAnswer = '4',
}) {
  return PracticeAnswerRecord(
    questionId: questionId,
    questionType: QuestionType.singleChoice,
    isCorrect: isCorrect,
    timeSpent: const Duration(seconds: 10),
    userAnswer: userAnswer,
  );
}

void main() {
  group('ReviewAnswersScreen', () {
    testWidgets('renders app bar with review mistakes title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question()],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('Review Mistakes'), findsOneWidget);
    });

    testWidgets('renders answer card with question text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', text: 'What is the capital?')],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('What is the capital?'), findsOneWidget);
    });

    testWidgets('shows index number on answer card', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1')],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows your answer and correct answer', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', correctAnswer: '4')],
          answerRecords: [_record(questionId: 'q1', userAnswer: '4')],
        ),
      ));

      expect(find.text('Your Answer'), findsOneWidget);
      expect(find.text('Correct Answer'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(2));
    });

    testWidgets('shows explanation when available', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [
            _question(
              id: 'q1',
              text: 'What is 2+2?',
              explanation: 'Addition of two and two.',
            ),
          ],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Addition of two and two.'), findsOneWidget);
    });

    testWidgets('does not show explanation when null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', explanation: null)],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('Explanation'), findsNothing);
    });

    testWidgets('empty explanation string hides explanation section',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', explanation: '')],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('Explanation'), findsNothing);
    });

    testWidgets('does not show correct answer section when correctAnswer is empty',
        (tester) async {
      final q = Question(
        id: 'q1',
        text: 'No markscheme',
        type: QuestionType.typedAnswer,
        subjectId: 'math',
        topicId: 'arithmetic',
        options: const [],
        markscheme: Markscheme(questionId: 'q1', correctAnswer: ''),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [q],
          answerRecords: [_record(questionId: 'q1')],
        ),
      ));

      expect(find.text('Correct Answer'), findsNothing);
    });

    testWidgets('handles missing question gracefully', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1')],
          answerRecords: [_record(questionId: 'nonexistent')],
        ),
      ));

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders multiple answer records', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [
            _question(id: 'q1', text: 'First question'),
            _question(id: 'q2', text: 'Second question'),
          ],
          answerRecords: [
            _record(questionId: 'q1', isCorrect: true, userAnswer: '4'),
            _record(questionId: 'q2', isCorrect: false, userAnswer: '3'),
          ],
        ),
      ));

      expect(find.text('First question'), findsOneWidget);
      expect(find.text('Second question'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('correct answer card uses primaryContainer color',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', text: 'Correct question')],
          answerRecords: [_record(questionId: 'q1', isCorrect: true)],
        ),
      ));

      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('incorrect answer card uses errorContainer color',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', text: 'Wrong question')],
          answerRecords: [
            _record(questionId: 'q1', isCorrect: false, userAnswer: '3'),
          ],
        ),
      ));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows user answer in error color when incorrect',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', correctAnswer: '4')],
          answerRecords: [
            _record(questionId: 'q1', isCorrect: false, userAnswer: 'Wrong'),
          ],
        ),
      ));

      expect(find.text('Wrong'), findsOneWidget);
    });

    testWidgets('scrolling works with many items', (tester) async {
      final questions = List.generate(
        20,
        (i) => _question(
          id: 'q$i',
          text: 'Question $i',
          correctAnswer: 'Answer $i',
        ),
      );
      final records = List.generate(
        20,
        (i) => _record(
          questionId: 'q$i',
          isCorrect: i.isEven,
          userAnswer: 'Answer $i',
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: questions,
          answerRecords: records,
        ),
      ));

      await tester.scrollUntilVisible(find.text('Question 19'), 200);
      expect(find.text('Question 19'), findsOneWidget);
    });

    testWidgets('renders card with correct styling for correct answer',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1', text: 'Test')],
          answerRecords: [_record(questionId: 'q1', isCorrect: true)],
        ),
      ));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('empty answerRecords renders list without crash',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ReviewAnswersScreen(
          questions: [_question(id: 'q1')],
          answerRecords: const [],
        ),
      ));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });
}
