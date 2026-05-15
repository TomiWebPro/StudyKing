import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final studyTimerServiceProvider = Provider<StudyTimerService>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  return StudyTimerService(repository: repository);
});
