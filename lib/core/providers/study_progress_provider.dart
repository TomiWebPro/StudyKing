import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart' show l10nProvider;
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show attemptRepositoryProvider, masteryGraphServiceProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart' show sessionRepositoryProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

final _studyProgressLogger = const Logger('StudyProgressProvider');

final studyProgressTrackerProvider = Provider<StudyProgressTracker>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = l10n ?? ((){
    _studyProgressLogger.w('l10nProvider returned null for studyProgressTrackerProvider, using English fallback');
    return lookupAppLocalizations(const Locale('en'));
  })();
  final tracker = StudyProgressTracker(
    attemptRepo: ref.watch(attemptRepositoryProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
    sessionRepo: ref.watch(sessionRepositoryProvider),
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
