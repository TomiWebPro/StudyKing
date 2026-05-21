import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/token_pricing_config.dart';

void main() {
  group('TokenPricingConfig', () {
    late TokenPricingConfig config;

    setUp(() {
      config = const TokenPricingConfig();
    });

    test('has default values', () {
      expect(config.cachedInputCostPerToken, equals(0.000005));
      expect(config.inputCostPerToken, equals(0.000006));
      expect(config.outputCostPerToken, equals(0.0000024));
      expect(config.divisor, equals(1000000));
    });

    test('calculateTotalCost with zero tokens returns zero', () {
      final cost = config.calculateTotalCost(0, 0, 0);
      expect(cost, equals(0.0));
    });

    test('calculateTotalCost with only input tokens', () {
      final cost = config.calculateTotalCost(1000, 0, 0);
      final expected = (1000 * 0.000006) / 1000000;
      expect(cost, equals(expected));
    });

    test('calculateTotalCost with only output tokens', () {
      final cost = config.calculateTotalCost(0, 500, 0);
      final expected = (500 * 0.0000024) / 1000000;
      expect(cost, equals(expected));
    });

    test('calculateTotalCost with only cached tokens', () {
      final cost = config.calculateTotalCost(0, 0, 2000);
      final expected = (2000 * 0.000005) / 1000000;
      expect(cost, equals(expected));
    });

    test('calculateTotalCost with all token types', () {
      final cost = config.calculateTotalCost(1000, 500, 200);
      final expected = ((200 * 0.000005) + (1000 * 0.000006) + (500 * 0.0000024)) / 1000000;
      expect(cost, equals(expected));
    });

    test('calculateTotalCost with large values', () {
      final cost = config.calculateTotalCost(1000000, 500000, 200000);
      expect(cost, greaterThan(0));
    });

    test('custom config overrides defaults', () {
      const custom = TokenPricingConfig(
        inputCostPerToken: 0.00001,
        outputCostPerToken: 0.00003,
        divisor: 1000,
      );
      final cost = custom.calculateTotalCost(100, 100, 0);
      final expected = ((100 * 0.00001) + (100 * 0.00003)) / 1000;
      expect(cost, equals(expected));
    });
  });
}
