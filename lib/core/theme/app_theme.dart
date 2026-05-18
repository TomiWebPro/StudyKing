import 'package:flutter/material.dart';
import 'llm_task_status.dart';

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

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required double fontSize,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      hoverColor: colorScheme.primary.withValues(alpha: 0.06),
      splashFactory: InkSparkle.splashFactory,
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
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: bottomSheetShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        indicatorColor: colorScheme.secondaryContainer,
        labelType: NavigationRailLabelType.all,
        groupAlignment: -0.8,
        minWidth: 80,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: colorScheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        errorStyle: TextStyle(color: colorScheme.error),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
      ),
    );
  }

  static ThemeData lightTheme({double fontSize = 16}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF673AB7),
      brightness: Brightness.light,
    );
    return _baseTheme(colorScheme: colorScheme, fontSize: fontSize);
  }

  static ThemeData darkTheme({double fontSize = 16}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9575CD),
      brightness: Brightness.dark,
    );
    return _baseTheme(colorScheme: colorScheme, fontSize: fontSize);
  }

  static ThemeData highContrastLightTheme({double fontSize = 16}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF673AB7),
      brightness: Brightness.light,
      contrastLevel: 1.0,
    );
    final base = _baseTheme(colorScheme: colorScheme, fontSize: fontSize);
    final baseInputTheme = base.inputDecorationTheme;
    return base.copyWith(
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: baseInputTheme.copyWith(
        filled: true,
        fillColor: baseInputTheme.fillColor,
        labelStyle: baseInputTheme.labelStyle,
        hintStyle: baseInputTheme.hintStyle,
        errorStyle: baseInputTheme.errorStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12), width: 2),
        ),
      ),
    );
  }

  static const bottomSheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  );

  static Color progressColor(double value, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (value >= 0.8) return cs.primary;
    if (value >= 0.6) return cs.tertiary;
    return cs.error;
  }

  static Color urgencyColor(double value, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (value > 0.7) return cs.error;
    if (value > 0.4) return cs.tertiary;
    return cs.primary;
  }

  static Color masteryColor(double value, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (value >= 0.8) return cs.primary;
    if (value >= 0.6) return cs.tertiary;
    return cs.error;
  }

  static Color priorityColor(double priority, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (priority > 2.0) return cs.error;
    if (priority > 1.0) return cs.tertiary;
    return cs.primary;
  }

  static Color badgeColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color statusColor(LlmTaskStatus status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      LlmTaskStatus.running => cs.primary,
      LlmTaskStatus.done => cs.primary,
      LlmTaskStatus.failed => cs.error,
      LlmTaskStatus.cancelled => cs.tertiary,
      LlmTaskStatus.queued => cs.onSurfaceVariant,
    };
  }

  static ThemeData highContrastDarkTheme({double fontSize = 16}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9575CD),
      brightness: Brightness.dark,
      contrastLevel: 1.0,
    );
    final base = _baseTheme(colorScheme: colorScheme, fontSize: fontSize);
    final baseInputTheme = base.inputDecorationTheme;
    return base.copyWith(
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: baseInputTheme.copyWith(
        filled: true,
        fillColor: baseInputTheme.fillColor,
        labelStyle: baseInputTheme.labelStyle,
        hintStyle: baseInputTheme.hintStyle,
        errorStyle: baseInputTheme.errorStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12), width: 2),
        ),
      ),
    );
  }
}
