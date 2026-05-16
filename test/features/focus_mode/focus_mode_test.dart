import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/focus_mode/focus_mode.dart';

void main() {
  group('focus_mode barrel', () {
    test('exports FocusTimerScreen', () {
      expect(FocusTimerScreen, isA<Type>());
    });

    test('exports FocusTimerWidget', () {
      expect(FocusTimerWidget, isA<Type>());
    });

    test('exports SessionSummaryCard', () {
      expect(SessionSummaryCard, isA<Type>());
    });

    test('exports studyTimerServiceProvider', () {
      expect(studyTimerServiceProvider, isNotNull);
    });
  });
}
