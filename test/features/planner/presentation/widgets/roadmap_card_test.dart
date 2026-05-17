import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/presentation/widgets/roadmap_card.dart';
import 'package:studyking/features/planner/presentation/widgets/milestone_timeline.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('roadmap_card_test_').path);
  });

  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: widget)),
    );
  }

  RoadmapModel roadmap({
    String status = 'active',
    double completion = 30.0,
    List<MilestoneModel> milestones = const [],
    DateTime? targetDate,
  }) {
    return RoadmapModel(
      id: 'roadmap-1',
      studentId: 'student-1',
      goal: 'Master IB Physics',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      targetCompletionDate: targetDate,
      milestones: milestones,
      completionPercentage: completion,
      status: status,
    );
  }

  MilestoneModel milestone({
    String id = 'm1',
    String title = 'Milestone 1',
    bool isCompleted = false,
    int order = 1,
  }) {
    return MilestoneModel(
      id: id,
      title: title,
      deadline: DateTime.now().add(Duration(days: 30 * order)),
      isCompleted: isCompleted,
      order: order,
      topicsCovered: ['topic-1'],
    );
  }

  group('RoadmapCard', () {
    testWidgets('renders goal and status badge', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap()),
      ));

      expect(find.text('Master IB Physics'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('shows progress bar and percentage', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(completion: 50.0)),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('50'), findsOneWidget);
    });

    testWidgets('shows milestone count', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(
          milestones: [
            milestone(),
            milestone(id: 'm2', title: 'Milestone 2'),
          ],
        )),
      ));

      expect(find.textContaining('Milestones'), findsOneWidget);
      expect(find.textContaining('2 Milestones'), findsOneWidget);
    });

    testWidgets('shows completed milestones', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(
          roadmap: roadmap(milestones: [
            milestone(isCompleted: true),
          ]),
          onToggleMilestone: (_, __, ___) {},
        ),
      ));

      expect(find.text('Milestone 1'), findsOneWidget);
    });

    testWidgets('target completion date is shown', (tester) async {
      final targetDate = DateTime(2025, 6, 15);
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(targetDate: targetDate)),
      ));

      expect(find.textContaining('Target Completion'), findsOneWidget);
    });

    testWidgets('shows MilestoneTimeline widget', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(milestones: [milestone()])),
      ));

      expect(find.byType(MilestoneTimeline), findsOneWidget);
    });

    testWidgets('onToggleMilestone callback works', (tester) async {
      String? capturedRoadmapId;
      String? capturedMilestoneId;
      bool? capturedValue;

      await tester.pumpWidget(buildApp(
        RoadmapCard(
          roadmap: roadmap(milestones: [milestone(isCompleted: false)]),
          onToggleMilestone: (rId, mId, val) {
            capturedRoadmapId = rId;
            capturedMilestoneId = mId;
            capturedValue = val;
          },
        ),
      ));

      await tester.tap(find.byType(CheckboxListTile));
      expect(capturedRoadmapId, 'roadmap-1');
      expect(capturedMilestoneId, 'm1');
      expect(capturedValue, isTrue);
    });

    testWidgets('completed milestone checkbox is disabled', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(
          roadmap: roadmap(milestones: [milestone(isCompleted: true)]),
          onToggleMilestone: (_, __, ___) {},
        ),
      ));

      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.onChanged, isNull);
    });

    testWidgets('shows completed status', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(status: 'completed')),
      ));

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows not_started status fallback', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(status: 'not_started')),
      ));

      expect(find.text('Not Started'), findsOneWidget);
    });

    testWidgets('uses completionPercentage when milestones are empty', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(completion: 75.0, milestones: [])),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('75'), findsOneWidget);
      expect(find.textContaining('0/0'), findsOneWidget);
    });

    testWidgets('no checkboxes when onToggleMilestone is null', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(roadmap: roadmap(milestones: [milestone()])),
      ));

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(MilestoneTimeline), findsOneWidget);
    });

    testWidgets('shows milestone topic count subtitle', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(
          roadmap: roadmap(milestones: [milestone()]),
          onToggleMilestone: (_, __, ___) {},
        ),
      ));

      expect(find.textContaining('1 topic'), findsOneWidget);
    });

    testWidgets('divider shown between milestones and timeline', (tester) async {
      await tester.pumpWidget(buildApp(
        RoadmapCard(
          roadmap: roadmap(milestones: [milestone()]),
          onToggleMilestone: (_, __, ___) {},
        ),
      ));

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
