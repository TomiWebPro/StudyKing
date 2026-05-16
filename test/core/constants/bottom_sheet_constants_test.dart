import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/bottom_sheet_constants.dart';

void main() {
  group('bottomSheetShape', () {
    test('has correct border radius', () {
      final border = bottomSheetShape;
      expect(border, isA<RoundedRectangleBorder>());
      expect(border.borderRadius, isA<BorderRadius>());
      final radius = border.borderRadius as BorderRadius;
      expect(radius.topLeft.x, equals(20));
      expect(radius.topRight.x, equals(20));
    });
  });
}
