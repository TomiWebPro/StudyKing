import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/presentation/widgets/calendar_view_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Widget buildApp(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: widget),
  );
}

PersonalLearningPlan createPlan({
  String studentId = 'student-1',
  int planDurationDays = 7,
}) {
  final now = DateTime.now();
  return PersonalLearningPlan(
    studentId: studentId,
    generatedAt: now,
    dailyPlans: [
      DailyPlan(
        date: now,
        dayNumber: 1,
        priorityTopics: [
          PlannedTopic(
            topicId: 't1',
            topicTitle: 'Algebra',
            priority: 0.9,
            reason: 'Weak area',
            readinessScore: 0.3,
            reviewUrgency: 0.8,
            estimatedQuestions: 10,
            estimatedMinutes: 30,
            reasons: ['needs practice'],
            subjectId: 'subj-1',
          ),
        ],
        reviewQuestionIds: ['q1'],
        stretchGoalQuestionIds: ['q2'],
        targetQuestions: 10,
        targetMinutes: 30,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: 10,
      totalMinutes: 30,
      newTopics: 2,
      reviewTopics: 3,
      estimatedCoverage: 0.75,
      focusAreas: ['algebra'],
    ),
    recommendations: [
      PlanRecommendation(
        topicId: 't1',
        reason: 'Weak',
        recommendationType: 'practice',
        priority: 0.9,
        explanations: ['needs work'],
      ),
    ],
    planDurationDays: planDurationDays,
  );
}

void main() {
  setUp(() async {
    Intl.defaultLocale = 'en';
    await initializeDateFormatting('en');
  });

  group('CalendarViewWidget', () {
    testWidgets('renders month header', (tester) async {
      final now = DateTime.now();
      final expected = DateFormat.yMMM().format(DateTime(now.year, now.month));

      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));

      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('renders day cells with day numbers', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('navigation buttons change month', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1);
      final nextMonth = DateTime(now.year, now.month + 1);
      final prevExpected = DateFormat.yMMM().format(prevMonth);
      final nextExpected = DateFormat.yMMM().format(nextMonth);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text(prevExpected), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text(DateFormat.yMMM().format(now)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text(nextExpected), findsOneWidget);
    });

    testWidgets('renders day headers', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));

      for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
        expect(find.text(day), findsAtLeast(1));
      }
    });

    testWidgets('onDayTap callback fires when tapping a day with topics',
        (tester) async {
      String? capturedTopicId;
      String? capturedTopicTitle;
      String? capturedSubjectId;

      await tester.pumpWidget(buildApp(
        CalendarViewWidget(
          plan: createPlan(),
          onDayTap: (topicId, topicTitle, subjectId) {
            capturedTopicId = topicId;
            capturedTopicTitle = topicTitle;
            capturedSubjectId = subjectId;
          },
        ),
      ));

      final now = DateTime.now();
      final dayCell = find.text('${now.day}').last;
      await tester.tap(dayCell);
      await tester.pumpAndSettle();

      expect(capturedTopicId, 't1');
      expect(capturedTopicTitle, 'Algebra');
      expect(capturedSubjectId, 'subj-1');
    });
  });
}
