import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/quickguide/presentation/quick_guide_screen.dart';

void main() {
  group('QuickGuideScreen - constructor defaults', () {
    test('default showModeNavigation is true', () {
      const screen = QuickGuideScreen();
      expect(screen.showModeNavigation, isTrue);
    });

    test('default defaultModelId is empty string', () {
      const screen = QuickGuideScreen();
      expect(screen.defaultModelId, '');
    });

    test('default systemPrompt is null', () {
      const screen = QuickGuideScreen();
      expect(screen.systemPrompt, isNull);
    });

    test('default llmService is null', () {
      const screen = QuickGuideScreen();
      expect(screen.llmService, isNull);
    });

    test('can be created with all parameters', () {
      const screen = QuickGuideScreen(
        llmService: null,
        defaultModelId: 'custom-model',
        systemPrompt: 'Custom prompt',
        showModeNavigation: false,
      );
      expect(screen.defaultModelId, 'custom-model');
      expect(screen.systemPrompt, 'Custom prompt');
      expect(screen.showModeNavigation, isFalse);
      expect(screen.llmService, isNull);
    });
  });
}
