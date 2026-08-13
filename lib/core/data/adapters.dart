import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/learning_preference_adapter.dart';

void registerCoreDataAdapters() {
  if (!Hive.isAdapterRegistered(43)) {
    Hive.registerAdapter(LearningPreferenceAdapter());
  }
}
