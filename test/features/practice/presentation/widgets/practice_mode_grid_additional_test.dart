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
  group('PracticeModeGrid additional', () {
    testWidgets('renders Manual card when customQuestionCount > 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          customQuestionCount: 5,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Questions: 5'), findsOneWidget);
    });

    testWidgets('calls onMyQuestions when Manual card is tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          customQuestionCount: 3,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () => called = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Manual'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('shows disabled dialog for Spaced Repetition when no due counts', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spaced Repetition'));
      await tester.pumpAndSettle();

      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('shows disabled dialog for Weak Areas when no subjects', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: false,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weak Areas'));
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
    });

    testWidgets('shows disabled dialog for Manual when no custom questions', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          customQuestionCount: 0,
          totalQuestionCount: 10,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Manual'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      expect(find.text('Create Question'), findsOneWidget);
    });

    testWidgets('Manual card shows no questions subtitle when customQuestionCount is 0', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          customQuestionCount: 0,
          totalQuestionCount: 10,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Questions: 0'), findsOneWidget);
    });

    testWidgets('disabled dialog for Weak Areas shows Add First Subject message', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: false,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weak Areas'));
      await tester.pumpAndSettle();

      expect(find.text('Add your first subject to begin studying'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('disabled dialog for Quick Practice dismisses with Cancel', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          totalQuestionCount: 0,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Practice'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Materials'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Materials'), findsNothing);
    });

    testWidgets('renders Manual card with person icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          customQuestionCount: 5,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders five practice mode cards including Manual', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PracticeModeGrid(
          isLoadingDueCounts: false,
          dueCounts: {},
          hasSubjects: true,
          onQuickPractice: () {},
          onSpacedRepetition: () {},
          onTopicFocus: () {},
          onWeakAreas: () {},
          onMyQuestions: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Quick Practice'), findsOneWidget);
      expect(find.text('Spaced Repetition'), findsOneWidget);
      expect(find.text('Topic Focus'), findsOneWidget);
      expect(find.text('Weak Areas'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
    });
  });
}
