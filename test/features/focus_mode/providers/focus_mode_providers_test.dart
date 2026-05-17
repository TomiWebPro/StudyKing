import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

void main() {
  group('FocusModeProviders', () {
    test('sessionRepositoryProvider creates SessionRepository and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(sessionRepositoryProvider);
      final repo2 = container.read(sessionRepositoryProvider);
      expect(repo1, isA<SessionRepository>());
      expect(repo1, same(repo2));
    });

    test('studyTimerServiceProvider is wired to sessionRepositoryProvider', () {
      final overrideRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(overrideRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      expect(service.repository, same(overrideRepo));
    });

    test('studyTimerServiceProvider returns a StudyTimerService and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final svc1 = container.read(studyTimerServiceProvider);
      final svc2 = container.read(studyTimerServiceProvider);
      expect(svc1, isA<StudyTimerService>());
      expect(svc1, same(svc2));
    });

    test('sessionRepositoryProvider can be overridden', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(sessionRepositoryProvider), same(fakeRepo));
    });

    test('all providers resolve without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () {
          container.read(sessionRepositoryProvider);
          container.read(studyTimerServiceProvider);
        },
        returnsNormally,
      );
    });

    test('handles error from session repository gracefully', () async {
      final now = DateTime.now();
      final repo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final sessions = await service.repository.getByDate(now);
      expect(sessions.isSuccess, true);
      expect(sessions.data, isEmpty);
    });
  });
}
