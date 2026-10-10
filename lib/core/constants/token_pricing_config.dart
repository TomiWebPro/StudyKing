class TokenPricingConfig {
  final double cachedInputCostPerToken;
  final double inputCostPerToken;
  final double outputCostPerToken;

  const TokenPricingConfig({
    this.cachedInputCostPerToken = 0.000005,
    this.inputCostPerToken = 0.000006,
    this.outputCostPerToken = 0.0000024,
  });

  double calculateTotalCost(int inputTokens, int outputTokens, int cachedTokens) {
    final cachedInputCost = cachedTokens * cachedInputCostPerToken;
    final inputCost = inputTokens * inputCostPerToken;
    final outputCost = outputTokens * outputCostPerToken;
    return cachedInputCost + inputCost + outputCost;
  }
}
