import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/topic_dependency_adapter.dart';

void registerSubjectsAdapters() {
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(TopicDependencyAdapter());
  }
}
