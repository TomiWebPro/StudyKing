import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/mastery_state_adapter.dart';
import 'adapters/mastery_improvement_adapter.dart';
import 'adapters/question_mastery_state_adapter.dart';

void registerPracticeAdapters() {
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(MasteryStateAdapter());
  }
  if (!Hive.isAdapterRegistered(18)) {
    Hive.registerAdapter(QuestionMasteryStateAdapter());
  }
  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(MasteryImprovementMetricAdapter());
  }
}
