import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/constants/app_constants.dart' show defaultModelForProvider;
import 'package:studyking/core/providers/app_providers.dart' show llmProviderProvider, settingsProvider;
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider;

final mentorAttemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final mentorProgressTrackerProvider = Provider<StudyProgressTracker>((ref) {
  return StudyProgressTracker(
    attemptRepo: ref.watch(mentorAttemptRepositoryProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
  );
});

final mentorPendingActionRepoProvider = Provider<PendingActionRepository>((ref) {
  return PendingActionRepository();
});

final mentorEngagementNudgeRepoProvider = Provider<EngagementNudgeRepository>((ref) {
  return EngagementNudgeRepository();
});

final mentorSessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final mentorModelIdProvider = Provider<String>((ref) {
  final savedModel = ref.watch(settingsProvider).selectedModel;
  if (savedModel.isNotEmpty) return savedModel;
  final provider = ref.watch(llmProviderProvider);
  return defaultModelForProvider(provider);
});
