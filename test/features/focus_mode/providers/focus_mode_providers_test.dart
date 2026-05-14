import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';
import 'package:studyking/features/focus_mode/services/focus_session_service.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';

void main() {
  group('FocusModeProviders', () {
    test('focusSessionRepositoryProvider creates FocusSessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(focusSessionRepositoryProvider);
      expect(repo, isA<FocusSessionRepository>());
    });

    test('focusSessionServiceProvider creates FocusSessionService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(focusSessionServiceProvider);
      expect(service, isA<FocusSessionService>());
    });

    test('focusSessionServiceProvider depends on focusSessionRepositoryProvider', () {
      final overrideRepo = FocusSessionRepository();
      final container = ProviderContainer(
        overrides: [
          focusSessionRepositoryProvider.overrideWithValue(overrideRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(focusSessionServiceProvider);
      expect(service.repository, same(overrideRepo));
    });

    test('can override focusSessionRepositoryProvider', () {
      final override = FocusSessionRepository();
      final container = ProviderContainer(
        overrides: [
          focusSessionRepositoryProvider.overrideWithValue(override),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(focusSessionRepositoryProvider),
        same(override),
      );
    });

    test('providers resolve without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () {
          container.read(focusSessionRepositoryProvider);
          container.read(focusSessionServiceProvider);
        },
        returnsNormally,
      );
    });
  });
}
