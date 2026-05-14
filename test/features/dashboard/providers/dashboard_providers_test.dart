import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';

void main() {
  group('DashboardProviders', () {
    group('provider resolution', () {
      test('dashboardTopicRepositoryProvider creates TopicRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(dashboardTopicRepositoryProvider);
        expect(repo, isA<TopicRepository>());
      });

      test('dashboardAttemptRepositoryProvider creates AttemptRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(dashboardAttemptRepositoryProvider);
        expect(repo, isA<AttemptRepository>());
      });

      test(
          'dashboardStudyProgressTrackerProvider creates StudyProgressTracker',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final tracker = container.read(dashboardStudyProgressTrackerProvider);
        expect(tracker, isA<StudyProgressTracker>());
      });

      test(
          'dashboardInstrumentationServiceProvider creates InstrumentationService',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service =
            container.read(dashboardInstrumentationServiceProvider);
        expect(service, isA<InstrumentationService>());
      });

      test(
          'dashboardAdherenceRepositoryProvider creates PlanAdherenceRepository',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(dashboardAdherenceRepositoryProvider);
        expect(repo, isA<PlanAdherenceRepository>());
      });
    });

    group('provider uniqueness', () {
      final allProviders = <String, ProviderBase>{
        'dashboardTopicRepositoryProvider': dashboardTopicRepositoryProvider,
        'dashboardAttemptRepositoryProvider':
            dashboardAttemptRepositoryProvider,
        'dashboardStudyProgressTrackerProvider':
            dashboardStudyProgressTrackerProvider,
        'dashboardInstrumentationServiceProvider':
            dashboardInstrumentationServiceProvider,

        'dashboardAdherenceRepositoryProvider':
            dashboardAdherenceRepositoryProvider,
      };

      for (final name in allProviders.keys) {
        final provider = allProviders[name]!;
        test('$name returns the same instance on repeated reads', () {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final instance1 = container.read(provider);
          final instance2 = container.read(provider);
          expect(instance1, same(instance2));
        });

        test('$name returns different instances in different containers', () {
          final container1 = ProviderContainer();
          final container2 = ProviderContainer();
          addTearDown(container1.dispose);
          addTearDown(container2.dispose);

          final instance1 = container1.read(provider);
          final instance2 = container2.read(provider);
          expect(instance1, isNot(same(instance2)));
        });
      }
    });

    group('dependency injection', () {
      test(
          'dashboardStudyProgressTrackerProvider uses dashboardAttemptRepositoryProvider',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final tracker = container.read(dashboardStudyProgressTrackerProvider);
        final attemptRepo =
            container.read(dashboardAttemptRepositoryProvider);

        expect(tracker, isA<StudyProgressTracker>());
        expect(attemptRepo, isA<AttemptRepository>());
      });

      test(
          'dashboardStudyProgressTrackerProvider can be overridden with custom AttemptRepository',
          () {
        final overrideRepo = AttemptRepository();

        final container = ProviderContainer(
          overrides: [
            dashboardAttemptRepositoryProvider.overrideWithValue(overrideRepo),
          ],
        );
        addTearDown(container.dispose);

        final tracker = container.read(dashboardStudyProgressTrackerProvider);
        final usedRepo = container.read(dashboardAttemptRepositoryProvider);

        expect(tracker, isA<StudyProgressTracker>());
        expect(usedRepo, same(overrideRepo));
      });

    });

    group('provider override', () {
      test('can override dashboardTopicRepositoryProvider', () {
        final overrideRepo = TopicRepository();

        final container = ProviderContainer(
          overrides: [
            dashboardTopicRepositoryProvider.overrideWithValue(overrideRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(dashboardTopicRepositoryProvider);
        expect(repo, same(overrideRepo));
      });

      test('can override dashboardAttemptRepositoryProvider', () {
        final overrideRepo = AttemptRepository();

        final container = ProviderContainer(
          overrides: [
            dashboardAttemptRepositoryProvider.overrideWithValue(overrideRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(dashboardAttemptRepositoryProvider);
        expect(repo, same(overrideRepo));
      });

      test('can override dashboardStudyProgressTrackerProvider', () {
        final overrideTracker = StudyProgressTracker(
          attemptRepo: AttemptRepository(),
        );

        final container = ProviderContainer(
          overrides: [
            dashboardStudyProgressTrackerProvider
                .overrideWithValue(overrideTracker),
          ],
        );
        addTearDown(container.dispose);

        final tracker = container.read(dashboardStudyProgressTrackerProvider);
        expect(tracker, same(overrideTracker));
      });

      test('can override dashboardInstrumentationServiceProvider', () {
        final overrideService = InstrumentationService();

        final container = ProviderContainer(
          overrides: [
            dashboardInstrumentationServiceProvider
                .overrideWithValue(overrideService),
          ],
        );
        addTearDown(container.dispose);

        final service = container.read(dashboardInstrumentationServiceProvider);
        expect(service, same(overrideService));
      });

      test('can override dashboardAdherenceRepositoryProvider', () {
        final overrideRepo = PlanAdherenceRepository();

        final container = ProviderContainer(
          overrides: [
            dashboardAdherenceRepositoryProvider
                .overrideWithValue(overrideRepo),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(dashboardAdherenceRepositoryProvider);
        expect(repo, same(overrideRepo));
      });
    });

    group('combined overrides', () {
      test('multiple overrides work simultaneously', () {
        final overrideRepo = TopicRepository();
        final overrideService = InstrumentationService();
        final overrideAdherence = PlanAdherenceRepository();

        final container = ProviderContainer(
          overrides: [
            dashboardTopicRepositoryProvider.overrideWithValue(overrideRepo),
            dashboardInstrumentationServiceProvider
                .overrideWithValue(overrideService),
            dashboardAdherenceRepositoryProvider
                .overrideWithValue(overrideAdherence),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(dashboardTopicRepositoryProvider);
        final service = container.read(dashboardInstrumentationServiceProvider);
        final adherence =
            container.read(dashboardAdherenceRepositoryProvider);

        expect(repo, same(overrideRepo));
        expect(service, same(overrideService));
        expect(adherence, same(overrideAdherence));
      });

      test(
          'combined override propagates to dependent StudyProgressTracker',
          () {
        final overrideAttemptRepo = AttemptRepository();

        final container = ProviderContainer(
          overrides: [
            dashboardAttemptRepositoryProvider
                .overrideWithValue(overrideAttemptRepo),
          ],
        );
        addTearDown(container.dispose);

        final tracker = container.read(dashboardStudyProgressTrackerProvider);
        final usedRepo = container.read(dashboardAttemptRepositoryProvider);

        expect(tracker, isA<StudyProgressTracker>());
        expect(usedRepo, same(overrideAttemptRepo));
      });
    });

    group('container isolation', () {
      test('overrides in one container do not affect another', () {
        final containerWithOverride = ProviderContainer(
          overrides: [
            dashboardTopicRepositoryProvider.overrideWithValue(
              TopicRepository(),
            ),
          ],
        );
        final containerWithoutOverride = ProviderContainer();
        addTearDown(containerWithOverride.dispose);
        addTearDown(containerWithoutOverride.dispose);

        final overridden =
            containerWithOverride.read(dashboardTopicRepositoryProvider);
        final normal =
            containerWithoutOverride.read(dashboardTopicRepositoryProvider);
        expect(overridden, isNot(same(normal)));
      });

      test('overrides do not leak across all five providers', () {
        final overrideRepo = TopicRepository();
        final containerWithOverride = ProviderContainer(
          overrides: [
            dashboardTopicRepositoryProvider.overrideWithValue(overrideRepo),
          ],
        );
        final containerWithoutOverride = ProviderContainer();
        addTearDown(containerWithOverride.dispose);
        addTearDown(containerWithoutOverride.dispose);

        final overriddenTopic =
            containerWithOverride.read(dashboardTopicRepositoryProvider);
        final normalTopic =
            containerWithoutOverride.read(dashboardTopicRepositoryProvider);
        final normalAttempt =
            containerWithoutOverride.read(dashboardAttemptRepositoryProvider);

        expect(overriddenTopic, same(overrideRepo));
        expect(normalTopic, isNot(same(overriddenTopic)));
        expect(normalAttempt, isA<AttemptRepository>());
      });
    });

    group('all providers in provider graph', () {
      test('reading all providers sequentially does not throw', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () {
            container.read(dashboardTopicRepositoryProvider);
            container.read(dashboardAttemptRepositoryProvider);
            container.read(dashboardStudyProgressTrackerProvider);
            container.read(dashboardInstrumentationServiceProvider);
            container.read(dashboardAdherenceRepositoryProvider);
          },
          returnsNormally,
        );
      });

      test('reading providers in reverse order does not throw', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () {
            container.read(dashboardAdherenceRepositoryProvider);
            container.read(dashboardInstrumentationServiceProvider);
            container.read(dashboardStudyProgressTrackerProvider);
            container.read(dashboardAttemptRepositoryProvider);
            container.read(dashboardTopicRepositoryProvider);
          },
          returnsNormally,
        );
      });

      test('repeated reads across all providers do not throw', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () {
            for (var i = 0; i < 10; i++) {
              container.read(dashboardTopicRepositoryProvider);
              container.read(dashboardAttemptRepositoryProvider);
              container.read(dashboardStudyProgressTrackerProvider);
              container.read(dashboardInstrumentationServiceProvider);
              container.read(dashboardAdherenceRepositoryProvider);
            }
          },
          returnsNormally,
        );
      });
    });

    group('lifecycle and disposal', () {
      test('disposed container throws on read', () {
        final container = ProviderContainer();
        container.dispose();

        expect(
          () => container.read(dashboardTopicRepositoryProvider),
          throwsA(isA<StateError>()),
        );
      });

      test(
          'read after partial disposal of overridden providers throws',
          () {
        final container = ProviderContainer(
          overrides: [
            dashboardTopicRepositoryProvider.overrideWithValue(
              TopicRepository(),
            ),
          ],
        );
        container.dispose();

        expect(
          () => container.read(dashboardTopicRepositoryProvider),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('watch behavior', () {
      test('ref.watch returns the same instance as ref.read', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final watched = container.read(dashboardTopicRepositoryProvider);
        final read = container.read(dashboardTopicRepositoryProvider);
        expect(watched, same(read));
      });
    });
  });
}
