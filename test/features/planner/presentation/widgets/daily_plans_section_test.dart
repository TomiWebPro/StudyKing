import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/presentation/widgets/daily_plans_section.dart';
import 'package:studyking/features/planner/presentation/widgets/daily_plan_card.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Builds a plan with [dayCount] daily plans for testing virtualization.
PersonalLearningPlan _buildLargePlan(int dayCount, String studentId) {
  final now = DateTime.now();
  final dailyPlans = List<DailyPlan>.generate(dayCount, (i) {
    return DailyPlan(
      date: now.add(Duration(days: i)),
      dayNumber: i + 1,
      priorityTopics: [
        PlannedTopic(
          topicId: 'topic_$i',
          topicTitle: 'Topic $i',
          priority: 1.0,
          reason: 'review',
          readinessScore: 0.8,
          reviewUrgency: 0.3,
          estimatedQuestions: 5,
          estimatedMinutes: 15,
          reasons: ['review'],
          subjectId: 'subject_1',
        ),
      ],
      reviewQuestionIds: [],
      stretchGoalQuestionIds: [],
      targetQuestions: 5,
      targetMinutes: 15,
      focus: 'Day ${i + 1}',
      isRestDay: i % 7 == 6,
      isCompleted: i < dayCount - 7,
    );
  });

  return PersonalLearningPlan(
    studentId: studentId,
    generatedAt: now,
    dailyPlans: dailyPlans,
    summary: PlanSummary(
      totalQuestions: dayCount * 5,
      totalMinutes: dayCount * 15,
      newTopics: 0,
      reviewTopics: dayCount,
      estimatedCoverage: 1.0,
      focusAreas: [],
    ),
    recommendations: [],
    planDurationDays: dayCount,
  );
}

class _FakePlannerService extends PlannerService {
  _FakePlannerService() : super(lessonAgentService: null, localeName: 'en');

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(null);
  }

  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<PendingActionModel>>> loadPendingActions() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Session>>> getMissedLessons() async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, int>>> getAdherenceMetrics() async {
    return Result.success({});
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    return Result.success([]);
  }
}

Widget buildApp(Widget widget) {
  return ProviderScope(
    overrides: [
      plannerServiceProvider.overrideWithValue(_FakePlannerService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    ),
  );
}

void main() {
  group('DailyPlansSection', () {
    testWidgets('returns SizedBox.shrink when plan is null', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlansSection(
          onStartTutoring: (_, __, ___) {},
          onScheduleLesson: (_, __, ___) {},
        ),
      ));

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildApp(
        DailyPlansSection(
          onStartTutoring: (_, __, ___) {},
          onScheduleLesson: (_, __, ___) {},
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders large plan via virtualized ListView not eager Column spread', (tester) async {
      final plan = _buildLargePlan(365, 'student1');
      final notifier = PlannerNotifier(_FakePlannerService());
      notifier.currentState = PlannerState(plan: plan);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannerServiceProvider.overrideWithValue(_FakePlannerService()),
            plannerProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: DailyPlansSection(
                onStartTutoring: (_, __, ___) {},
                onScheduleLesson: (_, __, ___) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(DailyPlanCard), findsWidgets);
    });

    testWidgets('does not eagerly build all DailyPlanCards for large plan', (tester) async {
      final plan = _buildLargePlan(365, 'student1');
      final notifier = PlannerNotifier(_FakePlannerService());
      notifier.currentState = PlannerState(plan: plan);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannerServiceProvider.overrideWithValue(_FakePlannerService()),
            plannerProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: DailyPlansSection(
                onStartTutoring: (_, __, ___) {},
                onScheduleLesson: (_, __, ___) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Virtualized: only visible items (within cache extent) should be built,
      // not all 365 at once.
      final cardCount = find.byType(DailyPlanCard).evaluate().length;
      expect(cardCount, lessThan(365));
      expect(cardCount, greaterThan(0));
    });
  });
}
