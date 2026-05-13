import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/quickguide.dart';

void main() {
  group('QuickGuide barrel export', () {
    test('quickguide.dart exports QuickGuideScreen', () {
      expect(QuickGuideScreen, isA<Type>());
    });
  });
}
