import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/theme/app_theme.dart';

void main() {
  group('AppTheme.createTextTheme', () {
    test('returns TextTheme with correct default font sizes', () {
      const fontSize = 16.0;
      final textTheme = AppTheme.createTextTheme(fontSize);

      expect(textTheme.displayLarge?.fontSize, fontSize * 2.5);
      expect(textTheme.displayMedium?.fontSize, fontSize * 2.0);
      expect(textTheme.displaySmall?.fontSize, fontSize * 1.75);
      expect(textTheme.headlineLarge?.fontSize, fontSize * 1.75);
      expect(textTheme.headlineMedium?.fontSize, fontSize * 1.5);
      expect(textTheme.headlineSmall?.fontSize, fontSize * 1.25);
      expect(textTheme.titleLarge?.fontSize, fontSize * 1.5);
      expect(textTheme.titleMedium?.fontSize, fontSize * 1.25);
      expect(textTheme.titleSmall?.fontSize, fontSize * 1.125);
      expect(textTheme.bodyLarge?.fontSize, fontSize);
      expect(textTheme.bodyMedium?.fontSize, fontSize);
      expect(textTheme.bodySmall?.fontSize, fontSize * 0.875);
      expect(textTheme.labelLarge?.fontSize, fontSize * 0.875);
      expect(textTheme.labelMedium?.fontSize, fontSize * 0.75);
      expect(textTheme.labelSmall?.fontSize, fontSize * 0.625);
    });

    test('all text styles have non-null height', () {
      final textTheme = AppTheme.createTextTheme(16);
      expect(textTheme.displayLarge?.height, 1.2);
      expect(textTheme.displayMedium?.height, 1.25);
      expect(textTheme.displaySmall?.height, 1.3);
      expect(textTheme.headlineLarge?.height, 1.3);
      expect(textTheme.headlineMedium?.height, 1.35);
      expect(textTheme.headlineSmall?.height, 1.4);
      expect(textTheme.titleLarge?.height, 1.3);
      expect(textTheme.titleMedium?.height, 1.35);
      expect(textTheme.titleSmall?.height, 1.35);
      expect(textTheme.bodyLarge?.height, 1.5);
      expect(textTheme.bodyMedium?.height, 1.4);
      expect(textTheme.bodySmall?.height, 1.3);
      expect(textTheme.labelLarge?.height, 1.4);
      expect(textTheme.labelMedium?.height, 1.35);
      expect(textTheme.labelSmall?.height, 1.3);
    });

    test('scales font sizes with custom fontSize parameter', () {
      const baseFontSize = 14.0;
      final textTheme = AppTheme.createTextTheme(baseFontSize);

      expect(textTheme.displayLarge?.fontSize, 35.0);
      expect(textTheme.bodyLarge?.fontSize, 14.0);
      expect(textTheme.labelSmall?.fontSize, 8.75);
    });

    test('all text styles have null color (inherits from theme)', () {
      final textTheme = AppTheme.createTextTheme(16);
      expect(textTheme.displayLarge?.color, isNull);
      expect(textTheme.bodyLarge?.color, isNull);
    });
  });

  group('AppTheme.bottomSheetShape', () {
    test('has correct border radius', () {
      const shape = AppTheme.bottomSheetShape;
      expect(shape.borderRadius, BorderRadius.vertical(top: Radius.circular(16)));
    });

    test('is a RoundedRectangleBorder', () {
      expect(AppTheme.bottomSheetShape, isA<RoundedRectangleBorder>());
    });
  });

  group('AppTheme lightTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.lightTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 3);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(12));
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerHighest);
      expect(theme.floatingActionButtonTheme.elevation, 4);
      expect(theme.floatingActionButtonTheme.backgroundColor, theme.colorScheme.primaryContainer);
      expect(theme.floatingActionButtonTheme.foregroundColor, theme.colorScheme.onPrimaryContainer);
      final fabShape = theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
      expect(fabShape.borderRadius, const BorderRadius.all(Radius.circular(16)));

      expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    });

    test('has correct disabled, focus, and hover colors', () {
      final theme = AppTheme.lightTheme();
      expect(theme.disabledColor, theme.colorScheme.onSurface.withValues(alpha: 0.38));
      expect(theme.focusColor, theme.colorScheme.primary.withValues(alpha: 0.12));
      expect(theme.hoverColor, theme.colorScheme.primary.withValues(alpha: 0.06));
    });

    test('splashFactory is InkSparkle', () {
      expect(AppTheme.lightTheme().splashFactory, InkSparkle.splashFactory);
    });

    test('elevated button style contains configured values', () {
      final style = AppTheme.lightTheme().elevatedButtonTheme.style!;

      expect(style.elevation?.resolve({}), 0);
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );

      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('filled button style contains configured values', () {
      final style = AppTheme.lightTheme().filledButtonTheme.style!;
      expect(style.elevation?.resolve({}), 0);
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );
      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('outlined button style contains configured values', () {
      final style = AppTheme.lightTheme().outlinedButtonTheme.style!;
      expect(style.elevation?.resolve({}), 0);
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );
      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('navigationBar theme contains configured values', () {
      final theme = AppTheme.lightTheme();

      expect(theme.navigationBarTheme.elevation, 2);
      expect(
        theme.navigationBarTheme.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
      expect(
        theme.navigationBarTheme.backgroundColor,
        theme.colorScheme.surfaceContainerHigh,
      );
      expect(
        theme.navigationBarTheme.indicatorColor,
        theme.colorScheme.secondaryContainer,
      );
    });

    test('navigationRail theme contains configured values', () {
      final theme = AppTheme.lightTheme();
      expect(theme.navigationRailTheme.backgroundColor, theme.colorScheme.surfaceContainerHigh);
      expect(theme.navigationRailTheme.indicatorColor, theme.colorScheme.secondaryContainer);
      expect(theme.navigationRailTheme.labelType, NavigationRailLabelType.all);
      expect(theme.navigationRailTheme.groupAlignment, -0.8);
      expect(theme.navigationRailTheme.minWidth, 80);
    });

    test('bottomSheet theme uses the static shape', () {
      final theme = AppTheme.lightTheme();
      expect(theme.bottomSheetTheme.shape, AppTheme.bottomSheetShape);
    });

    test('snackBar theme is floating with rounded corners', () {
      final theme = AppTheme.lightTheme();
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      final shape = theme.snackBarTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('dialog theme has rounded corners', () {
      final theme = AppTheme.lightTheme();
      final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    test('textSelection theme uses primary color', () {
      final theme = AppTheme.lightTheme();
      expect(theme.textSelectionTheme.cursorColor, theme.colorScheme.primary);
      expect(theme.textSelectionTheme.selectionColor, theme.colorScheme.primary.withValues(alpha: 0.3));
      expect(theme.textSelectionTheme.selectionHandleColor, theme.colorScheme.primary);
    });

    test('divider theme uses outlineVariant color', () {
      final theme = AppTheme.lightTheme();
      expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
      expect(theme.dividerTheme.thickness, 1);
    });

    test('inputDecoration theme has configured values', () {
      final theme = AppTheme.lightTheme();
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());
      expect(inputTheme.errorBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedErrorBorder, isA<OutlineInputBorder>());
      expect(inputTheme.disabledBorder, isA<OutlineInputBorder>());

      expect(inputTheme.filled, isTrue);
      expect(inputTheme.fillColor, theme.colorScheme.surfaceContainerLowest);
      expect(inputTheme.labelStyle?.color, theme.colorScheme.onSurface);
      expect(inputTheme.hintStyle?.color, theme.colorScheme.onSurfaceVariant);
      expect(inputTheme.errorStyle?.color, theme.colorScheme.error);

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, theme.colorScheme.primary);
      expect(focusedBorder.borderSide.width, 2);
    });

    test('applies default fontSize when not specified', () {
      final theme = AppTheme.lightTheme();
      expect(theme.textTheme.bodyLarge?.fontSize, 16.0);
    });

    test('applies custom fontSize', () {
      final theme = AppTheme.lightTheme(fontSize: 18);
      expect(theme.textTheme.bodyLarge?.fontSize, 18.0);
      expect(theme.textTheme.displayLarge?.fontSize, 45.0);
    });

    test('uses correct seed color', () {
      final theme = AppTheme.lightTheme();
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('largeTouchTargets affects minimum size', () {
      final normalStyle = AppTheme.lightTheme(largeTouchTargets: false).elevatedButtonTheme.style!;
      final largeStyle = AppTheme.lightTheme(largeTouchTargets: true).elevatedButtonTheme.style!;

      expect(normalStyle.minimumSize?.resolve({}), const Size(0, 0));
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });

    test('largeTouchTargets affects filled button', () {
      final largeStyle = AppTheme.lightTheme(largeTouchTargets: true).filledButtonTheme.style!;
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });

    test('largeTouchTargets affects outlined button', () {
      final largeStyle = AppTheme.lightTheme(largeTouchTargets: true).outlinedButtonTheme.style!;
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('AppTheme darkTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.darkTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 3);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(12));
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerHighest);
      expect(theme.floatingActionButtonTheme.elevation, 4);
      expect(theme.floatingActionButtonTheme.backgroundColor, theme.colorScheme.primaryContainer);
      expect(theme.floatingActionButtonTheme.foregroundColor, theme.colorScheme.onPrimaryContainer);
      final fabShape = theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
      expect(fabShape.borderRadius, const BorderRadius.all(Radius.circular(16)));

      expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    });

    test('has correct disabled, focus, and hover colors', () {
      final theme = AppTheme.darkTheme();
      expect(theme.disabledColor, theme.colorScheme.onSurface.withValues(alpha: 0.38));
      expect(theme.focusColor, theme.colorScheme.primary.withValues(alpha: 0.12));
      expect(theme.hoverColor, theme.colorScheme.primary.withValues(alpha: 0.06));
    });

    test('elevated button style contains configured values', () {
      final style = AppTheme.darkTheme().elevatedButtonTheme.style!;
      expect(style.elevation?.resolve({}), 0);
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );
      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('filled button style contains configured values', () {
      final style = AppTheme.darkTheme().filledButtonTheme.style!;
      expect(style.elevation?.resolve({}), 0);
      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('outlined button style contains configured values', () {
      final style = AppTheme.darkTheme().outlinedButtonTheme.style!;
      expect(style.elevation?.resolve({}), 0);
      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    test('navigationBar theme contains configured values', () {
      final theme = AppTheme.darkTheme();
      expect(theme.navigationBarTheme.elevation, 2);
      expect(
        theme.navigationBarTheme.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
      expect(
        theme.navigationBarTheme.backgroundColor,
        theme.colorScheme.surfaceContainerHigh,
      );
      expect(
        theme.navigationBarTheme.indicatorColor,
        theme.colorScheme.secondaryContainer,
      );
    });

    test('navigationRail theme contains configured values', () {
      final theme = AppTheme.darkTheme();
      expect(theme.navigationRailTheme.backgroundColor, theme.colorScheme.surfaceContainerHigh);
      expect(theme.navigationRailTheme.indicatorColor, theme.colorScheme.secondaryContainer);
      expect(theme.navigationRailTheme.labelType, NavigationRailLabelType.all);
      expect(theme.navigationRailTheme.groupAlignment, -0.8);
      expect(theme.navigationRailTheme.minWidth, 80);
    });

    test('inputDecoration theme has configured values', () {
      final theme = AppTheme.darkTheme();
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.filled, isTrue);
      expect(inputTheme.fillColor, theme.colorScheme.surfaceContainerLowest);
      expect(inputTheme.labelStyle?.color, theme.colorScheme.onSurface);
      expect(inputTheme.hintStyle?.color, theme.colorScheme.onSurfaceVariant);
      expect(inputTheme.errorStyle?.color, theme.colorScheme.error);

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, theme.colorScheme.primary);
      expect(focusedBorder.borderSide.width, 2);
    });

    test('uses correct seed color', () {
      final theme = AppTheme.darkTheme();
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('largeTouchTargets affects minimum size', () {
      final largeStyle = AppTheme.darkTheme(largeTouchTargets: true).elevatedButtonTheme.style!;
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('AppTheme highContrastLightTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.highContrastLightTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.cardTheme.elevation, 2);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerHighest);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(12));
      expect(cardShape.side.color, theme.colorScheme.outline);
      expect(cardShape.side.width, 1);
      expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
      expect(theme.dividerTheme.thickness, 2);
    });

    test('inputDecoration theme has configured borders with width 2', () {
      final theme = AppTheme.highContrastLightTheme();
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());
      expect(inputTheme.errorBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedErrorBorder, isA<OutlineInputBorder>());
      expect(inputTheme.disabledBorder, isA<OutlineInputBorder>());

      for (final border in [
        inputTheme.border,
        inputTheme.enabledBorder,
        inputTheme.disabledBorder,
      ]) {
        final b = border as OutlineInputBorder;
        expect(b.borderSide.width, 2);
      }

      final border = inputTheme.border as OutlineInputBorder;
      expect(border.borderSide.color, theme.colorScheme.outline);
      expect(border.borderSide.width, 2);

      final enabledBorder = inputTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, theme.colorScheme.outline);
      expect(enabledBorder.borderSide.width, 2);

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, theme.colorScheme.primary);
      expect(focusedBorder.borderSide.width, 2);

      final errorBorder = inputTheme.errorBorder as OutlineInputBorder;
      expect(errorBorder.borderSide.color, theme.colorScheme.error);
      expect(errorBorder.borderSide.width, 2);

      final focusedErrorBorder = inputTheme.focusedErrorBorder as OutlineInputBorder;
      expect(focusedErrorBorder.borderSide.color, theme.colorScheme.error);
      expect(focusedErrorBorder.borderSide.width, 2);
    });

    test('applies custom fontSize', () {
      final theme = AppTheme.highContrastLightTheme(fontSize: 20);
      expect(theme.textTheme.bodyLarge?.fontSize, 20.0);
    });

    test('largeTouchTargets affects minimum size', () {
      final largeStyle = AppTheme.highContrastLightTheme(largeTouchTargets: true).elevatedButtonTheme.style!;
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('AppTheme highContrastDarkTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.highContrastDarkTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.cardTheme.elevation, 2);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerHighest);
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(12));
      expect(cardShape.side.color, theme.colorScheme.outline);
      expect(cardShape.side.width, 1);
      expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
      expect(theme.dividerTheme.thickness, 2);
    });

    test('inputDecoration theme has configured borders with width 2', () {
      final theme = AppTheme.highContrastDarkTheme();
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());
      expect(inputTheme.errorBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedErrorBorder, isA<OutlineInputBorder>());
      expect(inputTheme.disabledBorder, isA<OutlineInputBorder>());

      final border = inputTheme.border as OutlineInputBorder;
      expect(border.borderSide.color, theme.colorScheme.outline);
      expect(border.borderSide.width, 2);

      final enabledBorder = inputTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, theme.colorScheme.outline);
      expect(enabledBorder.borderSide.width, 2);

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, theme.colorScheme.primary);
      expect(focusedBorder.borderSide.width, 2);

      final errorBorder = inputTheme.errorBorder as OutlineInputBorder;
      expect(errorBorder.borderSide.color, theme.colorScheme.error);
      expect(errorBorder.borderSide.width, 2);

      final focusedErrorBorder = inputTheme.focusedErrorBorder as OutlineInputBorder;
      expect(focusedErrorBorder.borderSide.color, theme.colorScheme.error);
      expect(focusedErrorBorder.borderSide.width, 2);
    });

    test('applies custom fontSize', () {
      final theme = AppTheme.highContrastDarkTheme(fontSize: 14);
      expect(theme.textTheme.bodyLarge?.fontSize, 14.0);
    });

    test('largeTouchTargets affects minimum size', () {
      final largeStyle = AppTheme.highContrastDarkTheme(largeTouchTargets: true).elevatedButtonTheme.style!;
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('AppTheme theme consistency', () {
    test('light and dark themes have same useMaterial3 setting', () {
      expect(
        AppTheme.lightTheme().useMaterial3,
        AppTheme.darkTheme().useMaterial3,
      );
    });

    test('light and dark themes have same card elevation', () {
      expect(
        AppTheme.lightTheme().cardTheme.elevation,
        AppTheme.darkTheme().cardTheme.elevation,
      );
    });

    test('light and dark themes have same card border radius', () {
      final lightShape =
          AppTheme.lightTheme().cardTheme.shape as RoundedRectangleBorder;
      final darkShape =
          AppTheme.darkTheme().cardTheme.shape as RoundedRectangleBorder;
      expect(lightShape.borderRadius, darkShape.borderRadius);
    });

    test('all four themes have same appBar elevation', () {
      expect(AppTheme.lightTheme().appBarTheme.elevation, 0);
      expect(AppTheme.darkTheme().appBarTheme.elevation, 0);
      expect(AppTheme.highContrastLightTheme().appBarTheme.elevation, 0);
      expect(AppTheme.highContrastDarkTheme().appBarTheme.elevation, 0);
    });

    test('both high contrast themes have card border side', () {
      final lightShape =
          AppTheme.highContrastLightTheme().cardTheme.shape
              as RoundedRectangleBorder;
      final darkShape =
          AppTheme.highContrastDarkTheme().cardTheme.shape
              as RoundedRectangleBorder;
      expect(lightShape.side, isNotNull);
      expect(darkShape.side, isNotNull);
    });

    test('high contrast themes have divider themes while normal themes do not', () {
      expect(AppTheme.highContrastLightTheme().dividerTheme.thickness, 2);
      expect(AppTheme.highContrastDarkTheme().dividerTheme.thickness, 2);
    });

    test('high contrast themes have card border side while normal themes have none', () {
      final hcLightShape =
          AppTheme.highContrastLightTheme().cardTheme.shape
              as RoundedRectangleBorder;
      final hcDarkShape =
          AppTheme.highContrastDarkTheme().cardTheme.shape
              as RoundedRectangleBorder;
      final lightShape =
          AppTheme.lightTheme().cardTheme.shape as RoundedRectangleBorder;
      final darkShape =
          AppTheme.darkTheme().cardTheme.shape as RoundedRectangleBorder;
      expect(hcLightShape.side.width, 1);
      expect(hcDarkShape.side.width, 1);
      expect(lightShape.side.width, 0);
      expect(darkShape.side.width, 0);
    });

    test('all themes use same bottomSheet shape', () {
      expect(AppTheme.lightTheme().bottomSheetTheme.shape, AppTheme.bottomSheetShape);
      expect(AppTheme.darkTheme().bottomSheetTheme.shape, AppTheme.bottomSheetShape);
      expect(AppTheme.highContrastLightTheme().bottomSheetTheme.shape, AppTheme.bottomSheetShape);
      expect(AppTheme.highContrastDarkTheme().bottomSheetTheme.shape, AppTheme.bottomSheetShape);
    });

    test('high contrast themes have card elevation 2 while normal themes have 0', () {
      expect(AppTheme.lightTheme().cardTheme.elevation, 0);
      expect(AppTheme.darkTheme().cardTheme.elevation, 0);
      expect(AppTheme.highContrastLightTheme().cardTheme.elevation, 2);
      expect(AppTheme.highContrastDarkTheme().cardTheme.elevation, 2);
    });

    test('light theme has different seed color from dark theme', () {
      final light = AppTheme.lightTheme();
      final dark = AppTheme.darkTheme();
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });
  });

  group('AppTheme edge cases', () {
    test('calling lightTheme multiple times returns consistent result', () {
      final theme1 = AppTheme.lightTheme();
      final theme2 = AppTheme.lightTheme();
      expect(theme1.scaffoldBackgroundColor, theme2.scaffoldBackgroundColor);
      expect(theme1.appBarTheme.elevation, theme2.appBarTheme.elevation);
    });

    test('calling darkTheme multiple times returns consistent result', () {
      final theme1 = AppTheme.darkTheme();
      final theme2 = AppTheme.darkTheme();
      expect(theme1.scaffoldBackgroundColor, theme2.scaffoldBackgroundColor);
      expect(theme1.appBarTheme.elevation, theme2.appBarTheme.elevation);
    });

    test('calling highContrastLightTheme multiple times returns consistent result', () {
      final theme1 = AppTheme.highContrastLightTheme();
      final theme2 = AppTheme.highContrastLightTheme();
      expect(theme1.cardTheme.elevation, theme2.cardTheme.elevation);
      expect(theme1.dividerTheme.thickness, theme2.dividerTheme.thickness);
    });

    test('calling highContrastDarkTheme multiple times returns consistent result', () {
      final theme1 = AppTheme.highContrastDarkTheme();
      final theme2 = AppTheme.highContrastDarkTheme();
      expect(theme1.cardTheme.elevation, theme2.cardTheme.elevation);
      expect(theme1.dividerTheme.thickness, theme2.dividerTheme.thickness);
    });

    test('themes are different instances', () {
      final light = AppTheme.lightTheme();
      final dark = AppTheme.darkTheme();
      final hcLight = AppTheme.highContrastLightTheme();
      final hcDark = AppTheme.highContrastDarkTheme();
      expect(identical(light, dark), isFalse);
      expect(identical(light, hcLight), isFalse);
      expect(identical(dark, hcDark), isFalse);
    });

    test('all themes return non-null ThemeData', () {
      expect(AppTheme.lightTheme(), isA<ThemeData>());
      expect(AppTheme.darkTheme(), isA<ThemeData>());
      expect(AppTheme.highContrastLightTheme(), isA<ThemeData>());
      expect(AppTheme.highContrastDarkTheme(), isA<ThemeData>());
    });

    test('createTextTheme with zero fontSize', () {
      final textTheme = AppTheme.createTextTheme(0);
      expect(textTheme.displayLarge?.fontSize, 0);
      expect(textTheme.bodyLarge?.fontSize, 0);
    });

    test('createTextTheme with negative fontSize', () {
      final textTheme = AppTheme.createTextTheme(-10);
      expect(textTheme.displayLarge?.fontSize, -25.0);
      expect(textTheme.bodyLarge?.fontSize, -10.0);
    });

    test('createTextTheme with large fontSize', () {
      final textTheme = AppTheme.createTextTheme(100);
      expect(textTheme.displayLarge?.fontSize, 250.0);
      expect(textTheme.bodyLarge?.fontSize, 100.0);
    });
  });
}
