import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Test harness that mirrors the app's locale switch: the MaterialApp
/// locale changes while the child's State survives (the app keeps per-tab
/// Navigators mounted, so screens stay alive across a language change).
///
/// Tests pump the widget in one locale, put it into an error/message
/// state, then call [LocaleSwitchHarnessState.switchLocale] and assert
/// the rendered text follows the new locale — catching localized strings
/// that were cached in State fields at resolve time.
class LocaleSwitchHarness extends StatefulWidget {
  final Widget child;

  const LocaleSwitchHarness({super.key, required this.child});

  @override
  State<LocaleSwitchHarness> createState() => LocaleSwitchHarnessState();
}

class LocaleSwitchHarnessState extends State<LocaleSwitchHarness> {
  Locale _locale = const Locale('en');

  void switchLocale(Locale locale) {
    if (_locale == locale) return;
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: widget.child,
    );
  }
}
