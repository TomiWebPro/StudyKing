import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

void main() {
  group('sessionRepositoryProvider', () {
    test('creates a SessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, isA<SessionRepository>());
    });

    test('returns the same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(sessionRepositoryProvider);
      final repo2 = container.read(sessionRepositoryProvider);
      expect(repo1, same(repo2));
    });

    test('can be overridden', () {
      final overrideRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(overrideRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, same(overrideRepo));
    });

    test('resolves without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(sessionRepositoryProvider),
        returnsNormally,
      );
    });
  });
}
