import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/core/providers/app_providers.dart' show notificationServiceProvider;

final studyTimerServiceProvider = Provider<StudyTimerService>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return StudyTimerService(repository: repository, notificationService: notificationService);
});
