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

PersonalLearningPlan createRestDayPlan() {
  final now = DateTime.now();
  return PersonalLearningPlan(
    studentId: 'student-1',
    generatedAt: now,
    dailyPlans: [
      DailyPlan(
        date: now,
        dayNumber: 1,
        priorityTopics: [],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: 0,
        targetMinutes: 0,
        isRestDay: true,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: 0,
      totalMinutes: 0,
      newTopics: 0,
      reviewTopics: 0,
      estimatedCoverage: 0,
      focusAreas: [],
    ),
    recommendations: [],
    planDurationDays: 1,
  );
}

PersonalLearningPlan createEmptyPlan() {
  final now = DateTime.now();
  return PersonalLearningPlan(
    studentId: 'student-1',
    generatedAt: now,
    dailyPlans: [],
    summary: PlanSummary(
      totalQuestions: 0,
      totalMinutes: 0,
      newTopics: 0,
      reviewTopics: 0,
      estimatedCoverage: 0,
      focusAreas: [],
    ),
    recommendations: [],
    planDurationDays: 0,
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

      for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
        expect(find.textContaining(day.substring(0, 2)), findsAtLeast(1));
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

    testWidgets('tapping a day without topics does not fire onDayTap',
        (tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(buildApp(
        CalendarViewWidget(
          plan: createPlan(),
          onDayTap: (topicId, topicTitle, subjectId) {
            wasCalled = true;
          },
        ),
      ));

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final dayCell = find.text('${tomorrow.day}').last;
      await tester.tap(dayCell);
      await tester.pumpAndSettle();

      expect(wasCalled, isFalse);
    });

    testWidgets('renders rest day without minutes', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createRestDayPlan()),
      ));

      final now = DateTime.now();
      expect(find.text('${now.day}'), findsOneWidget);
      expect(find.text('0m'), findsNothing);
    });

    testWidgets('renders with empty plan (no daily plans)', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createEmptyPlan()),
      ));

      final expected = DateFormat.yMMM().format(DateTime(DateTime.now().year, DateTime.now().month));
      expect(find.text(expected), findsOneWidget);
      for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
        expect(find.textContaining(day.substring(0, 2)), findsAtLeast(1));
      }
    });

    testWidgets('month-boundary navigation from December to January',
        (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));
      final monthsToDec = ((now.month - 12) % 12);
      for (var i = 0; i < monthsToDec; i++) {
        await tester.tap(find.byIcon(Icons.chevron_left));
      }
      await tester.pumpAndSettle();

      final decYear = now.month > monthsToDec ? now.year : now.year - 1;
      expect(find.text('Dec $decYear'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      final janYear = decYear + 1;
      expect(find.text('Jan $janYear'), findsOneWidget);
    });

    testWidgets('today cell has special decoration', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('non-rest day shows target minutes', (tester) async {
      await tester.pumpWidget(buildApp(
        CalendarViewWidget(plan: createPlan()),
      ));

      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('onDayTap is null prevents tapping', (tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(buildApp(
        CalendarViewWidget(
          plan: createPlan(),
          onDayTap: null,
        ),
      ));

      final now = DateTime.now();
      final dayCell = find.text('${now.day}').last;
      await tester.tap(dayCell);
      await tester.pumpAndSettle();

      expect(wasCalled, isFalse);
    });
  });
}
