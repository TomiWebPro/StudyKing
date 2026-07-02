import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'planner_screen_test_helpers.dart';
import '../../../helpers/navigator_observer_helper.dart';

void main() {
  group('PlannerScreen - Study Plan tab', () {
    testWidgets('renders title and form fields', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsWidgets);
      expect(find.text('Create Study Plan'), findsOneWidget);
      expect(find.text('Generate Plan'), findsOneWidget);
    });

    testWidgets('shows three input fields', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('shows calendar icon on generate button', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('generate button is enabled initially', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows snackbar when fields are empty on generate', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('days field uses number keyboard type', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, 3);

      final daysField = textFields[1];
      expect(daysField.keyboardType, TextInputType.number);

      final hoursField = textFields[2];
      expect(hoursField.keyboardType, TextInputType.number);
    });

    testWidgets('no schedule list shown initially', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsNothing);
    });

    testWidgets('form fields accept user input', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields[0].controller?.text, 'IB Physics');
      expect(textFields[1].controller?.text, '30');
      expect(textFields[2].controller?.text, '2');
    });

    testWidgets('generate plan with valid data shows schedule and summary', (tester) async {
      final planRepo = FakePlanRepository();
      final masteryRepo = FakeMasteryGraphRepository();
      final topicRepo = FakeTopicRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: masteryRepo,
        topicRepository: topicRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsNothing);
      expect(find.text('Plan Summary'), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();

      expect(find.text('Your Study Schedule'), findsOneWidget);
      expect(find.text('Plan Summary'), findsOneWidget);
    });

    testWidgets('plan summary displays plan stats after generation', (tester) async {
      final planRepo = FakePlanRepository();
      final masteryRepo = FakeMasteryGraphRepository();
      final topicRepo = FakeTopicRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: masteryRepo,
        topicRepository: topicRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('450Q'), findsOneWidget);
      expect(find.text('3600 min'), findsOneWidget);

      final plan = await planRepo.getAllPlans();
      expect(plan.data, hasLength(1));
      expect(plan.data!.first.studentId, 'test-student');
    });

    testWidgets('shows error container when plan generation fails', (tester) async {
      final masteryRepo = FakeMasteryGraphRepository();
      masteryRepo.failOnGenerate = true;

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: masteryRepo,
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('generate button shows progress indicator during generation', (tester) async {
      final masteryRepo = FakeMasteryGraphRepository();
      masteryRepo.generateCompleter = Completer<Result<List<MasteryState>>>();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: masteryRepo,
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      masteryRepo.generateCompleter!.complete(Result.success([]));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('Your Study Schedule'), findsOneWidget);
    });

    testWidgets('generate button is disabled while generating', (tester) async {
      final masteryRepo = FakeMasteryGraphRepository();
      masteryRepo.generateCompleter = Completer<Result<List<MasteryState>>>();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: masteryRepo,
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      masteryRepo.generateCompleter!.complete(Result.success([]));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final buttonAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('shows Generating text during generation', (tester) async {
      final masteryRepo = FakeMasteryGraphRepository();
      masteryRepo.generateCompleter = Completer<Result<List<MasteryState>>>();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: masteryRepo,
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();

      expect(find.text('Generating...'), findsOneWidget);

      masteryRepo.generateCompleter!.complete(Result.success([]));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Generating...'), findsNothing);
      expect(find.text('Generate Plan'), findsOneWidget);
    });

    testWidgets('loads existing plan from repository on init', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 50,
          totalMinutes: 1200,
          newTopics: 3,
          reviewTopics: 5,
          estimatedCoverage: 0.6,
          focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 120.0,
        targetQuestionsPerDay: 15,
      );
      await planRepo.savePlan(existingPlan);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsOneWidget);
      expect(find.text('Plan Summary'), findsOneWidget);
      expect(find.text('50Q'), findsOneWidget);
      expect(find.text('1200 min'), findsOneWidget);
    });

    testWidgets('shows no plan when loadPlan returns null', (tester) async {
      final planRepo = FakePlanRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsNothing);
      expect(find.text('Plan Summary'), findsNothing);
    });

    testWidgets('loadExistingPlan silent catch does not crash when repository throws', (tester) async {
      final planRepo = FakePlanRepository();
      planRepo.failOnInit = true;

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Your Study Schedule'), findsNothing);
      expect(find.text('Create Study Plan'), findsOneWidget);
    });

    testWidgets('planRepo.init failure in initState does not crash the screen', (tester) async {
      final planRepo = FakePlanRepository();
      planRepo.failOnInit = true;

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsWidgets);
      expect(find.text('Create Study Plan'), findsOneWidget);
    });

    testWidgets('generate plan validates zero days', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('generate plan validates negative hours', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '-1');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('generate plan validates empty course name', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('generate plan validates non-numeric input', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: FakePlanRepository(),
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), 'abc');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('openTutorMode triggers navigation when topic ID is non-empty', (tester) async {
      final planRepo = FakePlanRepository();
      final observer = TestNavigatorObserver();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [
          DailyPlan(
            dayNumber: 1,
            date: DateTime.now(),
            priorityTopics: [
              PlannedTopic(
                topicId: 'topic-1',
                topicTitle: 'Kinematics',
                priority: 1.0,
                reason: 'Weak area',
                readinessScore: 0.3,
                reviewUrgency: 0.8,
                estimatedQuestions: 10,
                estimatedMinutes: 60,
                reasons: ['Weak area'],
              ),
            ],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 10,
            targetMinutes: 60,
            focus: 'Study day',
            isRestDay: false,
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 10,
          totalMinutes: 60,
          newTopics: 1,
          reviewTopics: 0,
          estimatedCoverage: 0.1,
          focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 1,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
        navigatorObserver: observer,
        onGenerateRoute: (settings) {
          if (settings.name == '/tutor') {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Tutor Screen')),
            );
          }
          return null;
        },
      ));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsWidgets);

      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Tutor Screen'), findsOneWidget);
    });

    testWidgets('responsive layout shows side-by-side fields on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, 3);
      expect(textFields[1].controller, isNotNull);
      expect(textFields[2].controller, isNotNull);
    });

    testWidgets('generate plan handles repository init failure during generation', (tester) async {
      final planRepo = FakePlanRepository();
      planRepo.failOnInit = true;

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('plan summary shows focus areas when present', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0,
          totalMinutes: 0,
          newTopics: 0,
          reviewTopics: 0,
          estimatedCoverage: 0,
          focusAreas: ['Math', 'Physics'],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 120.0,
        targetQuestionsPerDay: 15,
      );
      await planRepo.savePlan(existingPlan);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Focus: Math, Physics'), findsOneWidget);
    });

    testWidgets('plan with rest day shows rest chip', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [
          DailyPlan(
            dayNumber: 1,
            date: DateTime.now(),
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
        targetMinutesPerDay: 0,
        targetQuestionsPerDay: 0,
      );
      await planRepo.savePlan(existingPlan);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Rest'), findsOneWidget);
    });

    testWidgets('planned topic with empty topicId does not show tutor button', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [
          DailyPlan(
            dayNumber: 1,
            date: DateTime.now(),
            priorityTopics: [
              PlannedTopic(
                topicId: '',
                topicTitle: 'Empty Topic',
                priority: 1.0,
                reason: 'Test',
                readinessScore: 0.5,
                reviewUrgency: 0.3,
                estimatedQuestions: 5,
                estimatedMinutes: 30,
                reasons: ['Test'],
              ),
            ],
            reviewQuestionIds: [],
            stretchGoalQuestionIds: [],
            targetQuestions: 5,
            targetMinutes: 30,
            isRestDay: false,
          ),
        ],
        summary: PlanSummary(
          totalQuestions: 5,
          totalMinutes: 30,
          newTopics: 1,
          reviewTopics: 0,
          estimatedCoverage: 0.1,
          focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 1,
        targetMinutesPerDay: 30.0,
        targetQuestionsPerDay: 5,
      );
      await planRepo.savePlan(existingPlan);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        masteryGraphRepository: FakeMasteryGraphRepository(),
        topicRepository: FakeTopicRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);
    });
  });
}
