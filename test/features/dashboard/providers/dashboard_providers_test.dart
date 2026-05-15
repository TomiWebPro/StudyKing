import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';

void main() {
  group('DashboardProviders', () {
    test('all providers resolve without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() {
        container.read(dashboardTopicRepositoryProvider);
        container.read(dashboardAttemptRepositoryProvider);
        container.read(dashboardStudyProgressTrackerProvider);
        container.read(dashboardInstrumentationServiceProvider);
        container.read(dashboardAdherenceRepositoryProvider);
      }, returnsNormally);
    });

    test('providers can be overridden with custom values', () {
      final overrideRepo = TopicRepository();
      final overrideTracker = StudyProgressTracker(attemptRepo: AttemptRepository());
      final overrideService = InstrumentationService();
      final overrideAdherence = PlanAdherenceRepository();

      final container = ProviderContainer(overrides: [
        dashboardTopicRepositoryProvider.overrideWithValue(overrideRepo),
        dashboardAttemptRepositoryProvider.overrideWithValue(AttemptRepository()),
        dashboardStudyProgressTrackerProvider.overrideWithValue(overrideTracker),
        dashboardInstrumentationServiceProvider.overrideWithValue(overrideService),
        dashboardAdherenceRepositoryProvider.overrideWithValue(overrideAdherence),
      ]);
      addTearDown(container.dispose);

      expect(container.read(dashboardTopicRepositoryProvider), same(overrideRepo));
      expect(container.read(dashboardStudyProgressTrackerProvider), same(overrideTracker));
      expect(container.read(dashboardInstrumentationServiceProvider), same(overrideService));
      expect(container.read(dashboardAdherenceRepositoryProvider), same(overrideAdherence));
    });
  });
}
