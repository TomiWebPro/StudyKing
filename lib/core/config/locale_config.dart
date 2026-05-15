import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

enum AppLocale {
  en(Locale('en'), 'English'),
  es(Locale('es'), 'Español');

  final Locale locale;
  final String displayName;

  const AppLocale(this.locale, this.displayName);

  static List<Locale> get supportedLocales =>
      AppLocale.values.map((l) => l.locale).toList();

  static AppLocale fromLocale(Locale locale) {
    for (final appLocale in AppLocale.values) {
      if (appLocale.locale.languageCode == locale.languageCode) {
        return appLocale;
      }
    }
    return AppLocale.en;
  }

  static Locale? resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return supportedLocales.first;
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return supportedLocales.first;
  }

  static List<DropdownMenuItem<String>> buildDropdownItems(
      AppLocalizations l10n) {
    return AppLocale.values.map((appLocale) {
      final label = switch (appLocale) {
        AppLocale.en => l10n.english,
        AppLocale.es => l10n.spanish,
      };
      return DropdownMenuItem(
        value: appLocale.locale.languageCode,
        child: Text(label),
      );
    }).toList();
  }
}
