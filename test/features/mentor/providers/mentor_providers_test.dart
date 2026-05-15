import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/planner/data/repositories/pending_action_repository.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/providers/mentor_providers.dart';

void main() {
  group('MentorProviders', () {
    test('mentorAttemptRepositoryProvider creates AttemptRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorAttemptRepositoryProvider);
      expect(repo, isA<AttemptRepository>());
    });

    test('mentorPendingActionRepoProvider creates PendingActionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mentorPendingActionRepoProvider);
      expect(repo, isA<PendingActionRepository>());
    });

    test('mentorProgressTrackerProvider is wired to mentorAttemptRepositoryProvider', () {
      final overrideAttemptRepo = AttemptRepository();
      final container = ProviderContainer(
        overrides: [
          mentorAttemptRepositoryProvider.overrideWithValue(overrideAttemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final tracker = container.read(mentorProgressTrackerProvider);
      expect(tracker, isA<StudyProgressTracker>());
    });

    test('mentorModelIdProvider returns empty string by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(mentorModelIdProvider), equals(''));
    });
  });
}
