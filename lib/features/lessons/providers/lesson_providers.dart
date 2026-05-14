import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/tutor_session_model.dart';
import '../../../core/services/mastery_graph_service.dart';
import '../../../core/providers/app_providers.dart' show database;
import '../../teaching/services/tutor_service.dart';
import '../services/lesson_service.dart';

final lessonServiceProvider = Provider<LessonService>((ref) {
  final tutorService = TutorService(
    database: database,
    llmService: ref.watch(llmServiceProviderForLesson),
    masteryService: ref.watch(masteryServiceForLessonProvider),
    modelId: 'openai/gpt-4o-mini',
  );
  return LessonService(
    database: database,
    tutorService: tutorService,
  );
});

final llmServiceProviderForLesson = Provider((ref) {
  return ref.watch(llmServiceProviderFallback);
});

final llmServiceProviderFallback = Provider((ref) {
  throw UnimplementedError('llmServiceProvider must be overridden');
});

final masteryServiceForLessonProvider = Provider<MasteryGraphService>((ref) {
  return MasteryGraphService();
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
