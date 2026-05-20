import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/presentation/widgets/syllabus_progress_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  late String hivePath;

  setUpAll(() {
    hivePath = Directory.systemTemp.createTempSync('syllabus_progress_card_test_').path;
    Hive.init(hivePath);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await Directory(hivePath).delete(recursive: true);
    } catch (_) {}
  });

  final goal = SyllabusGoal(
    subjectId: 'math-101',
    subjectTitle: 'Mathematics',
  );

  Widget buildApp(Widget widget) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    );
  }

  group('SyllabusProgressCard', () {
    testWidgets('shows loading state when no overrides provided', (tester) async {
      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
          masteryStatesOverride: [],
          totalTopicsOverride: 0,
        ),
      ));

      expect(find.textContaining('0 / 0'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows 0% progress when nothing mastered', (tester) async {
      final now = DateTime.now();
      final states = [
        MasteryState(
          studentId: 'student-1',
          topicId: 'topic-1',
          masteryLevel: MasteryLevel.novice,
          lastAttempt: now,
          lastUpdated: now,
        ),
        MasteryState(
          studentId: 'student-1',
          topicId: 'topic-2',
          masteryLevel: MasteryLevel.browsing,
          lastAttempt: now,
          lastUpdated: now,
        ),
      ];

      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
          masteryStatesOverride: states,
          totalTopicsOverride: 2,
        ),
      ));

      expect(find.textContaining('0 / 2'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows partial progress when some topics mastered', (tester) async {
      final now = DateTime.now();
      final states = [
        MasteryState(
          studentId: 'student-1',
          topicId: 'topic-1',
          masteryLevel: MasteryLevel.proficient,
          lastAttempt: now,
          lastUpdated: now,
        ),
        MasteryState(
          studentId: 'student-1',
          topicId: 'topic-2',
          masteryLevel: MasteryLevel.novice,
          lastAttempt: now,
          lastUpdated: now,
        ),
        MasteryState(
          studentId: 'student-1',
          topicId: 'topic-3',
          masteryLevel: MasteryLevel.expert,
          lastAttempt: now,
          lastUpdated: now,
        ),
      ];

      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
          masteryStatesOverride: states,
          totalTopicsOverride: 10,
        ),
      ));

      expect(find.textContaining('2 / 10'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
    });

    testWidgets('shows 100% progress when all topics mastered', (tester) async {
      final now = DateTime.now();
      final states = List.generate(5, (i) => MasteryState(
        studentId: 'student-1',
        topicId: 'topic-$i',
        masteryLevel: MasteryLevel.proficient,
        lastAttempt: now,
        lastUpdated: now,
      ));

      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
          masteryStatesOverride: states,
          totalTopicsOverride: 5,
        ),
      ));

      expect(find.textContaining('5 / 5'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows subject title and syllabus label', (tester) async {
      final now = DateTime.now();
      final states = [
        MasteryState(
          studentId: 'student-1',
          topicId: 'topic-1',
          masteryLevel: MasteryLevel.novice,
          lastAttempt: now,
          lastUpdated: now,
        ),
      ];

      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
          masteryStatesOverride: states,
          totalTopicsOverride: 1,
        ),
      ));

      expect(find.text('Mathematics Syllabus'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });
  });
}
