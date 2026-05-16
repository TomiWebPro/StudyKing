import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/hive_box_names.dart';

void main() {
  group('HiveBoxNames', () {
    test('has all expected constants and they are non-empty', () {
      expect(HiveBoxNames.answers, equals('answers'));
      expect(HiveBoxNames.attempts, equals('attempts'));
      expect(HiveBoxNames.badges, equals('badges'));
      expect(HiveBoxNames.conversations, equals('conversations'));
      expect(HiveBoxNames.engagementNudges, equals('engagement_nudges'));
      expect(HiveBoxNames.focusSessions, equals('focus_sessions'));
      expect(HiveBoxNames.learningPlans, equals('learning_plans'));
      expect(HiveBoxNames.lessonBlocks, equals('lessonBlocks'));
      expect(HiveBoxNames.lessons, equals('lessons'));
      expect(HiveBoxNames.masteryStates, equals('mastery_states'));
      expect(HiveBoxNames.masteryImprovementMetrics, equals('mastery_improvement_metrics'));
      expect(HiveBoxNames.pendingActions, equals('pending_actions'));
      expect(HiveBoxNames.planAdherence, equals('plan_adherence'));
      expect(HiveBoxNames.planAdherenceMetrics, equals('plan_adherence_metrics'));
      expect(HiveBoxNames.progress, equals('progress'));
      expect(HiveBoxNames.questions, equals('questions'));
      expect(HiveBoxNames.questionMasteryStates, equals('question_mastery_states'));
      expect(HiveBoxNames.questionEvaluations, equals('question_evaluations'));
      expect(HiveBoxNames.roadmaps, equals('roadmaps'));
      expect(HiveBoxNames.sessions, equals('sessions'));
      expect(HiveBoxNames.settings, equals('settings'));
      expect(HiveBoxNames.profile, equals('profile'));
      expect(HiveBoxNames.sources, equals('sources'));
      expect(HiveBoxNames.subjects, equals('subjects'));
      expect(HiveBoxNames.tasks, equals('tasks'));
      expect(HiveBoxNames.topicDependencies, equals('topic_dependencies'));
      expect(HiveBoxNames.topics, equals('topics'));
      expect(HiveBoxNames.tutorSessions, equals('tutor_sessions'));
      expect(HiveBoxNames.studentAvailability, equals('student_availability'));
    });

    test('constructor is private', () {
      expect(HiveBoxNames, isA<Type>());
    });
  });
}
