import 'package:hive_flutter/hive_flutter.dart';

import '../../features/subjects/models/subject_model.dart';
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
    // Run database migrations first
    await DatabaseMigration.runMigrations();
    
    // Register any custom adapters here if needed
    // Hive.registerAdapter(YourCustomAdapter());
    
    // Open all boxes - models use HiveField annotations
    await Hive.openBox<Subject>('subjects');
    await Hive.openBox<Topic>('topics');
    await Hive.openBox<Question>('questions');
    await Hive.openBox<Answer>('answers');
    await Hive.openBox<Source>('sources');
    await Hive.openBox<StudentAttempt>('attempts');
    await Hive.openBox<LessonBlock>('lessonBlocks');
    await Hive.openBox<Lesson>('lessons');
    await Hive.openBox<StudySession>('sessions');
    await Hive.openBox('progress');
    // Note: 'db_version' handled by migrations
    
    print('Hive initialized successfully with migrations');
  }
}
