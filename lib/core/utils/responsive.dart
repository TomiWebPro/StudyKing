import 'package:flutter/material.dart';

enum ScreenBreakpoint {
  xs,
  sm,
  md,
  lg;

  bool get isXs => this == ScreenBreakpoint.xs;
  bool get isSm => this == ScreenBreakpoint.sm;
  bool get isMd => this == ScreenBreakpoint.md;
  bool get isLg => this == ScreenBreakpoint.lg;
  bool get isMobile => this == ScreenBreakpoint.xs || this == ScreenBreakpoint.sm;
  bool get isTablet => this == ScreenBreakpoint.md || this == ScreenBreakpoint.lg;
}

class ResponsiveUtils {
  static const double xsMax = 600;
  static const double smMax = 840;
  static const double mdMax = 1200;

  static ScreenBreakpoint breakpointOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < xsMax) return ScreenBreakpoint.xs;
    if (width < smMax) return ScreenBreakpoint.sm;
    if (width < mdMax) return ScreenBreakpoint.md;
    return ScreenBreakpoint.lg;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return const EdgeInsets.all(12);
      case ScreenBreakpoint.sm:
        return const EdgeInsets.all(16);
      case ScreenBreakpoint.md:
        return const EdgeInsets.all(24);
      case ScreenBreakpoint.lg:
        return const EdgeInsets.all(32);
    }
  }

  static EdgeInsets listPadding(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ScreenBreakpoint.sm:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ScreenBreakpoint.md:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ScreenBreakpoint.lg:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  static EdgeInsets cardPadding(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return const EdgeInsets.all(12);
      case ScreenBreakpoint.sm:
        return const EdgeInsets.all(16);
      case ScreenBreakpoint.md:
        return const EdgeInsets.all(20);
      case ScreenBreakpoint.lg:
        return const EdgeInsets.all(24);
    }
  }

  static int gridCrossAxisCount(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return 2;
      case ScreenBreakpoint.sm:
        return 3;
      case ScreenBreakpoint.md:
        return 4;
      case ScreenBreakpoint.lg:
        return 4;
    }
  }

  static double horizontalSpacing(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return 8;
      case ScreenBreakpoint.sm:
        return 12;
      case ScreenBreakpoint.md:
        return 16;
      case ScreenBreakpoint.lg:
        return 20;
    }
  }

  static double verticalSpacing(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return 8;
      case ScreenBreakpoint.sm:
        return 12;
      case ScreenBreakpoint.md:
        return 16;
      case ScreenBreakpoint.lg:
        return 20;
    }
  }

  static double emptyStateIconSize(BuildContext context) {
    final bp = breakpointOf(context);
    switch (bp) {
      case ScreenBreakpoint.xs:
        return 64;
      case ScreenBreakpoint.sm:
        return 80;
      case ScreenBreakpoint.md:
        return 96;
      case ScreenBreakpoint.lg:
        return 96;
    }
  }

  static const double minTouchTarget = 48.0;

  static Widget ensureMinTouchTarget({required Widget child, VoidCallback? onTap}) {
    return Semantics(
      button: onTap != null,
      child: SizedBox(
        width: minTouchTarget,
        height: minTouchTarget,
        child: child,
      ),
    );
  }

  static Widget loaderInTouchTarget({double size = 20, double strokeWidth = 2}) {
    return SizedBox(
      width: minTouchTarget,
      height: minTouchTarget,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: strokeWidth),
        ),
      ),
    );
  }
}

extension ResponsiveContext on BuildContext {
  ScreenBreakpoint get breakpoint => ResponsiveUtils.breakpointOf(this);
  EdgeInsets get screenPadding => ResponsiveUtils.screenPadding(this);
  EdgeInsets get listPadding => ResponsiveUtils.listPadding(this);
  EdgeInsets get cardPadding => ResponsiveUtils.cardPadding(this);
}
