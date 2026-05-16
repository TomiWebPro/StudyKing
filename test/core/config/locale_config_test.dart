import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/config/locale_config.dart';

void main() {
  group('AppLocale', () {
    test('has correct enum values', () {
      expect(AppLocale.en.locale, equals(const Locale('en')));
      expect(AppLocale.en.displayName, equals('English'));
      expect(AppLocale.es.locale, equals(const Locale('es')));
      expect(AppLocale.es.displayName, equals('Español'));
    });

    test('supportedLocales returns all locales', () {
      final locales = AppLocale.supportedLocales;
      expect(locales, contains(const Locale('en')));
      expect(locales, contains(const Locale('es')));
    });

    test('fromLocale returns correct enum for en', () {
      expect(AppLocale.fromLocale(const Locale('en')), equals(AppLocale.en));
    });

    test('fromLocale returns correct enum for es', () {
      expect(AppLocale.fromLocale(const Locale('es')), equals(AppLocale.es));
    });

    test('fromLocale returns en for unsupported locale', () {
      expect(AppLocale.fromLocale(const Locale('fr')), equals(AppLocale.en));
    });

    test('fromLocale returns en for locale with unsupported language', () {
      expect(AppLocale.fromLocale(const Locale('de')), equals(AppLocale.en));
    });

    test('resolveLocale returns first supported locale when input is null', () {
      final supported = [const Locale('en'), const Locale('es')];
      final result = AppLocale.resolveLocale(null, supported);
      expect(result, equals(const Locale('en')));
    });

    test('resolveLocale returns matching locale', () {
      final supported = [const Locale('en'), const Locale('es')];
      final result = AppLocale.resolveLocale(const Locale('es'), supported);
      expect(result, equals(const Locale('es')));
    });

    test('resolveLocale returns first supported when no match', () {
      final supported = [const Locale('en'), const Locale('es')];
      final result = AppLocale.resolveLocale(const Locale('fr'), supported);
      expect(result, equals(const Locale('en')));
    });

  });
}
