import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/presentation/widgets/pace_adjustment_card.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class _FakePlannerService extends PlannerService {
  _FakePlannerService({PersonalLearningPlan? plan})
      : _plan = plan,
        super(lessonAgentService: null, localeName: 'en');

  final PersonalLearningPlan? _plan;
  final List<double> adjustPaceTargets = [];
  final List<String> updatedGoalSubjectIds = [];
  final List<double> updatedGoalHours = [];

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(_plan);
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

  @override
  Future<Result<void>> adjustPace(
    double newTargetMinutesPerDay, {
    bool recalculateDuration = false,
  }) async {
    adjustPaceTargets.add(newTargetMinutesPerDay);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateSyllabusGoalHours(
    String subjectId,
    double targetHoursPerDay,
  ) async {
    updatedGoalSubjectIds.add(subjectId);
    updatedGoalHours.add(targetHoursPerDay);
    return Result.success(null);
  }
}

PersonalLearningPlan _singleSubjectPlan() {
  return PersonalLearningPlan(
    studentId: 'student-1',
    planId: 'plan-1',
    generatedAt: DateTime(2026, 1, 1),
    dailyPlans: [
      DailyPlan(
        date: DateTime(2026, 1, 1),
        dayNumber: 1,
        priorityTopics: [],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: 15,
        targetMinutes: 180,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: 30,
      totalMinutes: 360,
      newTopics: 2,
      reviewTopics: 0,
      estimatedCoverage: 0.5,
      focusAreas: [],
    ),
    recommendations: [],
    targetMinutesPerDay: 180.0,
    targetQuestionsPerDay: 15,
    metadata: {
      'syllabus_goals': [
        {
          'subjectId': 'math',
          'subjectTitle': 'Math',
          'targetDays': 30,
          'targetHoursPerDay': 3,
        },
      ],
    },
  );
}

PersonalLearningPlan _twoSubjectPlan() {
  return PersonalLearningPlan(
    studentId: 'student-1',
    planId: 'plan-1',
    generatedAt: DateTime(2026, 1, 1),
    dailyPlans: [
      DailyPlan(
        date: DateTime(2026, 1, 1),
        dayNumber: 1,
        priorityTopics: [],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        targetQuestions: 15,
        targetMinutes: 180,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: 30,
      totalMinutes: 360,
      newTopics: 2,
      reviewTopics: 0,
      estimatedCoverage: 0.5,
      focusAreas: [],
    ),
    recommendations: [],
    targetMinutesPerDay: 180.0,
    targetQuestionsPerDay: 15,
    metadata: {
      'syllabus_goals': [
        {
          'subjectId': 'math',
          'subjectTitle': 'Math',
          'targetDays': 30,
          'targetHoursPerDay': 2,
        },
        {
          'subjectId': 'physics',
          'subjectTitle': 'Physics',
          'targetDays': 30,
          'targetHoursPerDay': 1,
        },
      ],
    },
  );
}

Widget buildApp(Widget widget, PlannerService service) {
  return ProviderScope(
    overrides: [
      plannerServiceProvider.overrideWithValue(service),
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
  group('PaceAdjustmentCard', () {
    testWidgets('shows no plan message when plan is null', (tester) async {
      await tester.pumpWidget(buildApp(const PaceAdjustmentCard(), _FakePlannerService()));

      expect(find.text('No study plan yet'), findsOneWidget);
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildApp(const PaceAdjustmentCard(), _FakePlannerService()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders one slider per syllabus goal for multi-subject plans',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const PaceAdjustmentCard(), _FakePlannerService(plan: _twoSubjectPlan())),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PaceAdjustmentCard)),
        listen: false,
      );
      await container.read(plannerProvider.notifier).loadExistingPlan();
      await tester.pumpAndSettle();

      expect(find.text('Math'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('dragging a per-subject slider updates that subject goal, '
        'not the global pace', (tester) async {
      final fake = _FakePlannerService(plan: _twoSubjectPlan());
      await tester.pumpWidget(buildApp(const PaceAdjustmentCard(), fake));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PaceAdjustmentCard)),
        listen: false,
      );
      await container.read(plannerProvider.notifier).loadExistingPlan();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Slider).at(0), const Offset(150, 0));
      await tester.pumpAndSettle();

      // The dragged subject's goal is updated through the per-goal path
      // (a drag fires onChanged multiple times)...
      expect(fake.updatedGoalSubjectIds, isNotEmpty);
      expect(fake.updatedGoalSubjectIds.toSet(), {'math'});
      expect(fake.updatedGoalHours, isNotEmpty);
      // ...and the global pace is NOT overwritten with the single
      // subject's hours (the old bug called adjustPace with goal*60).
      expect(fake.adjustPaceTargets, isEmpty);
    });

    testWidgets('apply persists the sum of per-subject hours, not the average',
        (tester) async {
      final fake = _FakePlannerService(plan: _twoSubjectPlan());
      await tester.pumpWidget(buildApp(const PaceAdjustmentCard(), fake));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PaceAdjustmentCard)),
        listen: false,
      );
      await container.read(plannerProvider.notifier).loadExistingPlan();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Study pace adjusted successfully'));
      await tester.pumpAndSettle();

      // Math 2h + Physics 1h = 3h = 180 min (the sum), not 90 min (average).
      expect(fake.adjustPaceTargets, [180.0]);
      expect(fake.updatedGoalSubjectIds, isEmpty);
    });

    testWidgets('single-subject slider keeps the dragged value after a '
        'rebuild (does not snap back to the persisted pace)',
        (tester) async {
      final fake = _FakePlannerService(plan: _singleSubjectPlan());
      await tester.pumpWidget(buildApp(const PaceAdjustmentCard(), fake));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PaceAdjustmentCard)),
        listen: false,
      );
      await container.read(plannerProvider.notifier).loadExistingPlan();
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      // 180 minutes/day seeds the single-subject slider at 3.0 hours.
      expect(tester.widget<Slider>(slider).value, 3.0);

      // Drag the thumb to the right and let the card rebuild.
      await tester.drag(slider, const Offset(150, 0));
      await tester.pumpAndSettle();

      final draggedValue = tester.widget<Slider>(slider).value;
      // The thumb must stay where the drag left it. The old code
      // re-derived _paceHours from the persisted plan on EVERY build
      // (without the _initialized guard), snapping it back to 3.0.
      expect(draggedValue, isNot(3.0));

      // The rendered hours label reflects the dragged value.
      final expectedLabel =
          '${formatDecimal(draggedValue, 'en', minFractionDigits: 1)} Hours/Day';
      expect(find.text(expectedLabel), findsOneWidget);

      // Apply persists the dragged pace, not the stale persisted pace.
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Study pace adjusted successfully'),
      );
      await tester.pumpAndSettle();
      expect(fake.adjustPaceTargets, [draggedValue * 60]);
    });
  });
}
