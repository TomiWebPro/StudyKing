import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';

void main() {
  group('MentorProviders', () {
    group('provider resolution', () {
      test('mentorAttemptRepositoryProvider creates AttemptRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(mentorAttemptRepositoryProvider);
        expect(repo, isA<AttemptRepository>());
      });

      test('mentorProgressTrackerProvider creates StudyProgressTracker', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final tracker = container.read(mentorProgressTrackerProvider);
        expect(tracker, isA<StudyProgressTracker>());
      });

      test('mentorPendingActionRepoProvider creates PendingActionRepository', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(mentorPendingActionRepoProvider);
        expect(repo, isA<PendingActionRepository>());
      });
    });

    group('override', () {
      test('can override mentorAttemptRepositoryProvider', () {
        final override = AttemptRepository();
        final container = ProviderContainer(
          overrides: [
            mentorAttemptRepositoryProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(mentorAttemptRepositoryProvider),
          same(override),
        );
      });

      test('can override mentorProgressTrackerProvider', () {
        final overrideRepo = AttemptRepository();
        final override = StudyProgressTracker(attemptRepo: overrideRepo);
        final container = ProviderContainer(
          overrides: [
            mentorProgressTrackerProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(mentorProgressTrackerProvider),
          same(override),
        );
      });

      test('can override mentorPendingActionRepoProvider', () {
        final override = PendingActionRepository();
        final container = ProviderContainer(
          overrides: [
            mentorPendingActionRepoProvider.overrideWithValue(override),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(mentorPendingActionRepoProvider),
          same(override),
        );
      });
    });

    group('singleton behavior', () {
      test('mentorAttemptRepositoryProvider returns same instance on repeated reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(mentorAttemptRepositoryProvider);
        final b = container.read(mentorAttemptRepositoryProvider);
        expect(a, same(b));
      });

      test('mentorProgressTrackerProvider returns same instance on repeated reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(mentorProgressTrackerProvider);
        final b = container.read(mentorProgressTrackerProvider);
        expect(a, same(b));
      });

      test('mentorPendingActionRepoProvider returns same instance on repeated reads', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final a = container.read(mentorPendingActionRepoProvider);
        final b = container.read(mentorPendingActionRepoProvider);
        expect(a, same(b));
      });

      test('providers return different instances in different containers', () {
        final c1 = ProviderContainer();
        final c2 = ProviderContainer();
        addTearDown(c1.dispose);
        addTearDown(c2.dispose);

        expect(
          c1.read(mentorAttemptRepositoryProvider),
          isNot(same(c2.read(mentorAttemptRepositoryProvider))),
        );
      });
    });

    group('lifecycle', () {
      test('disposed container throws on read', () {
        final container = ProviderContainer();
        container.dispose();

        expect(
          () => container.read(mentorAttemptRepositoryProvider),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
