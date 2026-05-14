import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/presentation/widgets/daily_plan_card.dart';
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

  DailyPlan plan({
    int dayNumber = 1,
    String? focus,
    bool isRestDay = false,
    List<PlannedTopic> topics = const [],
    int targetQuestions = 10,
    int targetMinutes = 30,
  }) {
    return DailyPlan(
      date: DateTime.now(),
      dayNumber: dayNumber,
      priorityTopics: topics,
      reviewQuestionIds: const [],
      stretchGoalQuestionIds: const [],
      targetQuestions: targetQuestions,
      targetMinutes: targetMinutes,
      focus: focus,
      isRestDay: isRestDay,
    );
  }

  PlannedTopic topic({
    String id = 'topic-1',
    String title = 'Algebra',
  }) {
    return PlannedTopic(
      topicId: id,
      topicTitle: title,
      priority: 1.0,
      reason: 'Needs practice',
      readinessScore: 0.5,
      reviewUrgency: 0.8,
      estimatedQuestions: 5,
      estimatedMinutes: 15,
      reasons: ['Needs practice'],
      subjectId: 'subj-1',
    );
  }

  group('DailyPlanCard', () {
    testWidgets('renders day number', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(dayNumber: 3),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows rest day chip when isRestDay', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(isRestDay: true),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.text('Rest'), findsOneWidget);
    });

    testWidgets('shows focus label when provided', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(focus: 'Review key concepts'),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.text('Review key concepts'), findsOneWidget);
    });

    testWidgets('shows default study day when no focus', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.text('Study Day'), findsOneWidget);
    });

    testWidgets('shows target questions and minutes', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(targetQuestions: 15, targetMinutes: 45),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.textContaining('15'), findsOneWidget);
      expect(find.textContaining('45'), findsOneWidget);
    });

    testWidgets('renders priority topics with action buttons', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(topics: [topic()]),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    });

    testWidgets('schedule lesson button shown when onScheduleLesson provided', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(topics: [topic()]),
          onStartTutoring: (_, __, ___) {},
          onScheduleLesson: (_, __, ___) {},
        ),
      ));

      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('start tutoring button calls callback', (tester) async {
      String? capturedTopicId;
      String? capturedTopicTitle;
      String? capturedSubjectId;

      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(topics: [topic()]),
          onStartTutoring: (topicId, topicTitle, subjectId) {
            capturedTopicId = topicId;
            capturedTopicTitle = topicTitle;
            capturedSubjectId = subjectId;
          },
        ),
      ));

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      expect(capturedTopicId, 'topic-1');
      expect(capturedTopicTitle, 'Algebra');
      expect(capturedSubjectId, 'subj-1');
    });

    testWidgets('no priority topics section for rest days', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlanCard(
          day: plan(isRestDay: true, topics: [topic()]),
          onStartTutoring: (_, __, ___) {},
        ),
      ));

      expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
    });
  });
}
