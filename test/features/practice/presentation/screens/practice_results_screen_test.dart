import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/screens/practice_results_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/navigator_observer_helper.dart';

TestNavigatorObserver? testNavigatorObserver;

Widget _buildTestApp(Widget child) {
  return MaterialApp(
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
  });
}
