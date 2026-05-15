import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

import 'database_migration.dart';
import 'hive_box_names.dart';
import 'package:studyking/features/questions/data/adapters/question_evaluation_adapter.dart';
import 'package:studyking/features/practice/data/adapters/mastery_state_adapter.dart';
import 'package:studyking/features/subjects/data/adapters/topic_dependency_adapter.dart';
import 'package:studyking/features/practice/data/adapters/question_mastery_state_adapter.dart';
import 'package:studyking/features/planner/data/adapters/personal_learning_plan_adapter.dart';
import 'package:studyking/features/questions/data/adapters/markscheme_adapter.dart';
import 'package:studyking/features/teaching/data/adapters/conversation_message_adapter.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_adapter.dart';
import 'package:studyking/features/practice/data/adapters/mastery_improvement_adapter.dart';
import 'models/question_evaluation_model.dart';
import 'models/mastery_state_model.dart';
import 'models/topic_dependency_model.dart';
import 'models/question_mastery_state_model.dart';
import 'models/personal_learning_plan_model.dart';
import 'models/student_attempt_model.dart';
import 'models/conversation_message_model.dart';
import 'models/tutor_session_model.dart';

class HiveInitializer {
  static final Logger _logger = const Logger('HiveInitializer');

  static Future<void> initialize() async {
    await DatabaseMigration.runMigrations();
    await _registerAdapters();

    await Hive.openBox<QuestionEvaluation>(HiveBoxNames.questionEvaluations);
    await Hive.openBox<MasteryState>(HiveBoxNames.masteryStates);
    await Hive.openBox<QuestionMasteryState>(HiveBoxNames.questionMasteryStates);
    await Hive.openBox<TopicDependency>(HiveBoxNames.topicDependencies);
    await Hive.openBox<PersonalLearningPlan>(HiveBoxNames.learningPlans);

    await Hive.openBox(HiveBoxNames.subjects);
    await Hive.openBox(HiveBoxNames.topics);
    await Hive.openBox(HiveBoxNames.questions);
    await Hive.openBox(HiveBoxNames.answers);
    await Hive.openBox(HiveBoxNames.sources);
    await Hive.openBox(HiveBoxNames.attempts);
    await Hive.openBox(HiveBoxNames.lessonBlocks);
    await Hive.openBox(HiveBoxNames.lessons);
    await Hive.openBox(HiveBoxNames.sessions);
    await Hive.openBox(HiveBoxNames.progress);
    await Hive.openBox(HiveBoxNames.tasks);

    await Hive.openBox<ConversationMessage>(HiveBoxNames.conversations);
    await Hive.openBox<TutorSession>(HiveBoxNames.tutorSessions);
    await Hive.openBox(HiveBoxNames.planAdherenceMetrics);
    await Hive.openBox(HiveBoxNames.masteryImprovementMetrics);
    await Hive.openBox<String>(HiveBoxNames.focusSessions);

    _logger.i('Hive initialized successfully with migrations');
  }

  static Future<void> _registerAdapters() async {
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(StudentAttemptAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(QuestionEvaluationAdapter());
      Hive.registerAdapter(EvaluationStepAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(MasteryStateAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(TopicDependencyAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(QuestionMasteryStateAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(PersonalLearningPlanAdapter());
      Hive.registerAdapter(DailyPlanAdapter());
      Hive.registerAdapter(PlannedTopicAdapter());
      Hive.registerAdapter(PlanSummaryAdapter());
      Hive.registerAdapter(PlanRecommendationAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(MarkschemeAdapter());
      Hive.registerAdapter(MarkSchemeStepAdapter());
    }
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(ConversationMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapter(TutorSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(PlanAdherenceMetricAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(MasteryImprovementMetricAdapter());
    }
  }
}
