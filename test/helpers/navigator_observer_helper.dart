import 'package:flutter/material.dart';

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];
  final void Function(Route<dynamic> route)? onPush;

  TestNavigatorObserver({this.onPush});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    onPush?.call(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
  }

  void reset() {
    pushedRoutes.clear();
    poppedRoutes.clear();
  }
}
