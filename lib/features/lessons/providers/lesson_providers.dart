import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart' show databaseProvider, settingsProvider;
import '../../../core/providers/llm_providers.dart' show llmServiceProvider, llmTaskManagerProvider;
import '../../../features/teaching/data/repositories/tutor_session_repository.dart';
import '../../lessons/data/repositories/lesson_repository.dart';
import '../services/lesson_service.dart';
import '../services/lesson_agent_service.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return ref.watch(databaseProvider).lessonRepository;
});

final tutorSessionRepositoryProvider = Provider<TutorSessionRepository>((ref) {
  return ref.watch(databaseProvider).tutorSessionRepository;
});

final lessonServiceProvider = Provider<SessionQueryService>((ref) {
  return SessionQueryService(database: ref.watch(databaseProvider));
});

final lessonAgentServiceProvider = Provider<LessonAgentService>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  return LessonAgentService(
    llmService: llmService,
    modelId: ref.watch(settingsProvider).selectedModel,
    lessonRepository: ref.watch(lessonRepositoryProvider),
    database: ref.watch(databaseProvider),
    taskManager: ref.watch(llmTaskManagerProvider),
  );
});
