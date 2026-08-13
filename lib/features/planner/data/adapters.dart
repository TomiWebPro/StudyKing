import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/personal_learning_plan_adapter.dart';
import 'adapters/pending_action_adapter.dart';
import 'adapters/plan_adherence_adapter.dart';
import 'adapters/plan_adherence_model_adapter.dart';
import 'adapters/engagement_nudge_adapter.dart';
import 'adapters/student_availability_adapter.dart';
import 'adapters/plan_advisor_suggestion_adapter.dart';
import 'adapters/task_adapter.dart';
import 'adapters/milestone_adapter.dart';
import 'adapters/roadmap_adapter.dart';

void registerPlannerAdapters() {
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(PendingActionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(TaskModelAdapter());
  }
  if (!Hive.isAdapterRegistered(19)) {
    Hive.registerAdapter(PersonalLearningPlanAdapter());
    Hive.registerAdapter(DailyPlanAdapter());
    Hive.registerAdapter(PlannedTopicAdapter());
    Hive.registerAdapter(PlanSummaryAdapter());
    Hive.registerAdapter(PlanRecommendationAdapter());
  }
  if (!Hive.isAdapterRegistered(25)) {
    Hive.registerAdapter(MilestoneModelAdapter());
  }
  if (!Hive.isAdapterRegistered(29)) {
    Hive.registerAdapter(RoadmapModelAdapter());
  }
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(PlanAdherenceMetricAdapter());
  }
  if (!Hive.isAdapterRegistered(32)) {
    Hive.registerAdapter(EngagementNudgeModelAdapter());
  }
  if (!Hive.isAdapterRegistered(33)) {
    Hive.registerAdapter(PlanAdherenceModelAdapter());
  }
  if (!Hive.isAdapterRegistered(35)) {
    Hive.registerAdapter(StudentAvailabilityModelAdapter());
  }
  if (!Hive.isAdapterRegistered(37)) {
    Hive.registerAdapter(PlanAdvisorSuggestionAdapter());
  }
}
