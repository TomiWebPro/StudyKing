import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'database_migration.dart';
import 'adapters/question_evaluation_adapter.dart';
import 'adapters/mastery_state_adapter.dart';
import 'adapters/topic_dependency_adapter.dart';
import 'adapters/question_mastery_state_adapter.dart';
import 'adapters/personal_learning_plan_adapter.dart';
import 'models/question_evaluation_model.dart';
import 'models/mastery_state_model.dart';
import 'models/topic_dependency_model.dart';
import 'models/question_mastery_state_model.dart';
import 'models/personal_learning_plan_model.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    await DatabaseMigration.runMigrations();
    await _registerAdapters();
    
    await Hive.openBox<QuestionEvaluation>('question_evaluations');
    await Hive.openBox<MasteryState>('mastery_states');
    await Hive.openBox<QuestionMasteryState>('question_mastery_states');
    await Hive.openBox<TopicDependency>('topic_dependencies');
    await Hive.openBox<PersonalLearningPlan>('learning_plans');
    
    await Hive.openBox('subjects');
    await Hive.openBox('topics');
    await Hive.openBox('questions');
    await Hive.openBox('answers');
    await Hive.openBox('sources');
    await Hive.openBox('attempts');
    await Hive.openBox('lessonBlocks');
    await Hive.openBox('lessons');
    await Hive.openBox('sessions');
    await Hive.openBox('progress');
    
    await Hive.openBox('tasks');
    
    debugPrint('Hive initialized successfully with migrations');
  }
  
  static Future<void> _registerAdapters() async {
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
  }
}
