import 'package:flutter/material.dart';
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

    test('QuickGuideScreen can be const-constructed', () {
      const screen = QuickGuideScreen();
      expect(screen.defaultModelId, '');
      expect(screen.showModeNavigation, true);
    });

    test('ModeNavigationWidget can be const-constructed', () {
      const widget = ModeNavigationWidget();
      expect(widget, isNotNull);
    });

    test('MessageListWidget stores messages', () {
      final widget = MessageListWidget(
        messages: [],
        scrollController: ScrollController(),
      );
      expect(widget.messages, isEmpty);
      expect(widget.reduceMotion, false);
    });

    test('SuggestedPromptsWidget stores prompts', () {
      final widget = SuggestedPromptsWidget(
        prompts: ['Explain', 'Quiz'],
        onSelectPrompt: (s) {},
      );
      expect(widget.prompts, ['Explain', 'Quiz']);
    });

    test('QuickGuideHelpDialog can be const-constructed', () {
      const dialog = QuickGuideHelpDialog();
      expect(dialog, isNotNull);
    });
  });
}
