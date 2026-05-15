import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/llm_models.dart';
import 'package:studyking/features/settings/data/models/settings_model.dart';

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

    test('fromJson with valid values', () {
      final key = SettingsAPIKey.fromJson({
        'provider': 'openai',
        'key': 'sk-test-key',
        'password': 'test-password',
      });

      expect(key.provider, 'openai');
      expect(key.key, 'sk-test-key');
      expect(key.password, 'test-password');
    });

    test('toJson returns correct structure', () {
      const key = SettingsAPIKey(
        provider: 'openrouter',
        key: 'test-key',
        password: 'secret',
      );

      final json = key.toJson();
      expect(json['provider'], 'openrouter');
      expect(json['key'], 'test-key');
      expect(json.containsKey('password'), isFalse);
    });

    test('equality based on provider, key, and password', () {
      const key1 = SettingsAPIKey(
        provider: 'openrouter',
        key: 'key1',
        password: 'pw1',
      );

      const key2 = SettingsAPIKey(
        provider: 'openrouter',
        key: 'key1',
        password: 'pw2',
      );

      const key3 = SettingsAPIKey(
        provider: 'openai',
        key: 'key1',
        password: 'pw1',
      );

      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
    });

    test('hashCode depends on provider and key only', () {
      const key1 = SettingsAPIKey(
        provider: 'test',
        key: 'key',
        password: 'pw1',
      );

      const key2 = SettingsAPIKey(
        provider: 'test',
        key: 'key',
        password: 'pw2',
      );

      expect(key1.hashCode, equals(key2.hashCode));
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

    test('fromResponse handles null usage', () {
      final record = UsageRecord.fromResponse(
        id: 'u2',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        usage: null,
      );

      expect(record.inputTokens, 0);
      expect(record.outputTokens, 0);
      expect(record.totalTokens, 0);
    });

    test('fromResponse handles missing token fields in usage', () {
      final record = UsageRecord.fromResponse(
        id: 'u3',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        usage: {'other': 'data'},
      );

      expect(record.inputTokens, 0);
      expect(record.outputTokens, 0);
    });

    test('priceDisplay formats correctly', () {
      final record = UsageRecord(
        id: 'test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.01234,
      );

      expect(record.priceDisplay, '\$0.0123');
    });

    test('tokenDisplay shows input and output tokens', () {
      final record = UsageRecord(
        id: 'test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        inputTokens: 500,
        outputTokens: 250,
        totalCost: 0.01,
      );

      expect(record.tokenDisplay, '(500 in / 250 out)');
    });

    test('formattedText includes timestamp, price, and cost per token', () {
      final record = UsageRecord(
        id: 'test',
        timestamp: DateTime(2026, 5, 11, 10, 30, 0),
        provider: 'openrouter',
        modelId: 'm1',
        inputTokens: 1000,
        outputTokens: 500,
        totalCost: 0.015,
      );

      final formatted = record.formattedText;
      expect(formatted, contains('2026-05-11'));
      expect(formatted, contains('\$0.0150'));
      expect(formatted, contains('cost/tk'));
    });

    test('promptTokensDetails and completionTokensDetails are stored', () {
      final record = UsageRecord.fromResponse(
        id: 'test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        usage: {
          'prompt_tokens': 100,
          'completion_tokens': 50,
        },
        promptTokensDetails: {'cached_tokens': 20},
        completionTokensDetails: {'reasoning_tokens': 10},
      );

      expect(record.promptTokensDetails, isNotNull);
      expect(record.completionTokensDetails, isNotNull);
    });

    test('constructor with all fields', () {
      final record = UsageRecord(
        id: 'full-test',
        timestamp: DateTime(2026, 5, 11),
        provider: 'test-provider',
        modelId: 'test-model',
        inputTokens: 200,
        outputTokens: 100,
        totalCost: 0.025,
        promptTokensDetails: {'key': 'value'},
        completionTokensDetails: {'key2': 'value2'},
        cachedTokensCost: 0.005,
        promptTokens: 200,
        completionTokens: 100,
      );

      expect(record.id, 'full-test');
      expect(record.provider, 'test-provider');
      expect(record.modelId, 'test-model');
      expect(record.inputTokens, 200);
      expect(record.outputTokens, 100);
      expect(record.totalCost, 0.025);
      expect(record.cachedTokensCost, 0.005);
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

    test('modelPricing returns unmodifiable map', () {
      final model = LLMSettingsModel();
      const pricing = ModelPrice(
        modelId: 'test',
        inputPrice: 1.0,
        outputPrice: 2.0,
        cacheReadPrice: 0.1,
        contextWindow: 4096,
      );
      model.setModelPricing('test', pricing);

      final pricingMap = model.modelPricing;
      expect(() => pricingMap['new'] = pricing, throwsUnsupportedError);
    });

    test('usageHistory returns unmodifiable list', () {
      final model = LLMSettingsModel();
      final record = UsageRecord(
        id: 'test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.01,
      );
      model.addUsageRecord(record);

      final history = model.usageHistory;
      expect(() => history.clear(), throwsUnsupportedError);
    });

    test('addApiKey and removeApiKey notify listeners', () {
      final model = LLMSettingsModel();
      var notifyCount = 0;
      model.addListener(() => notifyCount++);

      model.addApiKey('openrouter', 'key1');
      expect(notifyCount, 1);

      model.addApiKey('openai', 'key2');
      expect(notifyCount, 2);

      model.removeApiKey();
      expect(notifyCount, 3);
    });

    test('addUsageRecord inserts at beginning', () {
      final model = LLMSettingsModel();

      final record1 = UsageRecord(
        id: 'first',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.01,
      );
      final record2 = UsageRecord(
        id: 'second',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 200,
        outputTokens: 100,
        totalCost: 0.02,
      );

      model.addUsageRecord(record1);
      model.addUsageRecord(record2);

      expect(model.usageHistory.length, 2);
      expect(model.usageHistory.first.id, 'second');
      expect(model.usageHistory.last.id, 'first');
    });

    test('setModelPricing updates lastCost', () {
      final model = LLMSettingsModel();
      const pricing = ModelPrice(
        modelId: 'test',
        inputPrice: 1.0,
        outputPrice: 2.0,
        cacheReadPrice: 0.1,
        contextWindow: 4096,
      );

      expect(model.lastCost, isNull);
      model.setModelPricing('test', pricing);
      expect(model.lastCost, isNotNull);
    });

    test('getTotalTokens with multiple records', () {
      final model = LLMSettingsModel();

      for (var i = 0; i < 5; i++) {
        model.addUsageRecord(UsageRecord(
          id: 'test-$i',
          timestamp: DateTime.now(),
          provider: 'openrouter',
          modelId: 'm',
          inputTokens: 100,
          outputTokens: 50,
          totalCost: 0.01,
        ));
      }

      expect(model.getTotalTokens(), 750);
    });

    test('getTotalCost with multiple records', () {
      final model = LLMSettingsModel();

      for (var i = 0; i < 3; i++) {
        model.addUsageRecord(UsageRecord(
          id: 'test-$i',
          timestamp: DateTime.now(),
          provider: 'openrouter',
          modelId: 'm',
          inputTokens: 100,
          outputTokens: 50,
          totalCost: 0.01,
        ));
      }

      expect(model.getTotalCost(), closeTo(0.03, 1e-10));
    });

    test('avgCostPer1000Tokens calculates correctly', () {
      final model = LLMSettingsModel();

      model.addUsageRecord(UsageRecord(
        id: 'test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 1000000,
        outputTokens: 500000,
        totalCost: 0.015,
      ));

      expect(model.avgCostPer1000Tokens, closeTo(0.00001, 1e-10));
    });

    test('projectedMonthlyCost with single record', () {
      final model = LLMSettingsModel();

      model.addUsageRecord(UsageRecord(
        id: 'test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.03,
      ));

      expect(model.projectedMonthlyCost, closeTo(0.9, 1e-10));
    });

    test('formatUsageSummary formats correctly', () {
      final model = LLMSettingsModel();

      model.addUsageRecord(UsageRecord(
        id: 'test',
        timestamp: DateTime(2026, 5, 11),
        provider: 'openrouter',
        modelId: 'm',
        inputTokens: 1000,
        outputTokens: 500,
        totalCost: 0.05,
      ));

      final summary = model.formatUsageSummary();
      expect(summary, contains('Usage'));
      expect(summary, contains('1500 tokens'));
      expect(summary, contains('avg'));
      expect(summary, contains('per 1k tokens'));
    });
  });
}
