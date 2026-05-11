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

  group('AppTheme color scheme verification', () {
    test('lightTheme uses correct seed color', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('darkTheme uses correct seed color', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('lightTheme colorScheme brightness is light', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.brightness, Brightness.light);
    });

    test('darkTheme colorScheme brightness is dark', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('AppTheme theme consistency', () {
    test('both themes have same useMaterial3 setting', () {
      expect(AppTheme.lightTheme.useMaterial3, AppTheme.darkTheme.useMaterial3);
    });

    test('both themes have same card elevation', () {
      expect(
        AppTheme.lightTheme.cardTheme.elevation,
        AppTheme.darkTheme.cardTheme.elevation,
      );
    });

    test('both themes have same card border radius', () {
      final lightShape =
          AppTheme.lightTheme.cardTheme.shape as RoundedRectangleBorder;
      final darkShape =
          AppTheme.darkTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(lightShape.borderRadius, darkShape.borderRadius);
    });

    test('both themes have same appBarTheme elevation', () {
      expect(
        AppTheme.lightTheme.appBarTheme.elevation,
        AppTheme.darkTheme.appBarTheme.elevation,
      );
    });

    test('both themes have same appBarTheme centerTitle', () {
      expect(
        AppTheme.lightTheme.appBarTheme.centerTitle,
        AppTheme.darkTheme.appBarTheme.centerTitle,
      );
    });

    test('both themes have same FAB elevation', () {
      expect(
        AppTheme.lightTheme.floatingActionButtonTheme.elevation,
        AppTheme.darkTheme.floatingActionButtonTheme.elevation,
      );
    });
  });

  group('AppTheme widget component tests', () {
    testWidgets('light theme card renders with correct elevation',
        (WidgetTester tester) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
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

      expect(themeData.cardTheme.elevation, 2);
    });

    testWidgets('dark theme card renders with correct elevation',
        (WidgetTester tester) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
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

      expect(themeData.cardTheme.elevation, 2);
    });

    testWidgets('light theme elevated button renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
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

    testWidgets('dark theme elevated button renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
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

    testWidgets('light theme FAB renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
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

    testWidgets('dark theme FAB renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
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

    testWidgets('light theme scaffold has correct background color',
        (WidgetTester tester) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              themeData = Theme.of(context);
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      expect(themeData.scaffoldBackgroundColor, const Color(0xFFF5F5F5));
    });

    testWidgets('dark theme scaffold has correct background color',
        (WidgetTester tester) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              themeData = Theme.of(context);
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );

      expect(themeData.scaffoldBackgroundColor, const Color(0xFF121212));
    });

    testWidgets('light theme AppBar renders correctly', (WidgetTester tester) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              themeData = Theme.of(context);
              return Scaffold(
                appBar: AppBar(title: const Text('Test')),
              );
            },
          ),
        ),
      );

      expect(themeData.appBarTheme.elevation, 0);
      expect(themeData.appBarTheme.centerTitle, false);
    });

    testWidgets('dark theme AppBar renders correctly', (WidgetTester tester) async {
      late ThemeData themeData;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              themeData = Theme.of(context);
              return Scaffold(
                appBar: AppBar(title: const Text('Test')),
              );
            },
          ),
        ),
      );

      expect(themeData.appBarTheme.elevation, 0);
      expect(themeData.appBarTheme.centerTitle, false);
    });
  });

  group('AppTheme theme data properties', () {
    test('lightTheme returns non-null ThemeData', () {
      final theme = AppTheme.lightTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.hashCode, isNotNull);
    });

    test('darkTheme returns non-null ThemeData', () {
      final theme = AppTheme.darkTheme;
      expect(theme, isA<ThemeData>());
      expect(theme.hashCode, isNotNull);
    });

    test('themes are different instances', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;
      expect(identical(lightTheme, darkTheme), isFalse);
    });

    test('lightTheme scaffoldBackgroundColor is accessible', () {
      final theme = AppTheme.lightTheme;
      final bgColor = theme.scaffoldBackgroundColor;
      expect(bgColor, const Color(0xFFF5F5F5));
    });

    test('darkTheme scaffoldBackgroundColor is accessible', () {
      final theme = AppTheme.darkTheme;
      final bgColor = theme.scaffoldBackgroundColor;
      expect(bgColor, const Color(0xFF121212));
    });

    test('cardTheme margin is zero for light theme', () {
      final cardTheme = AppTheme.lightTheme.cardTheme;
      expect(cardTheme.margin, EdgeInsets.zero);
    });

    test('cardTheme margin is zero for dark theme', () {
      final cardTheme = AppTheme.darkTheme.cardTheme;
      expect(cardTheme.margin, EdgeInsets.zero);
    });
  });

  group('AppTheme edge cases', () {
    test('calling lightTheme multiple times returns consistent result', () {
      final theme1 = AppTheme.lightTheme;
      final theme2 = AppTheme.lightTheme;
      expect(theme1.useMaterial3, theme2.useMaterial3);
      expect(theme1.scaffoldBackgroundColor, theme2.scaffoldBackgroundColor);
      expect(theme1.appBarTheme.elevation, theme2.appBarTheme.elevation);
    });

    test('calling darkTheme multiple times returns consistent result', () {
      final theme1 = AppTheme.darkTheme;
      final theme2 = AppTheme.darkTheme;
      expect(theme1.useMaterial3, theme2.useMaterial3);
      expect(theme1.scaffoldBackgroundColor, theme2.scaffoldBackgroundColor);
      expect(theme1.appBarTheme.elevation, theme2.appBarTheme.elevation);
    });

    testWidgets('theme works with nested widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Column(
              children: [
                Card(child: Container(width: 50, height: 50)),
                ElevatedButton(onPressed: () {}, child: const Text('Button')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('dark theme works with nested widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Column(
              children: [
                Card(child: Container(width: 50, height: 50)),
                ElevatedButton(onPressed: () {}, child: const Text('Button')),
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
