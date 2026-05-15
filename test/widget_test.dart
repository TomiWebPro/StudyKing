import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
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
}) {
  final now = DateTime.utc(2024, 1, 1);
  return Question(
    id: id,
    text: text,
    type: type,
    subjectId: 'subject-a',
    topicId: 'topic-a',
    markscheme: Markscheme(questionId: id, correctAnswer: markschemeText),
    options: options,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _testApp({required Result<List<Question>> result}) {
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
                  builder: (_) => PracticeSessionScreen(args: const PracticeSessionArgs(subjectId: 'subject-a')),
                ),
              ),
              child: const Text('Start Practice'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Practice flow: loads questions, answer, submit, see feedback', (tester) async {
    final questions = [
      _question(
        id: 'q1',
        text: 'Capital of France?',
        type: QuestionType.singleChoice,
        markschemeText: 'Paris',
        options: ['London', 'Paris', 'Berlin', 'Madrid'],
      ),
    ];

    await tester.pumpWidget(_testApp(result: Result.success(questions)));
    await tester.tap(find.text('Start Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Capital of France?'), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);

    await tester.tap(find.text('Paris'));
    await tester.pump();

    await tester.tap(find.text('Submit Answer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('Practice session loads typedAnswer question and validates answer', (tester) async {
    final questions = [
      _question(id: 'q1', text: 'What is 2+2?', type: QuestionType.typedAnswer, markschemeText: '4'),
    ];

    await tester.pumpWidget(_testApp(result: Result.success(questions)));
    await tester.tap(find.text('Start Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('What is 2+2?'), findsOneWidget);

    final submit = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(submit.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '4');
    await tester.pump();

    final enabledSubmit = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabledSubmit.onPressed, isNotNull);

    await tester.tap(find.text('Submit Answer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Practice session shows progress bar and stats', (tester) async {
    final questions = [
      _question(id: 'q1', text: 'Question 1', type: QuestionType.typedAnswer, markschemeText: 'a'),
      _question(id: 'q2', text: 'Question 2', type: QuestionType.typedAnswer, markschemeText: 'b'),
    ];

    await tester.pumpWidget(_testApp(result: Result.success(questions)));
    await tester.tap(find.text('Start Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.access_time), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('Practice session shows different question types in app bar', (tester) async {
    final questions = [
      _question(
        id: 'q1',
        text: 'Math Q',
        type: QuestionType.mathExpression,
        markschemeText: 'x',
      ),
    ];

    await tester.pumpWidget(_testApp(result: Result.success(questions)));
    await tester.tap(find.text('Start Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Practice - mathExpression'), findsOneWidget);
  });

  testWidgets('Practice session completes session and shows results', (tester) async {
    final questions = [
      _question(id: 'q1', text: 'First Q', type: QuestionType.typedAnswer, markschemeText: 'yes'),
    ];

    await tester.pumpWidget(_testApp(result: Result.success(questions)));
    await tester.tap(find.text('Start Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'yes');
    await tester.pump();
    await tester.tap(find.text('Submit Answer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final nextButton = find.text('Next');
    await tester.ensureVisible(nextButton);
    await tester.pump();
    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Practice Complete!'), findsOneWidget);
    expect(find.text('Total Questions'), findsOneWidget);
    expect(find.text('Correct Answers'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('Practice Again'), findsOneWidget);
  });

  testWidgets('Submit button disabled when no answer for typedAnswer', (tester) async {
    final questions = [
      _question(id: 'q1', text: 'Fill in', type: QuestionType.typedAnswer, markschemeText: 'answer'),
    ];

    await tester.pumpWidget(_testApp(result: Result.success(questions)));
    await tester.tap(find.text('Start Practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'answer');
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabledButton.onPressed, isNotNull);
  });
}