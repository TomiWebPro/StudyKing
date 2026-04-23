import 'package:hive_flutter/hive_flutter.dart';

import 'models/topic_model.dart';
import 'models/question_model.dart';
import 'models/answer_model.dart';
import 'models/source_model.dart';
import 'models/student_attempt_model.dart';
import 'models/lesson_block_model.dart';
import 'models/lesson_model.dart';
import 'models/study_session_model.dart';
import 'database_migration.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Run database migrations first
    await DatabaseMigration.runMigrations();

    // Register any custom adapters here if needed
    // Hive.registerAdapter(YourCustomAdapter());

    // Open all boxes - models use HiveField annotations
    await Hive.openBox<Topic>('topics');
    await Hive.openBox('progress');
    await Hive.openBox<Question>('questions');
    await Hive.openBox<Answer>('answers');
    await Hive.openBox<Source>('sources');
    await Hive.openBox<StudentAttempt>('attempts');
    await Hive.openBox<LessonBlock>('lessonBlocks');
    await Hive.openBox<Lesson>('lessons');
    await Hive.openBox<StudySession>('sessions');
    
    // Create version tracking box if it doesn't exist
    if (!Hive.isBoxOpen('db_version')) {
      await Hive.openBox('db_version');
    }

    print('Hive initialized successfully with migrations');
  }
}
