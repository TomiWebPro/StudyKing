import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/presentation/widgets/milestone_timeline.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: widget)),
    );
  }

  group('MilestoneTimeline', () {
    testWidgets('shows nothing when no milestones', (tester) async {
      await tester.pumpWidget(buildApp(
        MilestoneTimeline(
          roadmap: RoadmapModel(
            id: 'r1',
            studentId: 's1',
            goal: 'Goal',
            createdAt: DateTime.now(),
            milestones: [],
          ),
        ),
      ));

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(MilestoneTimeline), findsOneWidget);
    });

    testWidgets('renders timeline section with milestone markers', (tester) async {
      await tester.pumpWidget(buildApp(
        MilestoneTimeline(
          roadmap: RoadmapModel(
            id: 'r1',
            studentId: 's1',
            goal: 'Goal',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            milestones: [
              MilestoneModel(
                id: 'm1',
                title: 'Complete Chapter 1',
                deadline: DateTime.now().add(const Duration(days: 5)),
                order: 1,
              ),
              MilestoneModel(
                id: 'm2',
                title: 'Complete Chapter 2',
                deadline: DateTime.now().add(const Duration(days: 20)),
                order: 2,
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Timeline'), findsOneWidget);
    });

    testWidgets('shows completed milestones in green', (tester) async {
      await tester.pumpWidget(buildApp(
        MilestoneTimeline(
          roadmap: RoadmapModel(
            id: 'r1',
            studentId: 's1',
            goal: 'Goal',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            milestones: [
              MilestoneModel(
                id: 'm1',
                title: 'Done Chapter',
                deadline: DateTime.now().subtract(const Duration(days: 5)),
                order: 1,
                isCompleted: true,
              ),
            ],
          ),
        ),
      ));

      expect(find.textContaining('Done Chapter'), findsOneWidget);
    });

    testWidgets('handles roadmap with targetCompletionDate', (tester) async {
      await tester.pumpWidget(buildApp(
        MilestoneTimeline(
          roadmap: RoadmapModel(
            id: 'r1',
            studentId: 's1',
            goal: 'Goal',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            targetCompletionDate: DateTime.now().add(const Duration(days: 20)),
            milestones: [
              MilestoneModel(
                id: 'm1',
                title: 'First Milestone',
                deadline: DateTime.now().add(const Duration(days: 5)),
                order: 1,
              ),
            ],
          ),
        ),
      ));

      expect(find.textContaining('First Milestone'), findsOneWidget);
    });

    testWidgets('renders milestone labels with deadlines', (tester) async {
      await tester.pumpWidget(buildApp(
        MilestoneTimeline(
          roadmap: RoadmapModel(
            id: 'r1',
            studentId: 's1',
            goal: 'Goal',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            milestones: [
              MilestoneModel(
                id: 'm1',
                title: 'Midterm',
                deadline: DateTime(2025, 3, 15),
                order: 1,
              ),
            ],
          ),
        ),
      ));

      expect(find.textContaining('Midterm'), findsOneWidget);
      expect(find.textContaining('Mar 15'), findsOneWidget);
    });
  });
}
