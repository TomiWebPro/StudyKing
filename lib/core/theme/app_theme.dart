import 'package:flutter/material.dart';

class AppTheme {
  static TextTheme createTextTheme(double fontSize) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: fontSize * 2.5, height: 1.2),
      displayMedium: TextStyle(fontSize: fontSize * 2.0, height: 1.25),
      displaySmall: TextStyle(fontSize: fontSize * 1.75, height: 1.3),
      headlineLarge: TextStyle(fontSize: fontSize * 1.75, height: 1.3),
      headlineMedium: TextStyle(fontSize: fontSize * 1.5, height: 1.35),
      headlineSmall: TextStyle(fontSize: fontSize * 1.25, height: 1.4),
      titleLarge: TextStyle(fontSize: fontSize * 1.5, height: 1.3),
      titleMedium: TextStyle(fontSize: fontSize * 1.25, height: 1.35),
      titleSmall: TextStyle(fontSize: fontSize * 1.125, height: 1.35),
      bodyLarge: TextStyle(fontSize: fontSize, height: 1.5),
      bodyMedium: TextStyle(fontSize: fontSize, height: 1.4),
      bodySmall: TextStyle(fontSize: fontSize * 0.875, height: 1.3),
      labelLarge: TextStyle(fontSize: fontSize * 0.875, height: 1.4),
      labelMedium: TextStyle(fontSize: fontSize * 0.75, height: 1.35),
      labelSmall: TextStyle(fontSize: fontSize * 0.625, height: 1.3),
    );
  }

  static ThemeData lightTheme({double fontSize = 16}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF673AB7),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      textTheme: createTextTheme(fontSize),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }

  static ThemeData darkTheme({double fontSize = 16}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9575CD),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      textTheme: createTextTheme(fontSize),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surfaceContainerHighest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
