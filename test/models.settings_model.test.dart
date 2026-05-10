import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/models/llm_models.dart';
import 'package:studyking/models/settings_model.dart';

void main() {
  group('SettingsAPIKey', () {
    test('fromJson defaults and toJson omit password', () {
      final key = SettingsAPIKey.fromJson({
        'provider': null,
        'key': null,
        'password': 'secret',
      });

      expect(key.provider, 'openrouter');
      expect(key.key, '');
      expect(key.password, 'secret');
      expect(key.toJson().containsKey('password'), isFalse);
    });
  });

  group('UsageRecord', () {
    test('fromResponse, totals, and display helpers are correct', () {
      final record = UsageRecord.fromResponse(
        id: 'u1',
        timestamp: DateTime(2026, 5, 11),
        provider: 'openrouter',
        modelId: 'm1',
        usage: {
          'prompt_tokens': 1200,
          'completion_tokens': 300,
          'cached_tokens': 100,
        },
      );

      expect(record.totalTokens, 1500);
      expect(record.promptTokens, 1200);
      expect(record.completionTokens, 300);
      expect(record.totalCost, greaterThan(0));
      expect(record.priceDisplay, startsWith('\$0.'));
      expect(record.tokenDisplay, '(1200 in / 300 out)');
      expect(record.toString(), contains('UsageRecord'));
    });

    test('calculateTotalCost supports zero values', () {
      expect(UsageRecord.calculateTotalCost(0, 0, 0), 0);
    });
  });

  group('LLMSettingsModel', () {
    test('manages api keys, pricing, usage, and aggregates', () {
      final model = LLMSettingsModel();

      expect(model.hasApiKey, isFalse);
      model.addApiKey('openrouter', 'abc123', password: 'pw');
      expect(model.hasApiKey, isTrue);
      expect(model.apiKey?.provider, 'openrouter');

      final old = UsageRecord(
        id: 'old',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.01,
      );
      final recent = UsageRecord(
        id: 'recent',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 200,
        outputTokens: 100,
        totalCost: 0.03,
      );
      model.addUsageRecord(old);
      model.addUsageRecord(recent);

      expect(model.usageHistory.first.id, 'recent');
      expect(model.getTotalTokens(), 450);
      expect(model.getTotalCost(), closeTo(0.04, 1e-10));
      expect(model.avgCostPer1000Tokens, closeTo((0.04 / 450) * 1000, 1e-10));
      expect(model.projectedMonthlyCost, closeTo((0.04 / 2) * 30, 1e-10));
      expect(model.formatUsageSummary(), contains('over 450 tokens'));

      const pricing = ModelPrice(
        modelId: 'm',
        inputPrice: 0.5,
        outputPrice: 1.0,
        cacheReadPrice: 0.1,
        contextWindow: 8192,
      );
      model.setModelPricing('m', pricing);
      expect(model.modelPricing['m'], pricing);
      expect(model.lastCost, contains('Instance of'));

      model.removeApiKey();
      expect(model.apiKey, isNull);
      expect(model.hasApiKey, isFalse);
    });

    test('returns zero values when usage history is empty', () {
      final model = LLMSettingsModel();
      expect(model.getTotalTokens(), 0);
      expect(model.getTotalCost(), 0.0);
      expect(model.avgCostPer1000Tokens, 0.0);
      expect(model.projectedMonthlyCost, 0.0);
    });

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
