import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';

void main() {
  group('FocusModeProviders', () {
    test('sessionRepositoryProvider creates SessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, isA<SessionRepository>());
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
  });
}
