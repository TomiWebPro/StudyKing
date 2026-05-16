import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_grid.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('PracticeModeGrid', () {
    testWidgets('renders four practice mode cards', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Quick Practice'), findsOneWidget);
      expect(find.text('Spaced Repetition'), findsOneWidget);
      expect(find.text('Topic Focus'), findsOneWidget);
      expect(find.text('Weak Areas'), findsOneWidget);
    });

    testWidgets('spaced repetition is disabled when no due counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No reviews scheduled.'), findsOneWidget);
    });

    testWidgets('shows due count when there are due reviews', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {'s1': 5},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5 due'), findsOneWidget);
    });

    testWidgets('weak areas disabled when no subjects', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: false,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Weak Areas'), findsOneWidget);
    });

    testWidgets('shows loading text when isLoadingDueCounts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: true,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('renders GridView layout', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('calls onQuickPractice when Quick Practice tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () => called = true,
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Practice'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onSpacedRepetition when due and tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {'s1': 3},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () => called = true,
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spaced Repetition'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onTopicFocus when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () => called = true,
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Topic Focus'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onWeakAreas when subjects exist and tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () => called = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weak Areas'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('shows badge on spaced repetition when due count > 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {'s1': 7},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('7 due'), findsOneWidget);
    });

    testWidgets('spaced repetition callback not called when no due counts', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () => called = true,
          onTopicFocus: () {},
          onWeakAreas: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spaced Repetition'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('weak areas card is disabled when no subjects', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: false,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () => called = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weak Areas'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });
  });
}
