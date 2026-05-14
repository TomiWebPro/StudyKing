import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/quickguide.dart';

void main() {
  group('QuickGuide barrel export', () {
    test('quickguide.dart exports QuickGuideScreen', () {
      expect(QuickGuideScreen, isA<Type>());
    });

    test('quickguide.dart exports ModeNavigationWidget', () {
      expect(ModeNavigationWidget, isA<Type>());
    });

    test('quickguide.dart exports MessageListWidget', () {
      expect(MessageListWidget, isA<Type>());
    });

    test('quickguide.dart exports SuggestedPromptsWidget', () {
      expect(SuggestedPromptsWidget, isA<Type>());
    });

    test('quickguide.dart exports showQuickGuideHelpDialog', () {
      expect(showQuickGuideHelpDialog, isA<Function>());
    });
  });
}
