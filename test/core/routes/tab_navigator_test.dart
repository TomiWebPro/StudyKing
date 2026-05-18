import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/routes/tab_navigator.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../helpers/navigator_observer_helper.dart';

Route<dynamic>? _testRouteGenerator(RouteSettings settings) {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text('Route: ${settings.name}')),
      body: Center(child: Text('${settings.name} screen')),
    ),
    settings: settings,
  );
}

Widget _buildTestApp({
  required GlobalKey<NavigatorState> navigatorKey,
  required Widget rootScreen,
  TestNavigatorObserver? observer,
}) {
  return MaterialApp(
    home: TabNavigator(
      navigatorKey: navigatorKey,
      rootScreen: rootScreen,
      customOnGenerateRoute: _testRouteGenerator,
      observers: observer != null ? [observer] : [],
    ),
  );
}

Widget _buildTestAppNoCustomRoute({
  required GlobalKey<NavigatorState> navigatorKey,
  required Widget rootScreen,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: TabNavigator(
      navigatorKey: navigatorKey,
      rootScreen: rootScreen,
    ),
  );
}

void main() {
  group('TabNavigator', () {
    testWidgets('shows root screen at initial route', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _buildTestApp(
          navigatorKey: key,
          rootScreen: const Scaffold(
            body: Text('Root Screen'),
          ),
        ),
      );

      expect(find.text('Root Screen'), findsOneWidget);
    });

    testWidgets('pushes named route via custom route generator',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(
        _buildTestApp(
          navigatorKey: key,
          observer: observer,
          rootScreen: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/test-route'),
                child: const Text('Go to Route'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Route'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(1));
      expect(
        observer.pushedRoutes.last.settings.name,
        equals('/test-route'),
      );
      expect(find.text('/test-route screen'), findsOneWidget);
    });

    testWidgets('pops route within tab navigator', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = TestNavigatorObserver();
      await tester.pumpWidget(
        _buildTestApp(
          navigatorKey: key,
          observer: observer,
          rootScreen: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/test-route'),
                child: const Text('Go to Route'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Route'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(observer.pushedRoutes.length, greaterThanOrEqualTo(2));

      key.currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.poppedRoutes, hasLength(1));
      expect(find.text('Go to Route'), findsOneWidget);
    });

    testWidgets('multiple pushes preserve route stack', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _buildTestApp(
          navigatorKey: key,
          rootScreen: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/route-a'),
                child: const Text('Route A'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Route A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      key.currentState?.pushNamed('/route-b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(key.currentState?.canPop(), isTrue);
      key.currentState?.pop();
      await tester.pump(const Duration(milliseconds: 300));
      expect(key.currentState?.canPop(), isTrue);

      key.currentState?.pop();
      await tester.pump(const Duration(milliseconds: 300));
      expect(key.currentState?.canPop(), isFalse);
    });

    testWidgets('falls back to default onGenerateRoute when custom is null',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _buildTestAppNoCustomRoute(
          navigatorKey: key,
          rootScreen: const Scaffold(body: Text('Default Root')),
        ),
      );

      expect(find.text('Default Root'), findsOneWidget);
      expect(key.currentState, isNotNull);
    });

    testWidgets('works without observers (defaults to empty list)',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: key,
            rootScreen: const Scaffold(body: Text('No Observers')),
          ),
        ),
      );

      expect(find.text('No Observers'), findsOneWidget);
      expect(key.currentState, isNotNull);
    });

    testWidgets('pushing unknown route with default fallback shows NotFoundScreen',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _buildTestAppNoCustomRoute(
          navigatorKey: key,
          rootScreen: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/unknown-route'),
                child: const Text('Push Unknown'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Unknown'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(key.currentState?.canPop(), isTrue);
    });

    testWidgets('initial route settings have name "/"', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _buildTestApp(
          navigatorKey: key,
          rootScreen: const Scaffold(body: Text('Root')),
        ),
      );

      expect(find.text('Root'), findsOneWidget);
    });

    testWidgets('sets navigator key correctly', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _buildTestApp(
          navigatorKey: key,
          rootScreen: const Scaffold(body: Text('Root')),
        ),
      );

      expect(key.currentState, isNotNull);
      expect(key.currentState, isA<NavigatorState>());
    });

    testWidgets('accepts and notifies multiple observers', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer1 = TestNavigatorObserver();
      final observer2 = TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: key,
            rootScreen: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/test-route'),
                  child: const Text('Push'),
                ),
              ),
            ),
            customOnGenerateRoute: _testRouteGenerator,
            observers: [observer1, observer2],
          ),
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer1.pushedRoutes, hasLength(greaterThanOrEqualTo(1)));
      expect(observer2.pushedRoutes, hasLength(greaterThanOrEqualTo(1)));
      expect(
        observer1.pushedRoutes.last.settings.name,
        equals('/test-route'),
      );
      expect(
        observer2.pushedRoutes.last.settings.name,
        equals('/test-route'),
      );
    });

    testWidgets('pushes route needing args without args via default generator',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TabNavigator(
            navigatorKey: key,
            rootScreen: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.subjectDetail),
                  child: const Text('Push Subject'),
                ),
              ),
            ),
            observers: [observer],
          ),
        ),
      );

      await tester.tap(find.text('Push Subject'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRoutes, hasLength(greaterThanOrEqualTo(1)));
      expect(
        observer.pushedRoutes.last.settings.name,
        AppRoutes.subjectDetail,
      );
      expect(key.currentState?.canPop(), isTrue);
    });

    testWidgets('pushes known route without args via default generator',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      final observer = TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TabNavigator(
            navigatorKey: key,
            rootScreen: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                  child: const Text('Settings'),
                ),
              ),
            ),
            observers: [observer],
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(observer.pushedRoutes, hasLength(greaterThanOrEqualTo(1)));
      expect(
        observer.pushedRoutes.last.settings.name,
        AppRoutes.settings,
      );
      expect(key.currentState?.canPop(), isTrue);
    });

    testWidgets('tab navigator isolation - two navigators dont interfere',
        (tester) async {
      final key1 = GlobalKey<NavigatorState>();
      final key2 = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              SizedBox(
                height: 300,
                child: TabNavigator(
                  navigatorKey: key1,
                  customOnGenerateRoute: _testRouteGenerator,
                  rootScreen: Scaffold(
                    body: Builder(
                      builder: (context) => ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/push'),
                        child: const Text('Tab1 Push'),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: TabNavigator(
                  navigatorKey: key2,
                  customOnGenerateRoute: _testRouteGenerator,
                  rootScreen: const Scaffold(
                    body: Text('Tab2 Root'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Tab1 Push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(key1.currentState?.canPop(), isTrue);
      expect(key2.currentState?.canPop(), isFalse);
    });
  });

  group('TabNavigator with IndexedStack', () {
    testWidgets('pushed routes preserved when switching tabs',
        (tester) async {
      final keys = List.generate(2, (_) => GlobalKey<NavigatorState>());
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setInnerState) => Scaffold(
              body: IndexedStack(
                index: selectedIndex,
                children: [
                  TabNavigator(
                    navigatorKey: keys[0],
                    customOnGenerateRoute: _testRouteGenerator,
                    rootScreen: Scaffold(
                      body: Builder(
                        builder: (ctx) => ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(ctx, '/pushed'),
                          child: const Text('Tab0 Push'),
                        ),
                      ),
                    ),
                  ),
                  TabNavigator(
                    navigatorKey: keys[1],
                    customOnGenerateRoute: _testRouteGenerator,
                    rootScreen: const Scaffold(
                      body: Text('Tab1 Root'),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setInnerState(() {
                    selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.school),
                    label: 'Tab0',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.play_arrow),
                    label: 'Tab1',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tab0 Push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(keys[0].currentState?.canPop(), isTrue);

      await tester.tap(find.text('Tab1'));
      await tester.pump();

      expect(keys[1].currentState?.canPop(), isFalse);

      await tester.tap(find.text('Tab0'));
      await tester.pump();

      expect(keys[0].currentState?.canPop(), isTrue);

      keys[0].currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(keys[0].currentState?.canPop(), isFalse);
    });

    testWidgets('deep navigation preserved across tab switch',
        (tester) async {
      final keys = List.generate(2, (_) => GlobalKey<NavigatorState>());
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setInnerState) => Scaffold(
              body: IndexedStack(
                index: selectedIndex,
                children: [
                  TabNavigator(
                    navigatorKey: keys[0],
                    customOnGenerateRoute: _testRouteGenerator,
                    rootScreen: Scaffold(
                      body: Builder(
                        builder: (ctx) => ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(ctx, '/level-1'),
                          child: const Text('Level 0'),
                        ),
                      ),
                    ),
                  ),
                  TabNavigator(
                    navigatorKey: keys[1],
                    customOnGenerateRoute: _testRouteGenerator,
                    rootScreen: const Scaffold(
                      body: Text('Tab1 Root'),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setInnerState(() {
                    selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.school),
                    label: 'Tab0',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.play_arrow),
                    label: 'Tab1',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Level 0'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      keys[0].currentState?.pushNamed('/level-2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(keys[0].currentState?.canPop(), isTrue);

      await tester.tap(find.text('Tab1'));
      await tester.pump();

      await tester.tap(find.text('Tab0'));
      await tester.pump();

      expect(keys[0].currentState?.canPop(), isTrue);

      keys[0].currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(keys[0].currentState?.canPop(), isTrue);

      keys[0].currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(keys[0].currentState?.canPop(), isFalse);
      expect(find.text('Level 0'), findsOneWidget);
    });
  });

  group('TabNavigator with Offstage + TickerMode', () {
    testWidgets('pushed routes preserved when switching tabs',
        (tester) async {
      final keys = List.generate(2, (_) => GlobalKey<NavigatorState>());
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setInnerState) => Scaffold(
              body: Stack(
                children: [
                  for (int i = 0; i < keys.length; i++)
                    Offstage(
                      offstage: i != selectedIndex,
                      child: TickerMode(
                        enabled: i == selectedIndex,
                        child: TabNavigator(
                          navigatorKey: keys[i],
                          customOnGenerateRoute: _testRouteGenerator,
                          rootScreen: i == 0
                              ? Scaffold(
                                  body: Builder(
                                    builder: (ctx) => ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pushNamed(ctx, '/pushed'),
                                      child: const Text('Tab0 Push'),
                                    ),
                                  ),
                                )
                              : const Scaffold(
                                  body: Text('Tab1 Root'),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setInnerState(() {
                    selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.school),
                    label: 'Tab0',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.play_arrow),
                    label: 'Tab1',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tab0 Push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(keys[0].currentState?.canPop(), isTrue);

      await tester.tap(find.text('Tab1'));
      await tester.pump();

      expect(keys[1].currentState?.canPop(), isFalse);

      await tester.tap(find.text('Tab0'));
      await tester.pump();

      expect(keys[0].currentState?.canPop(), isTrue);

      keys[0].currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(keys[0].currentState?.canPop(), isFalse);
    });

    testWidgets('deep navigation preserved across tab switch',
        (tester) async {
      final keys = List.generate(2, (_) => GlobalKey<NavigatorState>());
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setInnerState) => Scaffold(
              body: Stack(
                children: [
                  for (int i = 0; i < keys.length; i++)
                    Offstage(
                      offstage: i != selectedIndex,
                      child: TickerMode(
                        enabled: i == selectedIndex,
                        child: TabNavigator(
                          navigatorKey: keys[i],
                          customOnGenerateRoute: _testRouteGenerator,
                          rootScreen: i == 0
                              ? Scaffold(
                                  body: Builder(
                                    builder: (ctx) => ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pushNamed(ctx, '/level-1'),
                                      child: const Text('Level 0'),
                                    ),
                                  ),
                                )
                              : const Scaffold(
                                  body: Text('Tab1 Root'),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setInnerState(() {
                    selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.school),
                    label: 'Tab0',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.play_arrow),
                    label: 'Tab1',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Level 0'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      keys[0].currentState?.pushNamed('/level-2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(keys[0].currentState?.canPop(), isTrue);

      await tester.tap(find.text('Tab1'));
      await tester.pump();

      await tester.tap(find.text('Tab0'));
      await tester.pump();

      expect(keys[0].currentState?.canPop(), isTrue);

      keys[0].currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(keys[0].currentState?.canPop(), isTrue);

      keys[0].currentState?.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(keys[0].currentState?.canPop(), isFalse);
      expect(find.text('Level 0'), findsOneWidget);
    });
  });
}
