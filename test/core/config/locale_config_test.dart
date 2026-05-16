import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/config/locale_config.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';


void main() {
  group('AppLocale enum', () {
    test('has en value with correct locale and displayName', () {
      expect(AppLocale.en.locale, const Locale('en'));
      expect(AppLocale.en.displayName, 'English');
    });

    test('has es value with correct locale and displayName', () {
      expect(AppLocale.es.locale, const Locale('es'));
      expect(AppLocale.es.displayName, 'Español');
    });

    test('has exactly two values', () {
      expect(AppLocale.values.length, 2);
    });
  });

  group('supportedLocales', () {
    test('returns all locale values from enum', () {
      final locales = AppLocale.supportedLocales;
      expect(locales.length, 2);
      expect(locales, contains(const Locale('en')));
      expect(locales, contains(const Locale('es')));
    });

    test('returns locales in enum order', () {
      final locales = AppLocale.supportedLocales;
      expect(locales[0], const Locale('en'));
      expect(locales[1], const Locale('es'));
    });
  });

  group('fromLocale', () {
    test('returns AppLocale.en for English locale', () {
      expect(AppLocale.fromLocale(const Locale('en')), AppLocale.en);
    });

    test('returns AppLocale.es for Spanish locale', () {
      expect(AppLocale.fromLocale(const Locale('es')), AppLocale.es);
    });

    test('supports region subtags for known languages', () {
      expect(
        AppLocale.fromLocale(const Locale('en', 'US')),
        AppLocale.en,
      );
      expect(
        AppLocale.fromLocale(const Locale('es', 'MX')),
        AppLocale.es,
      );
    });

    test('defaults to AppLocale.en for unsupported locale', () {
      expect(
        AppLocale.fromLocale(const Locale('fr')),
        AppLocale.en,
      );
    });

    test('defaults to AppLocale.en for German locale', () {
      expect(
        AppLocale.fromLocale(const Locale('de')),
        AppLocale.en,
      );
    });

    test('defaults to AppLocale.en for Chinese locale', () {
      expect(
        AppLocale.fromLocale(const Locale('zh')),
        AppLocale.en,
      );
    });
  });

  group('resolveLocale', () {
    final supportedLocales = AppLocale.supportedLocales;

    test('returns first supported locale when locale is null', () {
      final result = AppLocale.resolveLocale(null, supportedLocales);
      expect(result, const Locale('en'));
    });

    test('returns matching locale when found in supported list', () {
      final result = AppLocale.resolveLocale(
        const Locale('es'),
        supportedLocales,
      );
      expect(result, const Locale('es'));
    });

    test('returns English locale when matching es in supported list', () {
      final result = AppLocale.resolveLocale(
        const Locale('en'),
        supportedLocales,
      );
      expect(result, const Locale('en'));
    });

    test('returns first supported locale when locale is unsupported', () {
      final result = AppLocale.resolveLocale(
        const Locale('fr'),
        supportedLocales,
      );
      expect(result, const Locale('en'));
    });

    test('handles region subtags by matching languageCode', () {
      final result = AppLocale.resolveLocale(
        const Locale('en', 'GB'),
        supportedLocales,
      );
      expect(result, const Locale('en'));
    });

    test('returns first locale from custom supported list', () {
      final customLocales = [const Locale('de'), const Locale('fr')];
      final result = AppLocale.resolveLocale(null, customLocales);
      expect(result, const Locale('de'));
    });

    test('returns first when locale not in custom supported list', () {
      final customLocales = [const Locale('de'), const Locale('fr')];
      final result = AppLocale.resolveLocale(
        const Locale('en'),
        customLocales,
      );
      expect(result, const Locale('de'));
    });

    test('returns exact match from custom supported locales', () {
      final customLocales = [const Locale('de'), const Locale('fr'), const Locale('en')];
      final result = AppLocale.resolveLocale(
        const Locale('fr'),
        customLocales,
      );
      expect(result, const Locale('fr'));
    });
  });

  group('buildDropdownItems', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('returns a list with correct number of items', () {
      final items = AppLocale.buildDropdownItems(l10n);
      expect(items.length, 2);
    });

    test('returns DropdownMenuItem instances', () {
      final items = AppLocale.buildDropdownItems(l10n);
      for (final item in items) {
        expect(item, isA<DropdownMenuItem<String>>());
      }
    });

    test('first item corresponds to English locale', () {
      final items = AppLocale.buildDropdownItems(l10n);
      expect(items[0].value, 'en');
    });

    test('second item corresponds to Spanish locale', () {
      final items = AppLocale.buildDropdownItems(l10n);
      expect(items[1].value, 'es');
    });

    test('English item displays "English" text', () {
      final items = AppLocale.buildDropdownItems(l10n);
      final text = items[0].child as Text;
      expect(text.data, 'English');
    });

    test('Spanish item displays "Spanish" text', () {
      final items = AppLocale.buildDropdownItems(l10n);
      final text = items[1].child as Text;
      expect(text.data, 'Spanish');
    });
  });
}
