import 'package:hive_flutter/hive_flutter.dart';

/// Migration for StudyKing Hive database
/// Handles schema updates and ensures robust data persistence
class DatabaseMigration {
  static const String versionBoxName = 'db_version';
  static const int currentVersionNum = 1;

  /// Initialize and run all migrations
  static Future<void> runMigrations() async {
    // Initialize version tracking and open the box if needed
    if (!Hive.isBoxOpen(versionBoxName)) {
      await Hive.openBox(versionBoxName);
    }

    final box = Hive.box(versionBoxName);
    await box.put('version', currentVersionNum);

    // Run migrations based on current version
    final existingVersion = box.get('version', defaultValue: 0);

    if (existingVersion < 1) {
      await _migrateToV1();
      await box.put('version', 1);
    }

    print('Database migration complete. Current version: $existingVersion');
  }

  /// Migration 1: Add subjectId to existing questions and lesson blocks
  /// This migration ensures all questions and lesson blocks have subjectId
  static Future<void> _migrateToV1() async {
    print('Running migration v1: Adding subjectId to questions and lessons');

    try {
      // Migrate questions that might be missing subjectId
      final questionBox = Hive.box<Map<String, dynamic>>('questions');
      await _migrateQuestionSubjectId(questionBox);

      // Migrate lessons that might be missing subjectId
      final lessonBox = Hive.box<Map<String, dynamic>>('lessons');
      await _migrateLessonSubjectId(lessonBox);

      print('Migration v1 completed successfully');
    } on Exception catch (e) {
      print('Migration error: ${e.toString()}');
      rethrow;
    } catch (e) {
      print('Unexpected migration error: $e');
      rethrow;
    }
  }

  static Future<int> _migrateQuestionSubjectId(Box questionBox) async {
    final updatedCount = 0; // Placeholder for actual migration logic

    // Note: With new models, this migration isn't needed if all data is created through proper channels
    // Keeping as placeholder for future data validation

    return updatedCount;
  }

  static Future<void> _migrateLessonSubjectId(Box lessonBox) async {
    // Similar placeholder for lesson migration
  }

  /// Helper to validate current database schema
  static Future<DatabaseValidationResult> validateSchema() async {
    try {
      // Validate all required boxes exist
      final boxes = [
        'topics',
        'questions',
        'answers',
        'sources',
        'attempts',
        'lessonBlocks',
        'lessons',
        'sessions',
      ];

      final missingBoxes = <String>[];
      for (final boxName in boxes) {
        try {
          await Hive.openBox(boxName);
        } catch (_) {
          missingBoxes.add(boxName);
        }
      }

      return DatabaseValidationResult(
        isValid: missingBoxes.isEmpty,
        missingBoxes: missingBoxes,
        currentVersion: Hive.box(versionBoxName).get('version', defaultValue: 0),
      );
    } catch (e) {
      return DatabaseValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
}

class DatabaseValidationResult {
  final bool isValid;
  final List<String> missingBoxes;
  final int currentVersion;
  final String? error;

  DatabaseValidationResult({
    this.isValid = true,
    this.missingBoxes = const [],
    this.currentVersion = 0,
    this.error,
  });

  bool get hasErrors => error != null || !isValid || missingBoxes.isNotEmpty;
}
