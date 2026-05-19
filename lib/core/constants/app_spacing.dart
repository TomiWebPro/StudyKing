import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const SizedBox gapXxs = SizedBox(height: xxs, width: xxs);
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  static const EdgeInsets symH8V4 = EdgeInsets.symmetric(horizontal: sm, vertical: xs);
  static const EdgeInsets symH16V8 = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets symH16V12 = EdgeInsets.symmetric(horizontal: md, vertical: 12);
  static const EdgeInsets symH24V12 = EdgeInsets.symmetric(horizontal: lg, vertical: 12);

  static const EdgeInsets onlyB8 = EdgeInsets.only(bottom: sm);
  static const EdgeInsets onlyB16 = EdgeInsets.only(bottom: md);
}
