import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import '../../../core/providers/app_providers.dart' show database;
import '../../lessons/data/repositories/lesson_repository.dart';
import '../../teaching/data/repositories/tutor_session_repository.dart';
import '../services/lesson_service.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return database.lessonRepository;
});

final tutorSessionRepositoryProvider = Provider<TutorSessionRepository>((ref) {
  return database.tutorSessionRepository;
});

final lessonServiceProvider = Provider<LessonService>((ref) {
  return LessonService(database: database);
});

final studentLessonsProvider =
    FutureProvider.family<List<TutorSession>, String>((ref, studentId) {
  final service = ref.watch(lessonServiceProvider);
  return service.getLessonsForStudent(studentId);
});

final lessonCompletionRateProvider =
    FutureProvider.family<double, String>((ref, studentId) {
  final service = ref.watch(lessonServiceProvider);
  return service.getCompletionRate(studentId);
});

final lessonProgressBySubjectProvider =
    FutureProvider.family<Map<String, double>, String>((ref, studentId) {
  final service = ref.watch(lessonServiceProvider);
  return service.getProgressBySubject(studentId);
});

final lessonCountBySubjectProvider =
    FutureProvider.family<Map<String, int>, String>((ref, studentId) {
  final service = ref.watch(lessonServiceProvider);
  return service.getLessonCountBySubject(studentId);
});

final upcomingLessonsProvider =
    FutureProvider.family<List<TutorSession>, String>((ref, studentId) {
  final service = ref.watch(lessonServiceProvider);
  return service.getUpcomingLessons(studentId);
});

final recentLessonsProvider =
    FutureProvider.family<List<TutorSession>, String>((ref, studentId) {
  final service = ref.watch(lessonServiceProvider);
  return service.getRecentLessons(studentId);
});
