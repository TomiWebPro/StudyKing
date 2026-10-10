import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/token_pricing_config.dart';

void main() {
  group('TokenPricingConfig', () {
    late TokenPricingConfig config;

    setUp(() {
      config = const TokenPricingConfig();
    });

    test('has default per-token values', () {
      expect(config.cachedInputCostPerToken, equals(0.000005));
      expect(config.inputCostPerToken, equals(0.000006));
      expect(config.outputCostPerToken, equals(0.0000024));
    });

    test('calculateTotalCost with zero tokens returns zero', () {
      final cost = config.calculateTotalCost(0, 0, 0);
      expect(cost, equals(0.0));
    });

    test('calculateTotalCost with only input tokens', () {
      final cost = config.calculateTotalCost(1000, 0, 0);
      expect(cost, closeTo(1000 * 0.000006, 1e-12));
    });

    test('calculateTotalCost with only output tokens', () {
      final cost = config.calculateTotalCost(0, 500, 0);
      expect(cost, closeTo(500 * 0.0000024, 1e-12));
    });

    test('calculateTotalCost with only cached tokens', () {
      final cost = config.calculateTotalCost(0, 0, 2000);
      expect(cost, closeTo(2000 * 0.000005, 1e-12));
    });

    test('calculateTotalCost with all token types', () {
      final cost = config.calculateTotalCost(1000, 500, 200);
      final expected =
          (1000 * 0.000006) + (500 * 0.0000024) + (200 * 0.000005);
      expect(cost, closeTo(expected, 1e-12));
    });

    test('calculateTotalCost yields dollar-scale cost for millions of tokens',
        () {
      // 1M input ($6.00) + 0.5M output ($1.20) + 0.2M cached ($1.00).
      final cost = config.calculateTotalCost(1000000, 500000, 200000);
      expect(cost, closeTo(8.20, 1e-9));
    });

    test('calculateTotalCost yields cents-scale cost for realistic token counts',
        () {
      // 2,000 input + 500 output tokens ≈ $0.0132, never ~$0.0000.
      final cost = config.calculateTotalCost(2000, 500, 0);
      expect(cost, closeTo(0.0132, 1e-12));
    });

    test('custom config overrides defaults', () {
      const custom = TokenPricingConfig(
        inputCostPerToken: 0.00001,
        outputCostPerToken: 0.00003,
      );
      final cost = custom.calculateTotalCost(100, 100, 0);
      final expected = (100 * 0.00001) + (100 * 0.00003);
      expect(cost, closeTo(expected, 1e-12));
    });
  });
}
