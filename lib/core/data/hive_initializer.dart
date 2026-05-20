import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

import 'database_migration.dart';
import 'hive_box_names.dart';
import 'hive_type_ids.dart';
import 'models/session_model.dart';
import 'package:studyking/features/ingestion/data/adapters/adapters.dart';
import 'package:studyking/features/sessions/data/adapters/adapters.dart';
import 'package:studyking/features/questions/data/adapters.dart';
import 'package:studyking/features/questions/data/models/question_evaluation_model.dart';
import 'package:studyking/features/practice/data/adapters.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/planner/data/adapters.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/subjects/data/adapters.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/teaching/data/adapters.dart';
import 'package:studyking/features/teaching/data/models/conversation_message_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/sessions/services/session_migration_service.dart';

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
    await Hive.openBox(HiveBoxNames.lessons);
    await Hive.openBox<String>(HiveBoxNames.sessions);
    await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);
    await Hive.openBox(HiveBoxNames.progress);
    await Hive.openBox(HiveBoxNames.tasks);

    await Hive.openBox<ConversationMessage>(HiveBoxNames.conversations);
    await Hive.openBox(HiveBoxNames.examResults);
    await Hive.openBox<TutorSession>(HiveBoxNames.tutorSessions);
    await Hive.openBox<PlanAdherenceModel>(HiveBoxNames.planAdherence);
    await Hive.openBox(HiveBoxNames.planAdherenceMetrics);
    await Hive.openBox(HiveBoxNames.masteryImprovementMetrics);
    await SessionMigrationService.migrateIfNeeded().then((r) {
      if (r.isFailure) {
        _logger.w('Session migration failed: ${r.error}');
      }
    });

    _logger.i('Hive initialized successfully with migrations');
  }

  static Future<void> _registerAdapters() async {
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(StudentAttemptAdapter());
    }
    registerIngestionAdapters();
    registerSessionAdapters();
    registerQuestionAdapters();
    registerPracticeAdapters();
    registerPlannerAdapters();
    registerSubjectsAdapters();
    registerTeachingAdapters();
    validateHiveTypeIds();
  }
}
