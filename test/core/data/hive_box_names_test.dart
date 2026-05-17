import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/hive_box_names.dart';

void main() {
  group('HiveBoxNames', () {
    test('all box names are non-empty strings', () {
      expect(HiveBoxNames.answers, isNotEmpty);
      expect(HiveBoxNames.attempts, isNotEmpty);
      expect(HiveBoxNames.badges, isNotEmpty);
      expect(HiveBoxNames.conversations, isNotEmpty);
      expect(HiveBoxNames.engagementNudges, isNotEmpty);
      expect(HiveBoxNames.focusSessions, isNotEmpty);
      expect(HiveBoxNames.learningPlans, isNotEmpty);
      expect(HiveBoxNames.lessonBlocks, isNotEmpty);
      expect(HiveBoxNames.lessons, isNotEmpty);
      expect(HiveBoxNames.masteryStates, isNotEmpty);
      expect(HiveBoxNames.masteryImprovementMetrics, isNotEmpty);
      expect(HiveBoxNames.pendingActions, isNotEmpty);
      expect(HiveBoxNames.planAdherence, isNotEmpty);
      expect(HiveBoxNames.planAdherenceMetrics, isNotEmpty);
      expect(HiveBoxNames.progress, isNotEmpty);
      expect(HiveBoxNames.questions, isNotEmpty);
      expect(HiveBoxNames.questionMasteryStates, isNotEmpty);
      expect(HiveBoxNames.questionEvaluations, isNotEmpty);
      expect(HiveBoxNames.roadmaps, isNotEmpty);
      expect(HiveBoxNames.sessions, isNotEmpty);
      expect(HiveBoxNames.settings, isNotEmpty);
      expect(HiveBoxNames.profile, isNotEmpty);
      expect(HiveBoxNames.sources, isNotEmpty);
      expect(HiveBoxNames.subjects, isNotEmpty);
      expect(HiveBoxNames.tasks, isNotEmpty);
      expect(HiveBoxNames.topicDependencies, isNotEmpty);
      expect(HiveBoxNames.topics, isNotEmpty);
      expect(HiveBoxNames.tutorSessions, isNotEmpty);
      expect(HiveBoxNames.studentAvailability, isNotEmpty);
    });

    test('all box names contain only lowercase letters and underscores', () {
      final names = [
        HiveBoxNames.answers,
        HiveBoxNames.attempts,
        HiveBoxNames.badges,
        HiveBoxNames.conversations,
        HiveBoxNames.engagementNudges,
        HiveBoxNames.focusSessions,
        HiveBoxNames.learningPlans,
        HiveBoxNames.lessonBlocks,
        HiveBoxNames.lessons,
        HiveBoxNames.masteryStates,
        HiveBoxNames.masteryImprovementMetrics,
        HiveBoxNames.pendingActions,
        HiveBoxNames.planAdherence,
        HiveBoxNames.planAdherenceMetrics,
        HiveBoxNames.progress,
        HiveBoxNames.questions,
        HiveBoxNames.questionMasteryStates,
        HiveBoxNames.questionEvaluations,
        HiveBoxNames.roadmaps,
        HiveBoxNames.sessions,
        HiveBoxNames.settings,
        HiveBoxNames.profile,
        HiveBoxNames.sources,
        HiveBoxNames.subjects,
        HiveBoxNames.tasks,
        HiveBoxNames.topicDependencies,
        HiveBoxNames.topics,
        HiveBoxNames.tutorSessions,
        HiveBoxNames.studentAvailability,
      ];
      for (final name in names) {
        expect(name, matches(RegExp(r'^[a-z]+([A-Z][a-z]+)*(_[a-z]+)*$')));
      }
    });

    test('constructor is private', () {
      expect(HiveBoxNames, isA<Type>());
    });
  });
}
