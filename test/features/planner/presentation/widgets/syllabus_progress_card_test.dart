import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/practice/data/adapters/mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/adapters/question_mastery_state_adapter.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/presentation/widgets/syllabus_progress_card.dart';
import 'package:studyking/features/questions/data/adapters/question_evaluation_adapter.dart';
import 'package:studyking/features/subjects/data/adapters/topic_adapter.dart';
import 'package:studyking/features/subjects/data/adapters/topic_dependency_adapter.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void main() {
  final goal = SyllabusGoal(
    subjectId: 'math-101',
    subjectTitle: 'Mathematics',
  );

  Widget buildApp(Widget widget, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: widget),
    );
  }

  // Seed the Hive boxes before ANY test runs. The card's _loadProgress
  // opens the topics/mastery boxes directly, and opening a Hive box
  // before its type adapter is registered hangs the tester process (and
  // deadlocks every later openBox of the same box via Hive's internal
  // opening-box lock). Registering adapters and opening the boxes up
  // front keeps every test on the fast path.
  setUpAll(() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TopicAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(MasteryStateAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(QuestionMasteryStateAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(TopicDependencyAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(QuestionEvaluationAdapter());
    }

    final topicRepo = TopicRepository();
    await topicRepo.init();
    for (final topic in _seedTopics()) {
      final existing = await topicRepo.get(topic.id);
      if (existing.data == null) {
        await topicRepo.create(topic);
      }
    }

    final masteryRepo = MasteryGraphRepository();
    await masteryRepo.init();
    for (final state in _seedMasteryStates()) {
      await masteryRepo.updateMasteryState(state);
    }
  });

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

      expect(find.text('No progress yet'), findsOneWidget);
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

      expect(find.text('No progress yet'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('localizes the empty-progress text for the es locale',
        (tester) async {
      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
          masteryStatesOverride: [],
          totalTopicsOverride: 2,
        ),
        locale: const Locale('es'),
      ));

      expect(find.text('Sin progreso aún'), findsOneWidget);
      expect(
        find.text(
          'Aún no has practicado Mathematics. '
          'Empieza subiendo materiales o programando una lección.',
        ),
        findsOneWidget,
      );
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

  group('SyllabusProgressCard._loadProgress subject scoping', () {
    testWidgets(
        'counts only this subject\'s mastered topics so progress never exceeds 100%',
        (tester) async {
      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: goal,
        ),
      ));
      await tester.pumpAndSettle();

      // Math has 2 topics, 1 of them proficient. The 2 proficient
      // physics topics must not be counted against math's total.
      expect(find.textContaining('1 / 2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.textContaining('3 / 2'), findsNothing);
      expect(find.text('150%'), findsNothing);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, lessThanOrEqualTo(1.0));
    });

    testWidgets('shows 100% when every topic of the subject is mastered',
        (tester) async {
      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-1',
          goal: const SyllabusGoal(
            subjectId: 'chem-101',
            subjectTitle: 'Chemistry',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / 1'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('does not count another student\'s mastery states',
        (tester) async {
      // student-2 has a proficient state on math-t2; the card is for
      // student-2, who only mastered math-t2 (not student-1's math-t1).
      await tester.pumpWidget(buildApp(
        SyllabusProgressCard(
          studentId: 'student-2',
          goal: goal,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 / 2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.textContaining('2 / 2'), findsNothing);
      expect(find.text('100%'), findsNothing);
    });
  });
}

List<Topic> _seedTopics() {
  return [
    Topic(
      id: 'math-t1',
      subjectId: 'math-101',
      title: 'Algebra',
      description: 'Algebra',
      syllabusText: '',
    ),
    Topic(
      id: 'math-t2',
      subjectId: 'math-101',
      title: 'Geometry',
      description: 'Geometry',
      syllabusText: '',
    ),
    Topic(
      id: 'phys-t1',
      subjectId: 'phys-101',
      title: 'Mechanics',
      description: 'Mechanics',
      syllabusText: '',
    ),
    Topic(
      id: 'phys-t2',
      subjectId: 'phys-101',
      title: 'Thermodynamics',
      description: 'Thermodynamics',
      syllabusText: '',
    ),
    Topic(
      id: 'phys-t3',
      subjectId: 'phys-101',
      title: 'Optics',
      description: 'Optics',
      syllabusText: '',
    ),
    Topic(
      id: 'chem-t1',
      subjectId: 'chem-101',
      title: 'Stoichiometry',
      description: 'Stoichiometry',
      syllabusText: '',
    ),
  ];
}

List<MasteryState> _seedMasteryStates() {
  final now = DateTime(2026, 5, 12);
  return [
    // student-1: one proficient math topic, two proficient physics topics,
    // one proficient chemistry topic.
    MasteryState(
      studentId: 'student-1',
      topicId: 'math-t1',
      masteryLevel: MasteryLevel.proficient,
      lastAttempt: now,
      lastUpdated: now,
    ),
    MasteryState(
      studentId: 'student-1',
      topicId: 'phys-t1',
      masteryLevel: MasteryLevel.proficient,
      lastAttempt: now,
      lastUpdated: now,
    ),
    MasteryState(
      studentId: 'student-1',
      topicId: 'phys-t2',
      masteryLevel: MasteryLevel.expert,
      lastAttempt: now,
      lastUpdated: now,
    ),
    MasteryState(
      studentId: 'student-1',
      topicId: 'chem-t1',
      masteryLevel: MasteryLevel.proficient,
      lastAttempt: now,
      lastUpdated: now,
    ),
    // student-2: proficient on a math topic (must stay scoped to student-2).
    MasteryState(
      studentId: 'student-2',
      topicId: 'math-t2',
      masteryLevel: MasteryLevel.proficient,
      lastAttempt: now,
      lastUpdated: now,
    ),
  ];
}
