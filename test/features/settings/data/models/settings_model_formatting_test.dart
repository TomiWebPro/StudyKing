import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:studyking/features/settings/data/models/settings_model.dart';

void main() {
  late UsageRecord record;
  late UsageRecord zeroRecord;

  setUpAll(() async {
    Intl.defaultLocale = 'en';
  });

  setUp(() {
    record = UsageRecord(
      id: 'fmt-test',
      timestamp: DateTime(2026, 5, 11, 10, 30),
      provider: 'openrouter',
      modelId: 'model-x',
      inputTokens: 1000,
      outputTokens: 500,
      totalCost: 0.012345,
      cachedTokensCost: 0.001,
    );
    zeroRecord = UsageRecord(
      id: 'zero-test',
      timestamp: DateTime(2026, 5, 11),
      provider: 'openrouter',
      modelId: 'model-x',
      inputTokens: 0,
      outputTokens: 0,
      totalCost: 0,
    );
  });

  group('UsageRecord.priceDisplayWithLocale', () {
    test('formats with en locale', () {
      expect(record.priceDisplayWithLocale('en'), '\$0.0123');
    });

    test('handles zero cost', () {
      expect(zeroRecord.priceDisplayWithLocale('en'), '\$0.0000');
    });
  });

  group('UsageRecord.priceDisplayWithLocale', () {
    test('formats with en locale', () {
      expect(record.priceDisplayWithLocale('en'), '\$0.0123');
    });

    test('handles zero cost', () {
      expect(zeroRecord.priceDisplayWithLocale('en'), '\$0.0000');
    });
  });

  group('UsageRecord.formattedTextWithLocale', () {
    test('includes date, price, and cost per token', () {
      final formatted = record.formattedTextWithLocale('en');
      expect(formatted, contains('2026-05-11'));
      expect(formatted, contains('\$0.0123'));
      expect(formatted, contains('cost/tk'));
    });

    test('handles zero tokens gracefully', () {
      final formatted = zeroRecord.formattedTextWithLocale('en');
      expect(formatted, contains('2026-05-11'));
      expect(formatted, contains('\$0.0000'));
    });
  });

  group('UsageRecord.formattedTextWithLocale', () {
    test('includes date, price, and cost per token', () {
      final formatted = record.formattedTextWithLocale('en');
      expect(formatted, contains('2026-05-11'));
      expect(formatted, contains('\$0.0123'));
      expect(formatted, contains('cost/tk'));
    });
  });

  group('LLMSettingsModel.formatUsageSummary', () {
    test('uses default en locale', () {
      final model = LLMSettingsModel();
      model.addUsageRecord(UsageRecord(
        id: 'summary-test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        inputTokens: 1000,
        outputTokens: 500,
        totalCost: 0.05,
      ));

      final summary = model.formatUsageSummary('en');
      expect(summary, contains('Usage'));
      expect(summary, contains('1500 tokens'));
      expect(summary, contains('avg'));
      expect(summary, contains('per 1k tokens'));
      expect(summary, contains('\$'));
    });

    test('accepts explicit en locale', () {
      final model = LLMSettingsModel();
      model.addUsageRecord(UsageRecord(
        id: 'locale-test',
        timestamp: DateTime.now(),
        provider: 'openrouter',
        modelId: 'm1',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.01,
      ));

      final summary = model.formatUsageSummary('en');
      expect(summary, contains('Usage'));
      expect(summary, contains('150 tokens'));
    });

    test('handles empty history', () {
      final model = LLMSettingsModel();
      final summary = model.formatUsageSummary('en');
      expect(summary, contains('Usage'));
      expect(summary, contains('0 tokens'));
    });
  });

  group('UsageRecord.cachedTokensCost', () {
    test('defaults to null when not provided', () {
      final r = UsageRecord(
        id: 'null-cache',
        timestamp: DateTime.now(),
        provider: 'p',
        modelId: 'm',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.01,
      );
      expect(r.cachedTokensCost, isNull);
    });

    test('stores cachedTokensCost when provided', () {
      expect(record.cachedTokensCost, 0.001);
    });
  });

  group('UsageRecord.calculateTotalCost', () {
    test('uses pricingConfig for calculation', () {
      final cost = UsageRecord.calculateTotalCost(100, 50, 10);
      expect(cost, greaterThanOrEqualTo(0));
    });
  });

  group('UsageRecord.toString', () {
    test('includes UsageRecord marker', () {
      final str = record.toString();
      expect(str, startsWith('UsageRecord'));
    });
  });
}
