// Core module exports
export 'data/enums.dart';
export 'data/database_service.dart';
export 'data/hive_initializer.dart';

// Models
export 'data/models/topic_model.dart';
export 'data/models/question_model.dart';
export 'data/models/answer_model.dart';
export 'data/models/source_model.dart';
export 'data/models/student_attempt_model.dart';
export 'data/models/topic_progress_model.dart';
export 'data/models/lesson_block_model.dart';
export 'data/models/lesson_model.dart';
export 'data/models/study_session_model.dart';

// Repositories
export 'data/repositories/topic_repository.dart';
export 'data/repositories/question_repository.dart';
export 'data/repositories/attempt_repository.dart';
export 'data/repositories/answer_repository.dart';
export 'data/repositories/source_repository.dart';
export 'data/repositories/progress_repository.dart';
export 'data/repositories/lesson_repository.dart';
export 'data/repositories/session_repository.dart';

// Extension for firstOrNull
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}

// Database is defined in main.dart - import it directly from there
// Usage: import '../../main.dart' show database;
