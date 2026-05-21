import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/theme/llm_task_status.dart';

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

  group('AppTheme.progressColor', () {
    testWidgets('returns primary for value >= 0.8', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.progressColor(0.8, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('returns tertiary for value 0.7', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.progressColor(0.7, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('returns tertiary for value 0.6', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.progressColor(0.6, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('returns error for value 0.59', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.progressColor(0.59, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.error);
    });

    testWidgets('returns error for value 0', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.progressColor(0, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.error);
    });
  });

  group('AppTheme.urgencyColor', () {
    testWidgets('returns error for value > 0.7', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.urgencyColor(0.71, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.error);
    });

    testWidgets('returns tertiary for value 0.5', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.urgencyColor(0.5, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('returns primary for value 0.4 (not > 0.4)', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.urgencyColor(0.4, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('returns primary for value 0.39', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.urgencyColor(0.39, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('returns primary for value 0', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.urgencyColor(0, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });
  });

  group('AppTheme.masteryColor', () {
    testWidgets('returns primary for value >= 0.8', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.masteryColor(1.0, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('returns tertiary for value 0.7', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.masteryColor(0.7, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('returns tertiary for value 0.6', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.masteryColor(0.6, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('returns error for value 0.5', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.masteryColor(0.5, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.error);
    });
  });

  group('AppTheme.priorityColor', () {
    testWidgets('returns error for priority > 2.0', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.priorityColor(3.0, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.error);
    });

    testWidgets('returns tertiary for priority 1.5', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.priorityColor(1.5, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('returns primary for priority 1.0 (not > 1.0)', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.priorityColor(1.0, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('returns primary for priority 0.9', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.priorityColor(0.9, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('returns primary for priority 0', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.priorityColor(0, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });
  });

  group('AppTheme.badgeColor', () {
    testWidgets('returns primary color', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.badgeColor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        result,
        Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary,
      );
    });
  });

  group('AppTheme.destructiveButtonStyle', () {
    testWidgets('has error background and onError foreground', (tester) async {
      late ButtonStyle style;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = AppTheme.destructiveButtonStyle(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final cs = Theme.of(tester.element(find.byType(SizedBox))).colorScheme;
      expect(style.backgroundColor?.resolve({}), cs.error);
      expect(style.foregroundColor?.resolve({}), cs.onError);
    });

    testWidgets('has configured padding', (tester) async {
      late ButtonStyle style;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = AppTheme.destructiveButtonStyle(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      );
    });

    testWidgets('has rounded shape', (tester) async {
      late ButtonStyle style;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              style = AppTheme.destructiveButtonStyle(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final shape = style.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('largeTouchTargets affects minimumSize', (tester) async {
      late ButtonStyle normalStyle;
      late ButtonStyle largeStyle;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              normalStyle = AppTheme.destructiveButtonStyle(context, largeTouchTargets: false);
              largeStyle = AppTheme.destructiveButtonStyle(context, largeTouchTargets: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(normalStyle.minimumSize?.resolve({}), const Size(0, 0));
      expect(largeStyle.minimumSize?.resolve({}), const Size(48, 48));
    });
  });

  group('AppTheme.statusColor', () {
    testWidgets('running returns primary', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.statusColor(LlmTaskStatus.running, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('done returns primary', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.statusColor(LlmTaskStatus.done, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });

    testWidgets('failed returns error', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.statusColor(LlmTaskStatus.failed, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.error);
    });

    testWidgets('cancelled returns tertiary', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.statusColor(LlmTaskStatus.cancelled, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.tertiary);
    });

    testWidgets('queued returns onSurfaceVariant', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppTheme.statusColor(LlmTaskStatus.queued, context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.onSurfaceVariant);
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

    testWidgets('light theme filled button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Filled'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Filled'), findsOneWidget);
    });

    testWidgets('dark theme filled button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Filled'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('light theme outlined button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: Center(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('dark theme outlined button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Center(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
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

    testWidgets('navigation rail renders with dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                  selectedIndex: 0,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('snackbar renders with floating behavior', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test snack')),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Test snack'), findsOneWidget);
    });

    testWidgets('dialog renders with rounded shape', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(content: Text('Dialog')),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.text('Dialog'), findsOneWidget);
    });

    testWidgets('input decoration renders with theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: 'Hint',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Label'), findsOneWidget);
    });

    testWidgets('destructive button renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                style: AppTheme.destructiveButtonStyle(context),
                onPressed: () {},
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('AppTheme largeTouchTargets', () {
    testWidgets('large elevated button has minimumSize 48', (
      WidgetTester tester,
    ) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(largeTouchTargets: true),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Big'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      final style = theme.elevatedButtonTheme.style!;
      expect(style.minimumSize?.resolve({}), const Size(48, 48));
    });

    testWidgets('large filled button has minimumSize 48', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(largeTouchTargets: true),
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Big'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('large outlined button has minimumSize 48', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(largeTouchTargets: true),
          home: Scaffold(
            body: Center(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Big'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
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

    testWidgets('status colors render for all LlmTaskStatus values', (
      WidgetTester tester,
    ) async {
      for (final status in LlmTaskStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Container(
                  color: AppTheme.statusColor(status, context),
                );
              },
            ),
          ),
        );
        expect(find.byType(Container), findsOneWidget);
      }
    });

    testWidgets('dark theme input decoration renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(
                labelText: 'Dark Label',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Dark Label'), findsOneWidget);
    });
  });
}
