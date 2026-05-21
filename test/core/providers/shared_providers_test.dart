import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/shared_providers.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';

class _FakeSettingsRepository extends SettingsRepository {
  final SettingsBox _settings = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async {
    return Result.success(_settings);
  }

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    return Result.success(null);
  }
}

void main() {
  group('shared_providers', () {
    group('localeProvider', () {
      test('falls back to en locale when no language code is set', () {
        final container = ProviderContainer();
        addTearDown(() => container.dispose());
        final locale = container.read(localeProvider);
        expect(locale, const Locale('en'));
      });

      test('respects initial language code when set', () {
        setInitialLanguageCode('fr');
        addTearDown(() => setInitialLanguageCode(''));
        final container = ProviderContainer();
        addTearDown(() => container.dispose());
        final locale = container.read(localeProvider);
        expect(locale, const Locale('fr'));
      });
    });

    group('l10nProvider', () {
      test('returns null initially', () {
        final container = ProviderContainer();
        addTearDown(() => container.dispose());
        final l10n = container.read(l10nProvider);
        expect(l10n, isNull);
      });
    });

    group('llmProviderProvider', () {
      test('defaults to openRouter', () {
        final container = ProviderContainer();
        addTearDown(() => container.dispose());
        final provider = container.read(llmProviderProvider);
        expect(provider.name, 'openRouter');
      });
    });

    group('settingsProvider', () {
      test('same SettingsController instance across reads', () {
        final repo = _FakeSettingsRepository();
        initSettingsRepository(repo);
        addTearDown(() => initSettingsRepository(_FakeSettingsRepository()));
        final container = ProviderContainer();
        addTearDown(() => container.dispose());
        final a = container.read(settingsProvider);
        final b = container.read(settingsProvider);
        expect(a, same(b));
      });
    });
  });
}
