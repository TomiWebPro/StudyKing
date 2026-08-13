import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/lesson_block_adapter.dart';
import 'adapters/lesson_adapter.dart';

void registerLessonAdapters() {
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(LessonBlockAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(LessonAdapter());
  }
}
