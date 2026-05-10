import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/theme/app_theme.dart';

void main() {
  group('AppTheme lightTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isFalse);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F5F5));
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);

      expect(theme.cardTheme.elevation, 2);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(12));

      expect(theme.floatingActionButtonTheme.elevation, 4);
      final fabShape =
          theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
      expect(fabShape.borderRadius, const BorderRadius.all(Radius.circular(16)));
    });

    test('elevated button style contains configured values', () {
      final style = AppTheme.lightTheme.elevatedButtonTheme.style!;

      expect(style.elevation?.resolve({}), 2);
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );

      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });
  });

  group('AppTheme darkTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isFalse);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF121212));
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);

      expect(theme.cardTheme.elevation, 2);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(12));

      expect(theme.floatingActionButtonTheme.elevation, 4);
      final fabShape =
          theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
      expect(fabShape.borderRadius, const BorderRadius.all(Radius.circular(16)));
    });

    test('elevated button style contains configured values', () {
      final style = AppTheme.darkTheme.elevatedButtonTheme.style!;

      expect(style.elevation?.resolve({}), 2);
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );

      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });
  });

  group('AppTheme widget behavior', () {
    testWidgets('light theme applies scaffold and app bar settings', (
      WidgetTester tester,
    ) async {
      late ThemeData resolvedTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Light')),
            body: Builder(
              builder: (context) {
                resolvedTheme = Theme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolvedTheme.scaffoldBackgroundColor, const Color(0xFFF5F5F5));
      expect(resolvedTheme.appBarTheme.centerTitle, isFalse);
      expect(resolvedTheme.appBarTheme.elevation, 0);
    });

    testWidgets('dark theme applies scaffold and app bar settings', (
      WidgetTester tester,
    ) async {
      late ThemeData resolvedTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Dark')),
            body: Builder(
              builder: (context) {
                resolvedTheme = Theme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolvedTheme.scaffoldBackgroundColor, const Color(0xFF121212));
      expect(resolvedTheme.appBarTheme.centerTitle, isFalse);
      expect(resolvedTheme.appBarTheme.elevation, 0);
    });
  });
}
