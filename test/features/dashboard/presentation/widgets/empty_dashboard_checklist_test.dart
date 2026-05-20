import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/presentation/widgets/empty_dashboard_checklist.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: Scaffold(body: child),
  );
}

void main() {
  group('EmptyDashboardChecklist', () {
    testWidgets('renders getting started title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.text('Getting Started'), findsOneWidget);
    });

    testWidgets('renders getting started description', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Complete these steps to get the most out of StudyKing',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders all 4 checklist items', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('Upload Study Material'), findsOneWidget);
      expect(find.text('Start Practicing'), findsOneWidget);
      expect(find.text('Schedule an AI Tutor Session'), findsOneWidget);
    });

    testWidgets('renders all 4 checklist descriptions', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Create your first subject to organize your study material',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Upload PDFs, notes, and question banks to get started',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Test your knowledge with adaptive practice questions',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Get personalized one-on-one tutoring with AI',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows rocket launch icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    });

    testWidgets('shows checklist item icons', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.library_add), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.byIcon(Icons.quiz), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('renders Card container', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders ChecklistItem with correct icon and text',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.library_add), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
    });

    testWidgets('shows progress badge when some items completed', (tester) async {
      final progress = ChecklistProgress(
        hasSubjects: true,
        hasSources: true,
      );
      await tester.pumpWidget(_buildTestApp(EmptyDashboardChecklist(progress: progress)));
      await tester.pumpAndSettle();

      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('shows celebration when all items completed', (tester) async {
      final progress = ChecklistProgress(
        hasSubjects: true,
        hasSources: true,
        hasPracticeSessions: true,
        hasScheduledLessons: true,
      );
      await tester.pumpWidget(_buildTestApp(EmptyDashboardChecklist(progress: progress)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.celebration), findsOneWidget);
      expect(find.text('Great job setting up!'), findsOneWidget);
    });

    testWidgets('celebration shows suggested actions', (tester) async {
      final progress = ChecklistProgress(
        hasSubjects: true,
        hasSources: true,
        hasPracticeSessions: true,
        hasScheduledLessons: true,
      );
      await tester.pumpWidget(_buildTestApp(EmptyDashboardChecklist(progress: progress)));
      await tester.pumpAndSettle();

      expect(find.text('Suggested next actions'), findsOneWidget);
    });

    testWidgets('celebration can be dismissed with Get Started', (tester) async {
      final progress = ChecklistProgress(
        hasSubjects: true,
        hasSources: true,
        hasPracticeSessions: true,
        hasScheduledLessons: true,
      );
      await tester.pumpWidget(_buildTestApp(EmptyDashboardChecklist(progress: progress)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.celebration), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.celebration), findsNothing);
    });

    testWidgets('first incomplete item is highlighted', (tester) async {
      final progress = ChecklistProgress(
        hasSubjects: true,
      );
      await tester.pumpWidget(_buildTestApp(EmptyDashboardChecklist(progress: progress)));
      await tester.pumpAndSettle();

      expect(find.text('Next Step'), findsOneWidget);
    });

    testWidgets('does not show completed count when all empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(const EmptyDashboardChecklist()));
      await tester.pumpAndSettle();

      expect(find.text('0 / 4'), findsNothing);
    });
  });
}
