import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/providers/shared_providers.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider;
import 'package:studyking/core/providers/study_progress_provider.dart' show studyProgressTrackerProvider;
import 'package:studyking/core/data/repositories/engagement_nudge_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart' show mentorServiceProvider;
import 'package:studyking/core/providers/service_providers.dart';
import '../services/engagement_scheduler.dart';
import '../services/notification_service.dart';
import '../services/plan_adherence_orchestrator.dart';
import '../services/badge_service.dart';
import '../../features/dashboard/data/repositories/badge_repository.dart';

export 'shared_providers.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final fontSizeProvider = StateProvider<double>((ref) => 16.0);

final apiKeyProvider = StateProvider<String>((ref) => '');

final apiBaseUrlProvider = StateProvider<String>((ref) => ApiConfig.openRouterBaseUrlString);

final selectedModelProvider = StateProvider<String>((ref) => '');

final planOrchestratorProvider = Provider<PlanAdherenceOrchestrator>((ref) {
  return PlanAdherenceOrchestrator();
});

final _appProvidersLogger = const Logger('AppProviders');

final engagementNudgeRepoProvider = Provider<EngagementNudgeRepository>((ref) {
  return EngagementNudgeRepository();
});

final engagementAdherenceRepoProvider = Provider<PlanAdherenceRepository>((ref) {
  return PlanAdherenceRepository();
});

final engagementPlannerServiceProvider = Provider<PlannerService>((ref) {
  return PlannerService(
    masteryService: ref.watch(masteryGraphServiceProvider),
  );
});

final engagementSchedulerProvider = Provider<EngagementScheduler>((ref) {
  final l10n = ref.watch(l10nProvider);
  final defaultL10n = l10n ?? ((){
    _appProvidersLogger.w('l10nProvider returned null for engagementSchedulerProvider, using English fallback');
    return lookupAppLocalizations(const Locale('en'));
  })();
  final studentId = ref.read(studentIdServiceProvider).getStudentId();
  final scheduler = EngagementScheduler(
    tracker: ref.watch(studyProgressTrackerProvider),
    masteryService: ref.watch(masteryGraphServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    nudgeRepository: ref.watch(engagementNudgeRepoProvider),
    adherenceRepository: ref.watch(engagementAdherenceRepoProvider),
    planOrchestrator: ref.watch(planOrchestratorProvider),
    sessionRepository: ref.watch(databaseProvider).sessionRepository,
    plannerService: ref.watch(engagementPlannerServiceProvider),
    mentorService: ref.watch(mentorServiceProvider(studentId)),
    l10n: l10n ?? defaultL10n,
  );
  if (l10n != null) scheduler.updateLocalization(l10n);
  ref.listen(l10nProvider, (_, next) {
    if (next != null) scheduler.updateLocalization(next);
  });
  ref.onDispose(() {
    scheduler.dispose();
  });
  return scheduler;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository();
});

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService(
    repository: ref.watch(badgeRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});


