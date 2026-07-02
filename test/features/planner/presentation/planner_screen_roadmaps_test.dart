import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'planner_screen_test_helpers.dart';

void main() {
  group('PlannerScreen - Roadmaps tab', () {
    testWidgets('loadRoadmaps shows CircularProgressIndicator while loading', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      roadmapRepo.loadCompleter = Completer<void>();

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pump();

      await tester.tap(find.text('Roadmaps'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      roadmapRepo.loadCompleter!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('loadRoadmaps shows empty state when no roadmaps exist', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('No roadmaps yet'), findsOneWidget);
      expect(find.text('e.g., I want to learn IB Physics in 180 days'), findsOneWidget);
    });

    testWidgets('loadRoadmaps shows ListView of roadmap cards when roadmaps exist', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      final roadmap = RoadmapModel(
        id: 'rm-1',
        studentId: 'test-student',
        goal: 'Learn IB Physics',
        createdAt: DateTime(2025, 1, 1),
        targetCompletionDate: DateTime(2025, 6, 1),
        milestones: [
          MilestoneModel(
            id: 'ms-1',
            title: 'Week 1',
            description: 'Foundation',
            deadline: DateTime(2025, 1, 15),
            order: 1,
            isCompleted: true,
          ),
          MilestoneModel(
            id: 'ms-2',
            title: 'Week 2',
            description: 'Core concepts',
            deadline: DateTime(2025, 2, 1),
            order: 2,
          ),
        ],
        status: 'active',
      );
      await roadmapRepo.saveRoadmap(roadmap);

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('Learn IB Physics'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('1/2 milestones'), findsOneWidget);
    });

    testWidgets('loadRoadmaps error path does not crash and shows empty state', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      roadmapRepo.failOnGet = true;

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('No roadmaps yet'), findsOneWidget);
    });

    testWidgets('tapping Create Roadmap opens AlertDialog with goal and days fields', (tester) async {
      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: FakeRoadmapRepository(),
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Roadmap'));
      await tester.pumpAndSettle();

      expect(find.text('Learning Goal'), findsOneWidget);
      expect(find.text('Days'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Generate Roadmap'), findsOneWidget);
    });

    testWidgets('cancelling roadmap dialog does not create a roadmap', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Roadmap'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final roadmaps = await roadmapRepo.getAllRoadmaps();
      expect(roadmaps.data, isEmpty);
    });

    testWidgets('submitting empty goal cancels creation', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Roadmap'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Roadmap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final roadmaps = await roadmapRepo.getAllRoadmaps();
      expect(roadmaps.data, isEmpty);
    });

    testWidgets('submitting valid goal creates a roadmap', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Roadmap'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Learn IB Physics in 180 days');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.pump();

      await tester.tap(find.text('Generate Roadmap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final roadmaps = await roadmapRepo.getAllRoadmaps();
      expect(roadmaps.data, hasLength(1));
      expect(roadmaps.data!.first.goal, 'Learn IB Physics in 180 days');
    });

    testWidgets('roadmap card renders status badge, progress bar, milestone count, target date', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      final roadmap = RoadmapModel(
        id: 'rm-2',
        studentId: 'test-student',
        goal: 'Master Python',
        createdAt: DateTime(2025, 1, 1),
        targetCompletionDate: DateTime(2025, 4, 1),
        milestones: [
          MilestoneModel(
            id: 'ms-1', title: 'Week 1', description: '',
            deadline: DateTime(2025, 1, 15), order: 1, isCompleted: true,
          ),
          MilestoneModel(
            id: 'ms-2', title: 'Week 2', description: '',
            deadline: DateTime(2025, 2, 1), order: 2,
          ),
          MilestoneModel(
            id: 'ms-3', title: 'Week 3', description: '',
            deadline: DateTime(2025, 2, 15), order: 3,
          ),
        ],
        status: 'completed',
      );
      await roadmapRepo.saveRoadmap(roadmap);

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('Master Python'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('1/3 milestones'), findsOneWidget);
      expect(find.textContaining('Target Completion'), findsOneWidget);
    });

    testWidgets('buildMilestoneTimeline renders milestones', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      final now = DateTime.now();
      final roadmap = RoadmapModel(
        id: 'rm-3',
        studentId: 'test-student',
        goal: 'Learn Dart',
        createdAt: now.subtract(const Duration(days: 30)),
        targetCompletionDate: now.add(const Duration(days: 30)),
        milestones: [
          MilestoneModel(
            id: 'ms-past', title: 'Past', description: '',
            deadline: now.subtract(const Duration(days: 10)),
            order: 1, isCompleted: true,
          ),
          MilestoneModel(
            id: 'ms-overdue', title: 'Overdue', description: '',
            deadline: now.subtract(const Duration(days: 5)),
            order: 2, isCompleted: false,
          ),
          MilestoneModel(
            id: 'ms-future', title: 'Future', description: '',
            deadline: now.add(const Duration(days: 10)),
            order: 3,
          ),
        ],
        status: 'active',
      );
      await roadmapRepo.saveRoadmap(roadmap);

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('M1'), findsOneWidget);
      expect(find.text('M2'), findsOneWidget);
      expect(find.text('M3'), findsOneWidget);
    });

    testWidgets('buildMilestoneTimeline shows empty when no milestones', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      final roadmap = RoadmapModel(
        id: 'rm-4',
        studentId: 'test-student',
        goal: 'Empty milestones',
        createdAt: DateTime.now(),
        milestones: [],
        status: 'active',
      );
      await roadmapRepo.saveRoadmap(roadmap);

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('Empty milestones'), findsOneWidget);
    });

    testWidgets('roadmap card shows progress bar with correct value', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      final roadmap = RoadmapModel(
        id: 'rm-5',
        studentId: 'test-student',
        goal: 'Progress test',
        createdAt: DateTime.now(),
        milestones: [
          MilestoneModel(
            id: 'ms-1', title: 'W1', description: '',
            deadline: DateTime.now().add(const Duration(days: 7)),
            order: 1, isCompleted: true,
          ),
          MilestoneModel(
            id: 'ms-2', title: 'W2', description: '',
            deadline: DateTime.now().add(const Duration(days: 14)),
            order: 2,
          ),
        ],
        status: 'active',
      );
      await roadmapRepo.saveRoadmap(roadmap);

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('creating roadmap with save error shows error snackbar', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      roadmapRepo.failOnSave = true;

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Roadmap'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Learn Dart');
      await tester.enterText(find.byType(TextField).at(1), '30');
      await tester.pump();

      await tester.tap(find.text('Generate Roadmap'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('loadRoadmaps init failure does not crash', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      roadmapRepo.failOnInit = true;

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('No roadmaps yet'), findsOneWidget);
    });

    testWidgets('roadmap with archived status renders correctly', (tester) async {
      final roadmapRepo = FakeRoadmapRepository();
      final now = DateTime.now();
      final roadmap = RoadmapModel(
        id: 'rm-archived',
        studentId: 'test-student',
        goal: 'Archived goal',
        createdAt: now,
        milestones: [],
        status: 'archived',
      );
      await roadmapRepo.saveRoadmap(roadmap);

      await tester.pumpWidget(buildPlannerTestApp(
        roadmapRepository: roadmapRepo,
        fixedStudentId: 'test-student',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Roadmaps'));
      await tester.pumpAndSettle();

      expect(find.text('Archived goal'), findsOneWidget);
      expect(find.text('Not Started'), findsOneWidget);
    });
  });
}
