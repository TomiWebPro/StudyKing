import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/services/personal_learning_plan_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/presentation/learning_plan_dashboard.dart';

class FakePersonalLearningPlanService extends PersonalLearningPlanService {
  final PersonalLearningPlan? plan;
  final List<String> atRiskIds;
  final List<String> readyToAdvanceIds;

  FakePersonalLearningPlanService({
    this.plan,
    this.atRiskIds = const [],
    this.readyToAdvanceIds = const [],
  });

  @override
  Future<Result<PersonalLearningPlan>> generatePlan(String studentId) async {
    if (plan == null) return Result.failure('No plan');
    return Result.success(plan!);
  }

  @override
  Future<Result<List<String>>> getAtRiskTopicIds(String studentId) async {
    return Result.success(atRiskIds);
  }

  @override
  Future<Result<List<String>>> getReadyToAdvanceTopicIds(String studentId) async {
    return Result.success(readyToAdvanceIds);
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> weakTopics;
  final Map<String, dynamic>? snapshot;

  FakeMasteryGraphService({this.weakTopics = const [], this.snapshot});

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(weakTopics);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
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
  return MaterialApp(home: Scaffold(body: dashboard));
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

    testWidgets('shows empty state for today plan when no plan', (tester) async {
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

      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('No study plan for today'), findsOneWidget);
    });

    testWidgets('shows today plan with focus chip', (tester) async {
      final plan = PersonalLearningPlan(
        studentId: 'student-1',
        generatedAt: DateTime.now(),
        dailyPlans: [
          DailyPlan(
            date: DateTime.now(),
            dayNumber: 1,
            focus: 'Algebra Review',
            targetQuestions: 10,
            targetMinutes: 30,
            priorityTopics: [
              PlannedTopic(
                topicId: 'topic-1',
                topicTitle: 'Algebra',
                priority: 2.0,
                reason: 'Needs review',
                readinessScore: 0.5,
                reviewUrgency: 0.8,
                estimatedQuestions: 5,
                estimatedMinutes: 20,
                reasons: ['Needs review'],
              ),
            ],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            isRestDay: false,
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 10,
          totalMinutes: 30,
          newTopics: 1,
          reviewTopics: 1,
          estimatedCoverage: 0.5,
          focusAreas: ['Algebra'],
        ),
        recommendations: [],
      );
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

      expect(find.text("Today's Plan"), findsOneWidget);
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

      expect(find.text('At Risk Topics'), findsOneWidget);
      expect(find.text('Accuracy: 30%'), findsOneWidget);
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

      expect(find.text('Ready to Advance'), findsOneWidget);
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

      expect(find.text('Mastery Overview'), findsOneWidget);
      expect(find.text('Total Topics'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('Weak'), findsOneWidget);
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

      expect(
        find.text('No at-risk topics. Keep up the good work!'),
        findsOneWidget,
      );
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

      expect(
        find.text('Keep practicing to unlock advanced topics!'),
        findsOneWidget,
      );
    });

    testWidgets('shows rest day content', (tester) async {
      final plan = PersonalLearningPlan(
        studentId: 'student-1',
        generatedAt: DateTime.now(),
        dailyPlans: [
          DailyPlan(
            date: DateTime.now(),
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
          estimatedCoverage: 0.0,
          focusAreas: [],
        ),
        recommendations: [],
      );
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

      expect(find.text('No study plan for today'), findsOneWidget);
    });
  });
}
