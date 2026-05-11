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

class _TestNavigatorObserver extends NavigatorObserver {
  int popCount = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

Question _question({
  required String id,
  required String text,
  required QuestionType type,
  required String markschemeText,
  String topicId = 'topic-a',
  List<String> options = const [],
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
  NavigatorObserver? observer,
}) {
  return ProviderScope(
    overrides: [
      questionRepositoryProvider.overrideWithValue(_FakeQuestionRepository(result)),
    ],
    child: MaterialApp(
      navigatorObservers: observer == null ? const [] : [observer],
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
  group('PracticeSessionScreen behavior', () {
    testWidgets('loads questions and renders first question', (tester) async {
      final questions = [
        _question(id: 'q1', text: 'What is 2+2?', type: QuestionType.typedAnswer, markschemeText: '4'),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('What is 2+2?'), findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget);
    });

    testWidgets('shows no-questions path for empty result', (tester) async {
      await tester.pumpWidget(_sessionApp(result: Result.success(const [])));
      await tester.tap(find.text('Open Session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No Questions Available'), findsOneWidget);
    });

    testWidgets('submit is disabled until answer exists and score updates on submit', (tester) async {
      final questions = [
        _question(id: 'q1', text: 'Capital of France?', type: QuestionType.typedAnswer, markschemeText: 'Paris'),
      ];

      await tester.pumpWidget(_sessionApp(result: Result.success(questions)));
      await tester.tap(find.text('Open Session'));
      await tester.pumpAndSettle();

      final submit = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(submit.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();

      final enabledSubmit = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(enabledSubmit.onPressed, isNotNull);

      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('completes session and pops back to previous route', (tester) async {
      final observer = _TestNavigatorObserver();
      final questions = [
        _question(id: 'q1', text: 'One?', type: QuestionType.typedAnswer, markschemeText: 'ok'),
        _question(id: 'q3', text: 'Wrong topic', type: QuestionType.typedAnswer, markschemeText: 'ok', topicId: 'topic-b'),
      ];

      await tester.pumpWidget(
        _sessionApp(
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
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 600));
      expect(observer.popCount, greaterThan(0));
      expect(find.text('Open Session'), findsOneWidget);
    });
  });

  group('PracticeAnswerRecord', () {
    test('stores session answer details', () {
      final record = PracticeAnswerRecord(
        questionId: 'q-1',
        questionType: QuestionType.typedAnswer,
        isCorrect: true,
        timeSpent: const Duration(seconds: 15),
        userAnswer: 'Paris',
      );

      expect(record.questionId, 'q-1');
      expect(record.questionType, QuestionType.typedAnswer);
      expect(record.isCorrect, isTrue);
      expect(record.timeSpent, const Duration(seconds: 15));
      expect(record.userAnswer, 'Paris');
    });
  });
}
