import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/core/providers/app_providers.dart' show notificationServiceProvider;
import 'package:studyking/features/focus_mode/services/focus_practice_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show spacedRepetitionServiceProvider, masteryGraphServiceProvider;
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;

final studyTimerServiceProvider = Provider<StudyTimerService>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return StudyTimerService(repository: repository, notificationService: notificationService);
});

final focusPracticeServiceProvider = Provider<FocusPracticeService>((ref) {
  return FocusPracticeService(
    srService: ref.watch(spacedRepetitionServiceProvider),
    masteryGraphService: ref.watch(masteryGraphServiceProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
    questionRepository: ref.watch(questionRepositoryProvider),
  );
});
