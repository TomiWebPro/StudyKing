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
    test('dashboardTopicRepositoryProvider creates TopicRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardTopicRepositoryProvider),
        isA<TopicRepository>(),
      );
    });

    test('dashboardAttemptRepositoryProvider creates AttemptRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAttemptRepositoryProvider),
        isA<AttemptRepository>(),
      );
    });

    test('dashboardStudyProgressTrackerProvider is wired to dashboardAttemptRepositoryProvider', () {
      final overrideAttempt = AttemptRepository();
      final container = ProviderContainer(
        overrides: [
          dashboardAttemptRepositoryProvider.overrideWithValue(overrideAttempt),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(dashboardStudyProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('dashboardInstrumentationServiceProvider creates InstrumentationService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardInstrumentationServiceProvider),
        isA<InstrumentationService>(),
      );
    });

    test('dashboardAdherenceRepositoryProvider creates PlanAdherenceRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardAdherenceRepositoryProvider),
        isA<PlanAdherenceRepository>(),
      );
    });
  });
}
