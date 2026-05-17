import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/core/services/notification_service.dart';

final studyTimerServiceProvider = Provider<StudyTimerService>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  return StudyTimerService(repository: repository, notificationService: NotificationService());
});
