import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

import 'database_migration.dart';
import 'hive_box_names.dart';
import 'hive_type_ids.dart';
import 'models/session_model.dart';
import 'package:studyking/features/ingestion/data/adapters/adapters.dart';
import 'package:studyking/features/sessions/data/adapters/adapters.dart';
import 'package:studyking/features/questions/data/questions_data.dart';
import 'package:studyking/features/practice/data/practice_data.dart';
import 'package:studyking/features/planner/data/planner_data.dart';
import 'package:studyking/features/subjects/data/subjects_data.dart';
import 'package:studyking/features/teaching/data/teaching_data.dart';
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
    await Hive.openBox<TutorSession>(HiveBoxNames.tutorSessions);
    await Hive.openBox<PlanAdherenceModel>(HiveBoxNames.planAdherence);
    await Hive.openBox(HiveBoxNames.planAdherenceMetrics);
    await Hive.openBox(HiveBoxNames.masteryImprovementMetrics);
    await SessionMigrationService.migrateIfNeeded();

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
