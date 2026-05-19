import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show attemptRepositoryProvider, masteryGraphServiceProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart' show sessionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

final dashboardStudyProgressTrackerProvider = Provider<StudyProgressTracker>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = lookupAppLocalizations(const Locale('en'));
  final tracker = StudyProgressTracker(
    attemptRepo: ref.read(attemptRepositoryProvider),
    sessionRepo: ref.read(sessionRepositoryProvider),
    masteryService: ref.read(masteryGraphServiceProvider),
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
    adherenceRepository: ref.read(engagementAdherenceRepoProvider),
  );
});

final dashboardExportServiceProvider = Provider<ProgressExportService>((ref) {
  return ProgressExportService(
    tracker: ref.read(dashboardStudyProgressTrackerProvider),
    masteryService: ref.read(masteryGraphServiceProvider),
    attemptRepo: ref.read(attemptRepositoryProvider),
  );
});
