import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static BorderRadius get circularXs => BorderRadius.circular(xs);
  static BorderRadius get circularSm => BorderRadius.circular(sm);
  static BorderRadius get circularMd => BorderRadius.circular(md);
  static BorderRadius get circularLg => BorderRadius.circular(lg);
  static BorderRadius get circularXl => BorderRadius.circular(xl);

  static RoundedRectangleBorder roundedSm = RoundedRectangleBorder(
    borderRadius: circularSm,
  );
  static RoundedRectangleBorder roundedMd = RoundedRectangleBorder(
    borderRadius: circularMd,
  );
  static RoundedRectangleBorder roundedLg = RoundedRectangleBorder(
    borderRadius: circularLg,
  );
}

class AppFontSize {
  AppFontSize._();

  static const double xs = 10;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double display = 24;
}
