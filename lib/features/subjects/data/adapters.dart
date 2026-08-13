import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/subject_adapter.dart';
import 'adapters/topic_adapter.dart';
import 'adapters/topic_dependency_adapter.dart';

void registerSubjectsAdapters() {
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(SubjectAdapter());
  }
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TopicAdapter());
  }
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(TopicDependencyAdapter());
  }
}
