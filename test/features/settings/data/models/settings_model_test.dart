import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/llm_models.dart';
import 'package:studyking/features/settings/data/models/settings_model.dart';

void main() {
  group('SettingsAPIKey', () {
    test('constructor sets all fields', () {
      const key = SettingsAPIKey(
        provider: 'openai',
        key: 'sk-test',
        password: 'pw123',
      );
      expect(key.provider, 'openai');
      expect(key.key, 'sk-test');
      expect(key.password, 'pw123');
    });

    test('constructor allows null password', () {
      const key = SettingsAPIKey(provider: 'openrouter', key: 'key');
      expect(key.provider, 'openrouter');
      expect(key.key, 'key');
      expect(key.password, isNull);
    });

    test('fromJson applies defaults for null values', () {
      final key = SettingsAPIKey.fromJson({
        'provider': null,
        'key': null,
        'password': 'secret',
      });
      expect(key.provider, 'openrouter');
      expect(key.key, '');
      expect(key.password, 'secret');
    });

    test('fromJson parses all fields', () {
      final key = SettingsAPIKey.fromJson({
        'provider': 'openai',
        'key': 'sk-test-key',
        'password': 'test-password',
      });
      expect(key.provider, 'openai');
      expect(key.key, 'sk-test-key');
      expect(key.password, 'test-password');
    });

    test('toJson returns correct structure without password', () {
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

    test('equality compares provider, key, and password', () {
      const key1 = SettingsAPIKey(
        provider: 'openrouter', key: 'key1', password: 'pw1',
      );
      const key2 = SettingsAPIKey(
        provider: 'openrouter', key: 'key1', password: 'pw2',
      );
      const key3 = SettingsAPIKey(
        provider: 'openai', key: 'key1', password: 'pw1',
      );
      const key4 = SettingsAPIKey(
        provider: 'openrouter', key: 'key1', password: 'pw1',
      );
      expect(key1, equals(key4));
      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
    });

    test('hashCode depends on provider and key only', () {
      const key1 = SettingsAPIKey(
        provider: 'test', key: 'key', password: 'pw1',
      );
      const key2 = SettingsAPIKey(
        provider: 'test', key: 'key', password: 'pw2',
      );
      const key3 = SettingsAPIKey(
        provider: 'other', key: 'key', password: 'pw1',
      );
      expect(key1.hashCode, equals(key2.hashCode));
      expect(key1.hashCode, isNot(equals(key3.hashCode)));
    });

    test('identical instances are equal', () {
      const key = SettingsAPIKey(provider: 'p', key: 'k');
      expect(key == key, isTrue);
    });

    test('different runtime types are not equal', () {
      const key = SettingsAPIKey(provider: 'p', key: 'k');
      expect(key == Object(), isFalse);
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      const original = SettingsAPIKey(
        provider: 'openai',
        key: 'sk-test-key',
        password: 'secret-password',
      );
      final json = original.toJson();
      final restored = SettingsAPIKey.fromJson(json);
      expect(restored.provider, original.provider);
      expect(restored.key, original.key);
      expect(restored.password, original.password);
    });

    test('toJson/fromJson round-trip with null password', () {
      const original = SettingsAPIKey(provider: 'openrouter', key: 'test-key');
      final json = original.toJson();
      final restored = SettingsAPIKey.fromJson(json);
      expect(restored.provider, 'openrouter');
      expect(restored.key, 'test-key');
      expect(restored.password, isNull);
    });
  });

  group('UsageRecord', () {
    test('constructor sets all fields', () {
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
      expect(record.timestamp, DateTime(2026, 5, 11));
      expect(record.provider, 'test-provider');
      expect(record.modelId, 'test-model');
      expect(record.inputTokens, 200);
      expect(record.outputTokens, 100);
      expect(record.totalCost, 0.025);
      expect(record.cachedTokensCost, 0.005);
      expect(record.promptTokens, 200);
      expect(record.completionTokens, 100);
      expect(record.promptTokensDetails, {'key': 'value'});
      expect(record.completionTokensDetails, {'key2': 'value2'});
    });

    test('constructor uses default zero for promptTokens and completionTokens', () {
      final record = UsageRecord(
        id: 'test', timestamp: DateTime.now(),
        provider: 'p', modelId: 'm',
        inputTokens: 100, outputTokens: 50, totalCost: 0.01,
      );
      expect(record.promptTokens, 0);
      expect(record.completionTokens, 0);
    });

    test('totalTokens sums input and output', () {
      final record = UsageRecord(
        id: 'test', timestamp: DateTime.now(),
        provider: 'p', modelId: 'm',
        inputTokens: 1000, outputTokens: 500, totalCost: 0.01,
      );
      expect(record.totalTokens, 1500);
    });

    test('totalTokens is zero when both input and output are zero', () {
      final record = UsageRecord(
        id: 'test', timestamp: DateTime.now(),
        provider: 'p', modelId: 'm',
        inputTokens: 0, outputTokens: 0, totalCost: 0,
      );
      expect(record.totalTokens, 0);
    });

    group('fromResponse', () {
      test('parses full usage map with cached tokens', () {
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
      });

      test('handles null usage', () {
        final record = UsageRecord.fromResponse(
          id: 'u2', timestamp: DateTime.now(),
          provider: 'openrouter', modelId: 'm1',
          usage: null,
        );
        expect(record.inputTokens, 0);
        expect(record.outputTokens, 0);
        expect(record.totalTokens, 0);
        expect(record.totalCost, 0);
      });

      test('handles usage with no token fields', () {
        final record = UsageRecord.fromResponse(
          id: 'u3', timestamp: DateTime.now(),
          provider: 'openrouter', modelId: 'm1',
          usage: {'other': 'data'},
        );
        expect(record.inputTokens, 0);
        expect(record.outputTokens, 0);
      });

      test('stores prompt and completion token details', () {
        final record = UsageRecord.fromResponse(
          id: 'test', timestamp: DateTime.now(),
          provider: 'openrouter', modelId: 'm1',
          usage: {'prompt_tokens': 100, 'completion_tokens': 50},
          promptTokensDetails: {'cached_tokens': 20},
          completionTokensDetails: {'reasoning_tokens': 10},
        );
        expect(record.promptTokensDetails, {'cached_tokens': 20});
        expect(record.completionTokensDetails, {'reasoning_tokens': 10});
      });

      test('handles missing promptTokensDetails and completionTokensDetails', () {
        final record = UsageRecord.fromResponse(
          id: 'test', timestamp: DateTime.now(),
          provider: 'openrouter', modelId: 'm1',
          usage: {'prompt_tokens': 100, 'completion_tokens': 50},
        );
        expect(record.promptTokensDetails, isNull);
        expect(record.completionTokensDetails, isNull);
      });
    });

    group('calculateTotalCost', () {
      test('returns zero for zero tokens', () {
        expect(UsageRecord.calculateTotalCost(0, 0, 0), 0);
      });

      test('calculates positive cost for non-zero tokens', () {
        final cost = UsageRecord.calculateTotalCost(1000, 500, 100);
        expect(cost, greaterThan(0));
      });
    });

    group('display helpers', () {
      test('priceDisplay formats to 4 decimal places', () {
        final record = UsageRecord(
          id: 'test', timestamp: DateTime.now(),
          provider: 'p', modelId: 'm',
          inputTokens: 100, outputTokens: 50, totalCost: 0.01234,
        );
        expect(record.priceDisplay, '\$0.0123');
      });

      test('priceDisplay handles zero cost', () {
        final record = UsageRecord(
          id: 'test', timestamp: DateTime.now(),
          provider: 'p', modelId: 'm',
          inputTokens: 0, outputTokens: 0, totalCost: 0,
        );
        expect(record.priceDisplay, '\$0.0000');
      });

      test('tokenDisplay formats input and output', () {
        final record = UsageRecord(
          id: 'test', timestamp: DateTime.now(),
          provider: 'p', modelId: 'm',
          inputTokens: 500, outputTokens: 250, totalCost: 0.01,
        );
        expect(record.tokenDisplay, '(500 in / 250 out)');
      });

      test('formattedText includes date, price, and cost per token', () {
        final record = UsageRecord(
          id: 'test', timestamp: DateTime(2026, 5, 11, 10, 30, 0),
          provider: 'openrouter', modelId: 'm1',
          inputTokens: 1000, outputTokens: 500, totalCost: 0.015,
        );
        final formatted = record.formattedText;
        expect(formatted, contains('2026-05-11'));
        expect(formatted, contains('\$0.0150'));
        expect(formatted, contains('cost/tk'));
      });
    });

    test('toString includes formattedText', () {
      final record = UsageRecord(
        id: 'test', timestamp: DateTime(2026, 5, 11),
        provider: 'p', modelId: 'm',
        inputTokens: 100, outputTokens: 50, totalCost: 0.005,
      );
      expect(record.toString(), contains('UsageRecord'));
      expect(record.toString(), contains(record.formattedText));
    });
  });

  group('LLMSettingsModel', () {
    test('initial state has no api key, empty history, and no pricing', () {
      final model = LLMSettingsModel();
      expect(model.apiKey, isNull);
      expect(model.hasApiKey, isFalse);
      expect(model.usageHistory, isEmpty);
      expect(model.modelPricing, isEmpty);
      expect(model.lastCost, isNull);
      expect(model.getTotalTokens(), 0);
      expect(model.getTotalCost(), 0.0);
      expect(model.avgCostPer1000Tokens, 0.0);
      expect(model.projectedMonthlyCost, 0.0);
    });

    group('api key management', () {
      test('addApiKey sets the key with password', () {
        final model = LLMSettingsModel();
        model.addApiKey('openrouter', 'abc123', password: 'pw');
        expect(model.hasApiKey, isTrue);
        expect(model.apiKey!.provider, 'openrouter');
        expect(model.apiKey!.key, 'abc123');
        expect(model.apiKey!.password, 'pw');
      });

      test('addApiKey sets the key without password', () {
        final model = LLMSettingsModel();
        model.addApiKey('openai', 'sk-test');
        expect(model.hasApiKey, isTrue);
        expect(model.apiKey!.provider, 'openai');
        expect(model.apiKey!.key, 'sk-test');
        expect(model.apiKey!.password, isNull);
      });

      test('hasApiKey returns false when key is empty string', () {
        final model = LLMSettingsModel();
        model.addApiKey('openrouter', '');
        expect(model.hasApiKey, isFalse);
      });

      test('removeApiKey clears the key', () {
        final model = LLMSettingsModel();
        model.addApiKey('openrouter', 'key1');
        expect(model.hasApiKey, isTrue);
        model.removeApiKey();
        expect(model.apiKey, isNull);
        expect(model.hasApiKey, isFalse);
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
    });

    group('usage history', () {
      UsageRecord record(String id, {int inTk = 100, int outTk = 50, double cost = 0.01}) {
        return UsageRecord(
          id: id, timestamp: DateTime.now(),
          provider: 'openrouter', modelId: 'm',
          inputTokens: inTk, outputTokens: outTk, totalCost: cost,
        );
      }

      test('addUsageRecord inserts at beginning', () {
        final model = LLMSettingsModel();
        final record1 = record('first');
        final record2 = record('second');

        model.addUsageRecord(record1);
        model.addUsageRecord(record2);

        expect(model.usageHistory.length, 2);
        expect(model.usageHistory.first.id, 'second');
        expect(model.usageHistory.last.id, 'first');
      });

      test('addUsageRecord notifies listeners', () {
        final model = LLMSettingsModel();
        var notifyCount = 0;
        model.addListener(() => notifyCount++);

        model.addUsageRecord(record('r1'));
        expect(notifyCount, 1);

        model.addUsageRecord(record('r2'));
        expect(notifyCount, 2);
      });

      test('usageHistory returns unmodifiable list', () {
        final model = LLMSettingsModel();
        model.addUsageRecord(record('test'));
        final history = model.usageHistory;
        expect(() => history.clear(), throwsUnsupportedError);
      });

      test('getTotalTokens sums all records', () {
        final model = LLMSettingsModel();
        for (var i = 0; i < 5; i++) {
          model.addUsageRecord(record('test-$i', inTk: 100, outTk: 50));
        }
        expect(model.getTotalTokens(), 750);
      });

      test('getTotalTokens returns 0 when history is empty', () {
        final model = LLMSettingsModel();
        expect(model.getTotalTokens(), 0);
      });

      test('getTotalCost sums all records', () {
        final model = LLMSettingsModel();
        for (var i = 0; i < 3; i++) {
          model.addUsageRecord(record('test-$i', cost: 0.01));
        }
        expect(model.getTotalCost(), closeTo(0.03, 1e-10));
      });

      test('getTotalCost returns 0 when history is empty', () {
        final model = LLMSettingsModel();
        expect(model.getTotalCost(), 0.0);
      });
    });

    group('pricing', () {
      const testPricing = ModelPrice(
        modelId: 'test-model',
        inputPrice: 1.0,
        outputPrice: 2.0,
        cacheReadPrice: 0.1,
        contextWindow: 4096,
      );

      test('setModelPricing stores pricing and updates lastCost', () {
        final model = LLMSettingsModel();
        expect(model.lastCost, isNull);
        model.setModelPricing('test-model', testPricing);
        expect(model.modelPricing['test-model'], testPricing);
        expect(model.lastCost, isNotNull);
        expect(model.lastCost, contains('Instance of'));
      });

      test('setModelPricing notifies listeners', () {
        final model = LLMSettingsModel();
        var notifyCount = 0;
        model.addListener(() => notifyCount++);

        model.setModelPricing('test-model', testPricing);
        expect(notifyCount, 1);
      });

      test('modelPricing returns unmodifiable map', () {
        final model = LLMSettingsModel();
        model.setModelPricing('test-model', testPricing);
        final pricingMap = model.modelPricing;
        expect(() => pricingMap['new'] = testPricing, throwsUnsupportedError);
      });

      test('setModelPricing overwrites existing pricing', () {
        final model = LLMSettingsModel();
        const updatedPricing = ModelPrice(
          modelId: 'test-model',
          inputPrice: 2.0,
          outputPrice: 3.0,
          cacheReadPrice: 0.2,
          contextWindow: 8192,
        );
        model.setModelPricing('test-model', testPricing);
        model.setModelPricing('test-model', updatedPricing);
        expect(model.modelPricing.length, 1);
        expect(model.modelPricing['test-model'], updatedPricing);
      });
    });

    group('aggregation calculations', () {
      UsageRecord record(String id, {int inTk = 100, int outTk = 50, double cost = 0.01}) {
        return UsageRecord(
          id: id, timestamp: DateTime.now(),
          provider: 'openrouter', modelId: 'm',
          inputTokens: inTk, outputTokens: outTk, totalCost: cost,
        );
      }

      test('avgCostPer1000Tokens calculates correctly', () {
        final model = LLMSettingsModel();
        model.addUsageRecord(record('test', inTk: 1000000, outTk: 500000, cost: 0.015));
        expect(model.avgCostPer1000Tokens, closeTo(0.00001, 1e-10));
      });

      test('avgCostPer1000Tokens returns 0 when total tokens is 0', () {
        final model = LLMSettingsModel();
        expect(model.avgCostPer1000Tokens, 0.0);
      });

      test('projectedMonthlyCost with single record', () {
        final model = LLMSettingsModel();
        model.addUsageRecord(record('test', cost: 0.03));
        expect(model.projectedMonthlyCost, closeTo(0.9, 1e-10));
      });

      test('projectedMonthlyCost with multiple records', () {
        final model = LLMSettingsModel();
        model.addUsageRecord(record('r1', cost: 0.01));
        model.addUsageRecord(record('r2', cost: 0.03));
        expect(model.projectedMonthlyCost, closeTo(0.6, 1e-10));
      });

      test('projectedMonthlyCost returns 0 when history is empty', () {
        final model = LLMSettingsModel();
        expect(model.projectedMonthlyCost, 0.0);
      });

      test('formatUsageSummary returns correct string', () {
        final model = LLMSettingsModel();
        model.addUsageRecord(record('test', inTk: 1000, outTk: 500, cost: 0.05));

        final summary = model.formatUsageSummary();
        expect(summary, contains('Usage'));
        expect(summary, contains('1500 tokens'));
        expect(summary, contains('avg'));
        expect(summary, contains('per 1k tokens'));
      });
    });

    group('listener notification', () {
      test('multiple operations notify each time', () {
        final model = LLMSettingsModel();
        final notifications = <String>[];
        model.addListener(() => notifications.add('notify'));

        model.addApiKey('openrouter', 'key');
        model.addUsageRecord(UsageRecord(
          id: 'r', timestamp: DateTime.now(),
          provider: 'p', modelId: 'm',
          inputTokens: 100, outputTokens: 50, totalCost: 0.01,
        ));
        model.setModelPricing('m', const ModelPrice(
          modelId: 'm', inputPrice: 0.5, outputPrice: 1.0,
          cacheReadPrice: 0.1, contextWindow: 8192,
        ));
        model.removeApiKey();

        expect(notifications.length, 4);
      });
    });
  });

}
