import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/theme/app_theme.dart';

void main() {
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
