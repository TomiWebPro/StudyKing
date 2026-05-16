import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart' show databaseProvider;
import '../../lessons/data/repositories/lesson_repository.dart';
import '../../teaching/data/repositories/tutor_session_repository.dart';
import '../services/lesson_service.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return ref.watch(databaseProvider).lessonRepository;
});

final tutorSessionRepositoryProvider = Provider<TutorSessionRepository>((ref) {
  return ref.watch(databaseProvider).tutorSessionRepository;
});

final lessonServiceProvider = Provider<LessonService>((ref) {
  return LessonService(database: ref.watch(databaseProvider));
});
