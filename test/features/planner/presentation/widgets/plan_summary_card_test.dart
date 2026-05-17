import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/presentation/widgets/plan_summary_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    );
  }

  group('PlanSummaryCard', () {
    testWidgets('renders plan summary title and icon', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 5,
            reviewTopics: 3,
            estimatedCoverage: 0.75,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('Plan Summary'), findsOneWidget);
      expect(find.byIcon(Icons.summarize), findsOneWidget);
    });

    testWidgets('shows total questions and time', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 100,
            totalMinutes: 600,
            newTopics: 10,
            reviewTopics: 5,
            estimatedCoverage: 0.8,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('100Q'), findsOneWidget);
      expect(find.text('600 min'), findsOneWidget);
    });

    testWidgets('shows new and review topic counts', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 8,
            reviewTopics: 4,
            estimatedCoverage: 0.6,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('8 new'), findsOneWidget);
      expect(find.text('4 review'), findsOneWidget);
    });

    testWidgets('shows estimated coverage percentage', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 5,
            reviewTopics: 3,
            estimatedCoverage: 0.85,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('shows focus areas when provided', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 5,
            reviewTopics: 3,
            estimatedCoverage: 0.7,
            focusAreas: ['Algebra', 'Geometry'],
          ),
        ),
      ));

      expect(find.textContaining('Algebra'), findsOneWidget);
      expect(find.textContaining('Geometry'), findsOneWidget);
    });

    testWidgets('does not show focus areas section when empty', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 5,
            reviewTopics: 3,
            estimatedCoverage: 0.7,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.textContaining('Algebra'), findsNothing);
      expect(find.textContaining('Geometry'), findsNothing);
    });

    testWidgets('renders summary chips in a wrap layout', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 30,
            totalMinutes: 180,
            newTopics: 3,
            reviewTopics: 2,
            estimatedCoverage: 0.5,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('renders divider', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 5,
            reviewTopics: 3,
            estimatedCoverage: 0.75,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders all five summary chips', (tester) async {
      await tester.pumpWidget(buildApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 100,
            totalMinutes: 600,
            newTopics: 8,
            reviewTopics: 4,
            estimatedCoverage: 0.85,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('100Q'), findsOneWidget);
      expect(find.text('600 min'), findsOneWidget);
      expect(find.text('8 new'), findsOneWidget);
      expect(find.text('4 review'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });
  });

  group('PlanSummaryCard Spanish locale', () {
    Widget buildSpanishApp(Widget widget) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: widget),
      );
    }

    testWidgets('shows localized question abbreviation and percentage', (tester) async {
      await tester.pumpWidget(buildSpanishApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 100,
            totalMinutes: 600,
            newTopics: 10,
            reviewTopics: 5,
            estimatedCoverage: 0.85,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('100P'), findsOneWidget);
      expect(find.textContaining('85'), findsOneWidget);
    });

    testWidgets('shows localized new and review text', (tester) async {
      await tester.pumpWidget(buildSpanishApp(
        PlanSummaryCard(
          summary: PlanSummary(
            totalQuestions: 50,
            totalMinutes: 300,
            newTopics: 3,
            reviewTopics: 2,
            estimatedCoverage: 0.6,
            focusAreas: [],
          ),
        ),
      ));

      expect(find.text('3 nuevos'), findsOneWidget);
      expect(find.text('2 revisión'), findsOneWidget);
    });
  });
}
