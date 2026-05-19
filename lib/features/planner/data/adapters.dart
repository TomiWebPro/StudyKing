import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/personal_learning_plan_adapter.dart';
import 'adapters/plan_adherence_adapter.dart';
import 'adapters/plan_adherence_model_adapter.dart';
import 'adapters/engagement_nudge_adapter.dart';
import 'adapters/student_availability_adapter.dart';

void registerPlannerAdapters() {
  if (!Hive.isAdapterRegistered(19)) {
    Hive.registerAdapter(PersonalLearningPlanAdapter());
    Hive.registerAdapter(DailyPlanAdapter());
    Hive.registerAdapter(PlannedTopicAdapter());
    Hive.registerAdapter(PlanSummaryAdapter());
    Hive.registerAdapter(PlanRecommendationAdapter());
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
}
