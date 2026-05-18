import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

final dashboardTopicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});

final dashboardAttemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final dashboardSessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final dashboardStudyProgressTrackerProvider = Provider<StudyProgressTracker>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = lookupAppLocalizations(const Locale('en'));
  final tracker = StudyProgressTracker(
    attemptRepo: ref.read(dashboardAttemptRepositoryProvider),
    sessionRepo: ref.read(dashboardSessionRepositoryProvider),
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

final dashboardInstrumentationServiceProvider = Provider<InstrumentationService>((ref) {
  return InstrumentationService(
    adherenceRepository: ref.read(dashboardAdherenceRepositoryProvider),
  );
});

final dashboardAdherenceRepositoryProvider = Provider<PlanAdherenceRepository>((ref) {
  return PlanAdherenceRepository();
});
