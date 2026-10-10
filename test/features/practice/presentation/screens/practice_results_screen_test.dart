import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/presentation/screens/practice_results_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

TestNavigatorObserver? testNavigatorObserver;

Widget _buildTestApp(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: testNavigatorObserver != null ? [testNavigatorObserver!] : [],
    home: child,
  );
}

void main() {
  group('PracticeResultsScreen', () {
    setUp(() {
      testNavigatorObserver = TestNavigatorObserver();
    });

    tearDown(() {
      testNavigatorObserver = null;
    });

    testWidgets('renders results with correct values', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 10,
          correctAnswers: 7,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      expect(find.text('Correct: 7/10'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('renders 0% when no questions', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 0,
          correctAnswers: 0,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders 100% when all correct', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 5,
          correctAnswers: 5,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows practice again button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 5,
          correctAnswers: 3,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Practice Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onPracticeAgain when button tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 5,
          correctAnswers: 3,
          onPracticeAgain: () => called = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Again'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('shows app bar with session results title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 5,
          correctAnswers: 3,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session Results'), findsOneWidget);
    });

    testWidgets('renders topic breakdown entries', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 10,
          correctAnswers: 7,
          onPracticeAgain: () {},
          topicBreakdown: {'Algebra': 0.8, 'Geometry': 0.6},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Topic Breakdown'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('does not show topic breakdown section when empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 10,
          correctAnswers: 7,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Topic Breakdown'), findsNothing);
    });

    testWidgets('renders all stat rows', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 10,
          correctAnswers: 7,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Total Questions'), findsOneWidget);
      expect(find.text('Correct Answers'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
    });

    testWidgets('contains semantics merge and FocusTraversalOrder', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 5,
          correctAnswers: 3,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MergeSemantics), findsAtLeastNWidgets(1));
      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
      expect(find.byType(FocusTraversalOrder), findsOneWidget);
    });

    testWidgets('shows practice complete title', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeResultsScreen(
          totalQuestions: 5,
          correctAnswers: 3,
          onPracticeAgain: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Practice Complete!'), findsOneWidget);
    });

    group('additional coverage', () {
      testWidgets('renders 0 questions edge case', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 0,
            correctAnswers: 0,
            onPracticeAgain: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Session Results'), findsOneWidget);
        expect(find.text('Practice Complete!'), findsOneWidget);
      });

      testWidgets('handles large topic breakdown', (tester) async {
        final breakdown = <String, double>{};
        for (int i = 0; i < 20; i++) {
          breakdown['Topic $i'] = i / 20.0;
        }

        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
            topicBreakdown: breakdown,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Breakdown'), findsOneWidget);
        expect(find.text('Topic 0'), findsOneWidget);
        expect(find.text('Topic 19'), findsOneWidget);
      });

      testWidgets('empty topic breakdown does not show section', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
            topicBreakdown: {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Breakdown'), findsNothing);
      });

      testWidgets('practice again button has semantics label', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 5,
            correctAnswers: 3,
            onPracticeAgain: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.text('Practice Again'), findsOneWidget);
      });

      testWidgets('keyboard navigation with FocusTraversalOrder works', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 5,
            correctAnswers: 3,
            onPracticeAgain: () {},
            topicBreakdown: {'Algebra': 0.8},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
        expect(find.byType(FocusTraversalOrder), findsOneWidget);
      });

      testWidgets('accuracy correctly computed for various values', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 3,
            correctAnswers: 2,
            onPracticeAgain: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('67%'), findsOneWidget);
      });

      testWidgets('renders with 1 question all correct', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 1,
            correctAnswers: 1,
            onPracticeAgain: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('100%'), findsOneWidget);
        expect(find.text('Correct: 1/1'), findsOneWidget);
      });

      testWidgets('renders with 1 question all wrong', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 1,
            correctAnswers: 0,
            onPracticeAgain: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('0%'), findsOneWidget);
        expect(find.text('Correct: 0/1'), findsOneWidget);
      });

      testWidgets('stat rows render with locale-aware values', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Total Questions'), findsOneWidget);
        expect(find.text('Correct Answers'), findsOneWidget);
        expect(find.text('Accuracy'), findsOneWidget);
      });

      testWidgets('single topic in breakdown displays correctly', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
            topicBreakdown: {'SingleTopic': 0.5},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Topic Breakdown'), findsOneWidget);
        expect(find.text('SingleTopic'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
      });
    });

    group('answer source breakdown', () {
      Question makeQuestion(String id, {String? model}) {
        return Question(
          id: id,
          text: 'Question $id',
          type: QuestionType.singleChoice,
          subjectId: 'subject-1',
          topicId: 'topic-1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          model: model,
        );
      }

      testWidgets('shows Answer Source heading once alongside a single Topic Breakdown heading', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
            topicBreakdown: {'Algebra': 0.8, 'Geometry': 0.6},
            reviewQuestions: [
              QuestionReviewData(
                question: makeQuestion('q1'), // model == null → manual source
                userAnswer: '4',
                correctAnswer: '4',
                isCorrect: true,
              ),
              QuestionReviewData(
                question: makeQuestion('q2', model: 'ai-model'),
                userAnswer: '5',
                correctAnswer: '4',
                isCorrect: false,
              ),
            ],
          ),
        ));
        await tester.pumpAndSettle();

        // Regression: the manual/AI section must not reuse the topic
        // breakdown heading (previously rendered two identical headings).
        expect(find.text('Topic Breakdown'), findsOneWidget);
        expect(find.text('Answer Source'), findsOneWidget);
        expect(find.text('Manual'), findsOneWidget);
        expect(find.text('AI-generated'), findsOneWidget);
      });

      testWidgets('renders localized headings in Spanish without duplicating the topic heading', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
            topicBreakdown: {'Algebra': 0.8},
            reviewQuestions: [
              QuestionReviewData(
                question: makeQuestion('q1'),
                userAnswer: '4',
                correctAnswer: '4',
                isCorrect: true,
              ),
              QuestionReviewData(
                question: makeQuestion('q2', model: 'ai-model'),
                userAnswer: '5',
                correctAnswer: '4',
                isCorrect: false,
              ),
            ],
          ),
          locale: const Locale('es'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Desglose por Tema'), findsOneWidget);
        expect(find.text('Origen de las Respuestas'), findsOneWidget);
      });

      testWidgets('does not show answer source section when review questions are empty', (tester) async {
        await tester.pumpWidget(_buildTestApp(
          PracticeResultsScreen(
            totalQuestions: 10,
            correctAnswers: 7,
            onPracticeAgain: () {},
            topicBreakdown: {'Algebra': 0.8},
            reviewQuestions: const [],
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Answer Source'), findsNothing);
        expect(find.text('Topic Breakdown'), findsOneWidget);
      });
    });
  });
}
