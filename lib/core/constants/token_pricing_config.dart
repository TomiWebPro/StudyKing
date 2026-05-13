class TokenPricingConfig {
  final double cachedInputCostPerToken;
  final double inputCostPerToken;
  final double outputCostPerToken;
  final double divisor;

  const TokenPricingConfig({
    this.cachedInputCostPerToken = 0.000005,
    this.inputCostPerToken = 0.000006,
    this.outputCostPerToken = 0.0000024,
    this.divisor = 1000000,
  });

  double calculateTotalCost(int inputTokens, int outputTokens, int cachedTokens) {
    final cachedInputCost = (cachedTokens * cachedInputCostPerToken) / divisor;
    final inputCost = (inputTokens * inputCostPerToken) / divisor;
    final outputCost = (outputTokens * outputCostPerToken) / divisor;
    return cachedInputCost + inputCost + outputCost;
  }
}
