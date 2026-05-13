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

  group('AppTheme lightTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.lightTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
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
  });

  group('AppTheme darkTheme', () {
    test('builds expected ThemeData values', () {
      final theme = AppTheme.darkTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
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

    test('uses correct seed color', () {
      final theme = AppTheme.darkTheme();
      expect(theme.colorScheme.primary, isNotNull);
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

    test('inputDecoration theme has configured borders', () {
      final theme = AppTheme.highContrastLightTheme();
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());

      final border = inputTheme.border as OutlineInputBorder;
      expect(border.borderSide.color, theme.colorScheme.outline);
      expect(border.borderSide.width, 2);

      final enabledBorder = inputTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, theme.colorScheme.outline);
      expect(enabledBorder.borderSide.width, 2);

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, theme.colorScheme.primary);
      expect(focusedBorder.borderSide.width, 2);
    });

    test('applies custom fontSize', () {
      final theme = AppTheme.highContrastLightTheme(fontSize: 20);
      expect(theme.textTheme.bodyLarge?.fontSize, 20.0);
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

    test('inputDecoration theme has configured borders', () {
      final theme = AppTheme.highContrastDarkTheme();
      final inputTheme = theme.inputDecorationTheme;

      expect(inputTheme.border, isA<OutlineInputBorder>());
      expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());

      final border = inputTheme.border as OutlineInputBorder;
      expect(border.borderSide.color, theme.colorScheme.outline);
      expect(border.borderSide.width, 2);

      final enabledBorder = inputTheme.enabledBorder as OutlineInputBorder;
      expect(enabledBorder.borderSide.color, theme.colorScheme.outline);
      expect(enabledBorder.borderSide.width, 2);

      final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, theme.colorScheme.primary);
      expect(focusedBorder.borderSide.width, 2);
    });

    test('applies custom fontSize', () {
      final theme = AppTheme.highContrastDarkTheme(fontSize: 14);
      expect(theme.textTheme.bodyLarge?.fontSize, 14.0);
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
  });

  group('AppTheme widget behavior', () {
    testWidgets('light theme applies scaffold and app bar settings', (
      WidgetTester tester,
    ) async {
      late ThemeData resolvedTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
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

      expect(resolvedTheme.scaffoldBackgroundColor, resolvedTheme.colorScheme.surface);
      expect(resolvedTheme.appBarTheme.centerTitle, isFalse);
      expect(resolvedTheme.appBarTheme.elevation, 0);
    });

    testWidgets('dark theme applies scaffold and app bar settings', (
      WidgetTester tester,
    ) async {
      late ThemeData resolvedTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
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

      expect(resolvedTheme.scaffoldBackgroundColor, resolvedTheme.colorScheme.surface);
      expect(resolvedTheme.appBarTheme.centerTitle, isFalse);
      expect(resolvedTheme.appBarTheme.elevation, 0);
    });

    testWidgets('high contrast light theme applies card border', (
      WidgetTester tester,
    ) async {
      late ThemeData resolvedTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastLightTheme(),
          home: Builder(
            builder: (context) {
              resolvedTheme = Theme.of(context);
              return Scaffold(
              body: Card(
                  child: SizedBox(width: 100, height: 100),
                ),
              );
            },
          ),
        ),
      );

      final shape = resolvedTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.width, 1);
    });

    testWidgets('high contrast dark theme applies card border', (
      WidgetTester tester,
    ) async {
      late ThemeData resolvedTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastDarkTheme(),
          home: Builder(
            builder: (context) {
              resolvedTheme = Theme.of(context);
              return Scaffold(
                body: Card(
                  child: SizedBox(width: 100, height: 100),
                ),
              );
            },
          ),
        ),
      );

      final shape = resolvedTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.width, 1);
    });
  });

  group('AppTheme widget component tests', () {
    testWidgets('light theme card renders with correct elevation', (
      WidgetTester tester,
    ) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Builder(
            builder: (context) {
              themeData = Theme.of(context);
              return const Scaffold(
                body: Card(
                  child: SizedBox(width: 100, height: 100),
                ),
              );
            },
          ),
        ),
      );

      expect(themeData.cardTheme.elevation, 0);
    });

    testWidgets('dark theme card renders with correct elevation', (
      WidgetTester tester,
    ) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Builder(
            builder: (context) {
              themeData = Theme.of(context);
              return const Scaffold(
                body: Card(
                  child: SizedBox(width: 100, height: 100),
                ),
              );
            },
          ),
        ),
      );

      expect(themeData.cardTheme.elevation, 0);
    });

    testWidgets('light theme elevated button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('dark theme elevated button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Test'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('light theme FAB renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('dark theme FAB renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('high contrast light theme FAB renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastLightTheme(),
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('high contrast dark theme FAB renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastDarkTheme(),
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('navigation bar renders with light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
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

    testWidgets('theme works with nested widgets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Column(
              children: [
                Card(child: SizedBox(width: 50, height: 50)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Button'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('high contrast theme works with nested widgets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastLightTheme(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Column(
              children: [
                Card(child: SizedBox(width: 50, height: 50)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Button'),
                ),
                FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
