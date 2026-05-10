import 'package:hive_flutter/hive_flutter.dart';

import 'database_migration.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    // Run database migrations first
    await DatabaseMigration.runMigrations();
    
    // Open all boxes - use proper types based on models
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
    
    // Open the Kanban tasks box
    await Hive.openBox('tasks');
    
    print('Hive initialized successfully with migrations');
  }
}
