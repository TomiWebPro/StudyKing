import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_results_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('PracticeResultsScreen', () {
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
      expect(find.text('7/10'), findsOneWidget);
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
  });
}
