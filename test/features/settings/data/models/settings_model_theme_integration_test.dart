import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_model.dart';

void main() {
  group('LLMSettingsModel widget integration', () {
    testWidgets('notifies listeners and updates widget text', (tester) async {
      final model = LLMSettingsModel();

      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBuilder(
            animation: model,
            builder: (context, _) => Text(model.hasApiKey ? 'configured' : 'missing'),
          ),
        ),
      );

      expect(find.text('missing'), findsOneWidget);
      model.addApiKey('openrouter', 'live-key');
      await tester.pump();

      expect(find.text('configured'), findsOneWidget);
    });
  });
}
