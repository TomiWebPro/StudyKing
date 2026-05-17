import 'package:flutter/material.dart';

import 'app_router.dart';

class TabNavigator extends StatelessWidget {
  final Widget rootScreen;
  final GlobalKey<NavigatorState> navigatorKey;
  final Route<dynamic>? Function(RouteSettings)? customOnGenerateRoute;
  final List<NavigatorObserver>? observers;

  const TabNavigator({
    super.key,
    required this.rootScreen,
    required this.navigatorKey,
    this.customOnGenerateRoute,
    this.observers,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => rootScreen,
            settings: const RouteSettings(name: '/'),
          );
        }
        final generator = customOnGenerateRoute ?? onGenerateRoute;
        return generator(settings);
      },
      observers: observers ?? [],
    );
  }
}
