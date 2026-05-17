import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  Brightness get brightness => Theme.of(this).brightness;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
