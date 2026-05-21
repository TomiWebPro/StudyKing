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

  static RoundedRectangleBorder get roundedSm => RoundedRectangleBorder(
    borderRadius: circularSm,
  );
  static RoundedRectangleBorder get roundedMd => RoundedRectangleBorder(
    borderRadius: circularMd,
  );
  static RoundedRectangleBorder get roundedLg => RoundedRectangleBorder(
    borderRadius: circularLg,
  );
}


