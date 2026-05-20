import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/constants/app_constants.dart' show defaultModelForProvider;
import 'package:studyking/core/providers/app_providers.dart' show llmProviderProvider, settingsProvider, l10nProvider, databaseProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/core/providers/llm_agent_providers.dart' show llmAgentProvider, longTermMemoryProvider;
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/mentor_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

final mentorAttemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final mentorProgressTrackerProvider = Provider<StudyProgressTracker>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = lookupAppLocalizations(const Locale('en'));
  final tracker = StudyProgressTracker(
    attemptRepo: ref.watch(mentorAttemptRepositoryProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
    sessionRepo: ref.watch(mentorSessionRepositoryProvider),
    l10n: l10n ?? defaultL10n,
  );
  if (l10n != null) {
    tracker.updateLocalization(l10n);
  }
  ref.listen(l10nProvider, (_, next) {
    if (next != null) {
      tracker.updateLocalization(next);
    }
  });
  return tracker;
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

final mentorServiceProvider = Provider.family<MentorService, String>((ref, studentId) {
  final l10n = ref.watch(l10nProvider);
  return MentorService(
    database: ref.watch(databaseProvider),
    llmService: ref.watch(llmServiceProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
    progressTracker: ref.watch(mentorProgressTrackerProvider),
    plannerService: ref.watch(plannerServiceProvider),
    nudgeRepo: ref.watch(mentorEngagementNudgeRepoProvider),
    sessionRepository: ref.watch(mentorSessionRepositoryProvider),
    modelId: ref.watch(mentorModelIdProvider),
    studentId: studentId,
    localeName: l10n?.localeName ?? 'en',
    agent: ref.watch(llmAgentProvider(studentId)),
    longTermMemory: ref.watch(longTermMemoryProvider),
  );
});
