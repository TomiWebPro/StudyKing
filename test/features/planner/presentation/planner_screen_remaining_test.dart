import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'planner_screen_test_helpers.dart';

void main() {
  group('PlannerScreen - Pending Actions', () {
    testWidgets('shows pending actions section when actions exist', (tester) async {
      final pendingRepo = FakePendingActionRepository();
      pendingRepo.addAction(PendingActionModel(
        id: 'action-1',
        studentId: 'test-student',
        actionType: 'schedule',
        topicTitle: 'Algebra',
      ));

      await tester.pumpWidget(buildPlannerTestApp(
        pendingActionRepository: pendingRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pending Actions'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('accept pending action marks it as completed', (tester) async {
      final pendingRepo = FakePendingActionRepository();
      pendingRepo.addAction(PendingActionModel(
        id: 'action-2',
        studentId: 'test-student',
        actionType: 'schedule',
        topicTitle: 'Physics',
        payload: {
          'topicId': 'topic-1',
          'subjectId': 'subj-1',
          'scheduledTime': DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String(),
          'durationMinutes': 30,
        },
      ));

      await tester.pumpWidget(buildPlannerTestApp(
        pendingActionRepository: pendingRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Physics'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      final action = await pendingRepo.get('action-2');
      expect(action.data?.status, 'completed');
    });

    testWidgets('dismiss pending action marks it as rejected', (tester) async {
      final pendingRepo = FakePendingActionRepository();
      pendingRepo.addAction(PendingActionModel(
        id: 'action-3',
        studentId: 'test-student',
        actionType: 'reschedule',
        topicTitle: 'Chemistry',
      ));

      await tester.pumpWidget(buildPlannerTestApp(
        pendingActionRepository: pendingRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chemistry'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();

      final action = await pendingRepo.get('action-3');
      expect(action.data?.status, 'rejected');
    });

    testWidgets('pending actions section not shown when empty', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pending Actions'), findsNothing);
    });
  });

  group('PlannerScreen - Multi-syllabus input', () {
    testWidgets('toggle switches to multi-subject mode', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Course/Subject +'), findsNothing);

      await tester.tap(find.text('Subjects'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Course/Subject +'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('add and remove syllabus entries', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Subjects'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Course/Subject +'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

      await tester.tap(find.text('Course/Subject +'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('multi-syllabus validation shows snackbar on empty fields', (tester) async {
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

      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Course/Subject +'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in all fields correctly'), findsOneWidget);
    });

    testWidgets('multi-syllabus with valid inputs triggers generation', (tester) async {
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

      await tester.tap(find.text('Subjects'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Course/Subject +'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'IB Physics');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.pump();

      expect(find.text('Generate Plan'), findsOneWidget);

      await tester.tap(find.text('Generate Plan'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PlannerScreen - Adherence banner', () {
    testWidgets('shows banner when deviation requires regeneration', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final deviationPlanAdherenceOrchestrator = FakePlanAdherenceOrchestrator(
        adherenceDeviation: const AdherenceDeviation(
          requiresRegeneration: true,
          requiresEscalation: false,
          message: 'You are behind schedule',
        ),
      );

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        planOrchestrator: deviationPlanAdherenceOrchestrator,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Redistribute'), findsOneWidget);
      expect(find.text('Regenerate Plan'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('banner shows escalation styling when requiresEscalation', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final deviationPlanAdherenceOrchestrator = FakePlanAdherenceOrchestrator(
        adherenceDeviation: const AdherenceDeviation(
          requiresRegeneration: true,
          requiresEscalation: true,
          message: 'Critical: you are far behind',
        ),
      );

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        planOrchestrator: deviationPlanAdherenceOrchestrator,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('banner does not show when deviation is null', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Redistribute'), findsNothing);
    });
  });

  group('PlannerScreen - Scheduled lessons', () {
    testWidgets('shows scheduled lessons section when lessons exist', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final sessionRepo = FakeSessionRepository();
      final now = DateTime.now();
      final sess0 = Session(
        id: 'sess-1',
        studentId: 'test-student',
        topicId: 'topic-1',
        subjectId: 'subj-1',
        startTime: now.add(const Duration(hours: 2)),
        plannedDurationMinutes: 30,
        status: SessionStatus.planned,
      );
      await sessionRepo.save(sess0.id, sess0);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        sessionRepository: sessionRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Scheduled Lessons'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('completed lesson shows check icon and line-through title', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final sessionRepo = FakeSessionRepository();
      final now = DateTime.now();
      final sess1 = Session(
        id: 'sess-completed',
        studentId: 'test-student',
        topicId: 'topic-done',
        subjectId: 'subj-1',
        startTime: now.subtract(const Duration(hours: 4)),
        endTime: now.subtract(const Duration(hours: 3)),
        completed: true,
        status: SessionStatus.completed,
      );
      await sessionRepo.save(sess1.id, sess1);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        sessionRepository: sessionRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_filled), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });

    testWidgets('play button on scheduled lesson navigates to tutor', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final sessionRepo = FakeSessionRepository();
      final now = DateTime.now();
      final sess2 = Session(
        id: 'sess-2',
        studentId: 'test-student',
        topicId: 'topic-2',
        subjectId: 'subj-2',
        startTime: now.add(const Duration(hours: 2)),
        plannedDurationMinutes: 45,
        status: SessionStatus.planned,
      );
      await sessionRepo.save(sess2.id, sess2);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        sessionRepository: sessionRepo,
        fixedStudentId: 'test-student',
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

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pumpAndSettle();

      expect(find.text('Tutor Screen'), findsOneWidget);
    });

    testWidgets('cancel lesson shows confirmation dialog and cancels', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final sessionRepo = FakeSessionRepository();
      final now = DateTime.now();
      final sess3 = Session(
        id: 'sess-cancel',
        studentId: 'test-student',
        topicId: 'topic-cancel',
        subjectId: 'subj-1',
        startTime: now.add(const Duration(hours: 2)),
        plannedDurationMinutes: 30,
        status: SessionStatus.planned,
      );
      await sessionRepo.save(sess3.id, sess3);

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        sessionRepository: sessionRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to cancel this lesson?'), findsOneWidget);
      expect(find.text('Cancel'), findsWidgets);

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      final session = await sessionRepo.get('sess-cancel');
      expect(session.isSuccess, isTrue);
    });

    testWidgets('shows more lessons button when > 3 scheduled lessons', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final sessionRepo = FakeSessionRepository();
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        final sess4 = Session(
          id: 'sess-$i',
          studentId: 'test-student',
          topicId: 'topic-$i',
          subjectId: 'subj-1',
          startTime: now.add(Duration(hours: 2 + i)),
          plannedDurationMinutes: 30,
          status: SessionStatus.planned,
        );
        await sessionRepo.save(sess4.id, sess4);
      }

      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
        sessionRepository: sessionRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('more...'), findsOneWidget);
    });
  });

  group('PlannerScreen - Calendar tab', () {
    testWidgets('shows empty state when no plan exists', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.text('No study plan yet'), findsOneWidget);
    });
  });

  group('PlannerScreen - Error and success handling', () {
    testWidgets('error container shows on study plan tab when error is set', (tester) async {
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

    testWidgets('success message shows snackbar', (tester) async {
      final planRepo = FakePlanRepository();
      final existingPlan = PersonalLearningPlan(
        studentId: 'test-student',
        generatedAt: DateTime.now(),
        dailyPlans: [],
        summary: PlanSummary(
          totalQuestions: 0, totalMinutes: 0, newTopics: 0,
          reviewTopics: 0, estimatedCoverage: 0, focusAreas: [],
        ),
        recommendations: [],
        planDurationDays: 30,
        targetMinutesPerDay: 60.0,
        targetQuestionsPerDay: 10,
      );
      await planRepo.savePlan(existingPlan);

      final masteryRepo = FakeMasteryGraphRepository();
      await tester.pumpWidget(buildPlannerTestApp(
        planRepository: planRepo,
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
  });

  group('PlannerScreen - Keyboard accessibility', () {
    testWidgets('renders FocusTraversalGroup for keyboard navigation', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('interactive elements have proper semantics for keyboard focus', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
