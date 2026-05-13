import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/personal_learning_plan_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/presentation/learning_plan_dashboard.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

const _kTodaysPlan = "Today's Plan";
const _kNoStudyPlanToday = 'No study plan for today';
const _kAtRiskTopics = 'At Risk Topics';
const _kReadyToAdvance = 'Ready to Advance';
const _kMasteryOverview = 'Mastery Overview';
const _kNoAtRiskTopics = 'No at-risk topics. Keep up the good work!';
const _kKeepPracticingToUnlock = 'Keep practicing to unlock advanced topics!';
const _kTotalTopics = 'Total Topics';
const _kMastered = 'Mastered';
const _kWeak = 'Weak';
const _kAccuracy = 'Accuracy: 30%';

class FakePersonalLearningPlanService extends PersonalLearningPlanService {
  final PersonalLearningPlan? plan;
  final List<String> atRiskIds;
  final List<String> readyToAdvanceIds;
  final bool failGeneratePlan;
  final bool failGetAtRisk;
  final bool failGetReadyToAdvance;
  Completer<Result<PersonalLearningPlan>>? _generatePlanCompleter;

  FakePersonalLearningPlanService({
    this.plan,
    this.atRiskIds = const [],
    this.readyToAdvanceIds = const [],
    this.failGeneratePlan = false,
    this.failGetAtRisk = false,
    this.failGetReadyToAdvance = false,
  });

  @override
  Future<Result<PersonalLearningPlan>> generatePlan(String studentId) async {
    if (_generatePlanCompleter != null) {
      return _generatePlanCompleter!.future;
    }
    if (failGeneratePlan) return Result.failure('Plan generation failed');
    if (plan == null) return Result.failure('No plan');
    return Result.success(plan!);
  }

  @override
  Future<Result<List<String>>> getAtRiskTopicIds(String studentId) async {
    if (failGetAtRisk) return Result.failure('Failed to get at-risk topics');
    return Result.success(atRiskIds);
  }

  @override
  Future<Result<List<String>>> getReadyToAdvanceTopicIds(String studentId) async {
    if (failGetReadyToAdvance) return Result.failure('Failed to get ready-to-advance topics');
    return Result.success(readyToAdvanceIds);
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> weakTopics;
  final Map<String, dynamic>? snapshot;
  final bool failGetWeakTopics;
  final bool failGetSnapshot;

  FakeMasteryGraphService({
    this.weakTopics = const [],
    this.snapshot,
    this.failGetWeakTopics = false,
    this.failGetSnapshot = false,
  });

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    if (failGetWeakTopics) return Result.failure('Failed to get weak topics');
    return Result.success(weakTopics);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    if (failGetSnapshot) return Result.failure('Failed to get snapshot');
    return Result.success(snapshot ?? {
      'totalTopics': 0,
      'masteredTopics': 0,
      'weakTopics': 0,
      'averageAccuracy': 0.0,
      'avgReadiness': 0.0,
    });
  }
}

Widget _buildTestApp(LearningPlanDashboard dashboard) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: dashboard),
  );
}

PersonalLearningPlan _makePlan({
  String focus = 'Algebra Review',
  int targetQuestions = 10,
  int targetMinutes = 30,
  bool isRestDay = false,
  double reviewUrgency = 0.8,
}) {
  return PersonalLearningPlan(
    studentId: 'student-1',
    generatedAt: DateTime.now(),
    dailyPlans: [
      DailyPlan(
        date: DateTime.now(),
        dayNumber: 1,
        focus: isRestDay ? null : focus,
        targetQuestions: targetQuestions,
        targetMinutes: targetMinutes,
        priorityTopics: isRestDay ? [] : [
          PlannedTopic(
            topicId: 'topic-1',
            topicTitle: 'Algebra',
            priority: 2.0,
            reason: 'Needs review',
            readinessScore: 0.5,
            reviewUrgency: reviewUrgency,
            estimatedQuestions: 5,
            estimatedMinutes: 20,
            reasons: ['Needs review'],
          ),
        ],
        reviewQuestionIds: [],
        stretchGoalQuestionIds: [],
        isRestDay: isRestDay,
      ),
    ],
    summary: PlanSummary(
      totalQuestions: targetQuestions,
      totalMinutes: targetMinutes,
      newTopics: 1,
      reviewTopics: 1,
      estimatedCoverage: 0.5,
      focusAreas: [focus],
    ),
    recommendations: [],
  );
}

void main() {
  group('LearningPlanDashboard', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final planService = FakePersonalLearningPlanService();
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no plan', (tester) async {
      final planService = FakePersonalLearningPlanService();
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kTodaysPlan), findsOneWidget);
      expect(find.text(_kNoStudyPlanToday), findsOneWidget);
    });

    testWidgets('shows today plan with focus chip', (tester) async {
      final plan = _makePlan();
      final planService = FakePersonalLearningPlanService(plan: plan);
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kTodaysPlan), findsOneWidget);
      expect(find.text('Algebra Review'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('10 questions'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('shows at risk topics section', (tester) async {
      final planService = FakePersonalLearningPlanService(
        atRiskIds: ['topic-1'],
      );
      final masteryService = FakeMasteryGraphService(
        weakTopics: [
          MasteryState(
            studentId: 'student-1',
            topicId: 'topic-1',
            masteryLevel: MasteryLevel.novice,
            accuracy: 0.3,
            reviewUrgency: 0.9,
            lastAttempt: DateTime.now().subtract(const Duration(days: 7)),
            lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kAtRiskTopics), findsOneWidget);
      expect(find.text(_kAccuracy), findsOneWidget);
    });

    testWidgets('shows ready to advance section', (tester) async {
      final planService = FakePersonalLearningPlanService(
        readyToAdvanceIds: ['topic-2'],
      );
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kReadyToAdvance), findsOneWidget);
    });

    testWidgets('shows mastery overview section', (tester) async {
      final planService = FakePersonalLearningPlanService();
      final masteryService = FakeMasteryGraphService(snapshot: {
        'totalTopics': 10,
        'masteredTopics': 3,
        'weakTopics': 2,
        'averageAccuracy': 0.75,
        'avgReadiness': 0.6,
      });

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kMasteryOverview), findsOneWidget);
      expect(find.text(_kTotalTopics), findsOneWidget);
      expect(find.text(_kMastered), findsOneWidget);
      expect(find.text(_kWeak), findsOneWidget);
    });

    testWidgets('shows empty at risk state', (tester) async {
      final planService = FakePersonalLearningPlanService();
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kNoAtRiskTopics), findsOneWidget);
    });

    testWidgets('shows empty ready to advance state', (tester) async {
      final planService = FakePersonalLearningPlanService();
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kKeepPracticingToUnlock), findsOneWidget);
    });

    testWidgets('shows rest day content', (tester) async {
      final plan = _makePlan(isRestDay: true);
      final planService = FakePersonalLearningPlanService(plan: plan);
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kNoStudyPlanToday), findsOneWidget);
    });

    testWidgets('handles generatePlan failure gracefully', (tester) async {
      final planService = FakePersonalLearningPlanService(failGeneratePlan: true);
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kTodaysPlan), findsOneWidget);
      expect(find.text(_kNoStudyPlanToday), findsOneWidget);
    });

    testWidgets('handles getWeakTopics failure while plan succeeds', (tester) async {
      final plan = _makePlan();
      final planService = FakePersonalLearningPlanService(plan: plan);
      final masteryService = FakeMasteryGraphService(
        failGetWeakTopics: true,
      );

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra Review'), findsOneWidget);
      expect(find.text(_kMasteryOverview), findsOneWidget);
    });

    testWidgets('handles getMasterySnapshot failure', (tester) async {
      final planService = FakePersonalLearningPlanService();
      final masteryService = FakeMasteryGraphService(
        failGetSnapshot: true,
      );

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(_kMasteryOverview), findsOneWidget);
    });

    testWidgets('handles at risk failure while plan succeeds', (tester) async {
      final plan = _makePlan();
      final planService = FakePersonalLearningPlanService(
        plan: plan,
        failGetAtRisk: true,
      );
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra Review'), findsOneWidget);
      expect(find.text(_kAtRiskTopics), findsOneWidget);
    });

    testWidgets('handles ready to advance failure while plan succeeds', (tester) async {
      final plan = _makePlan();
      final planService = FakePersonalLearningPlanService(
        plan: plan,
        failGetReadyToAdvance: true,
      );
      final masteryService = FakeMasteryGraphService();

      await tester.pumpWidget(_buildTestApp(
        LearningPlanDashboard(
          studentId: 'student-1',
          planService: planService,
          masteryService: masteryService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algebra Review'), findsOneWidget);
      expect(find.text(_kReadyToAdvance), findsOneWidget);
    });

    group('mounted guard', () {
      testWidgets('does not call setState after widget is disposed', (tester) async {
        final completer = Completer<Result<PersonalLearningPlan>>();
        final planService = FakePersonalLearningPlanService();
        planService._generatePlanCompleter = completer;
        final masteryService = FakeMasteryGraphService();

        await tester.pumpWidget(_buildTestApp(
          LearningPlanDashboard(
            studentId: 'student-1',
            planService: planService,
            masteryService: masteryService,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpWidget(Container());

        completer.complete(Result.success(_makePlan()));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('urgency indicator', () {
      testWidgets('shows red indicator for high urgency (> 0.7)', (tester) async {
        final plan = _makePlan(reviewUrgency: 0.9);
        final planService = FakePersonalLearningPlanService(plan: plan);
        final masteryService = FakeMasteryGraphService();

        await tester.pumpWidget(_buildTestApp(
          LearningPlanDashboard(
            studentId: 'student-1',
            planService: planService,
            masteryService: masteryService,
          ),
        ));
        await tester.pumpAndSettle();

        final finder = find.byWidgetPredicate(
          (widget) => widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.red,
        );
        expect(finder, findsAtLeast(1));
      });

      testWidgets('shows orange indicator for medium urgency (> 0.4, <= 0.7)', (tester) async {
        final plan = _makePlan(reviewUrgency: 0.6);
        final planService = FakePersonalLearningPlanService(plan: plan);
        final masteryService = FakeMasteryGraphService();

        await tester.pumpWidget(_buildTestApp(
          LearningPlanDashboard(
            studentId: 'student-1',
            planService: planService,
            masteryService: masteryService,
          ),
        ));
        await tester.pumpAndSettle();

        final finder = find.byWidgetPredicate(
          (widget) => widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.orange,
        );
        expect(finder, findsAtLeast(1));
      });

      testWidgets('shows green indicator for low urgency (<= 0.4)', (tester) async {
        final plan = _makePlan(reviewUrgency: 0.3);
        final planService = FakePersonalLearningPlanService(plan: plan);
        final masteryService = FakeMasteryGraphService();

        await tester.pumpWidget(_buildTestApp(
          LearningPlanDashboard(
            studentId: 'student-1',
            planService: planService,
            masteryService: masteryService,
          ),
        ));
        await tester.pumpAndSettle();

        final finder = find.byWidgetPredicate(
          (widget) => widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.green,
        );
        expect(finder, findsAtLeast(1));
      });
    });
  });
}
