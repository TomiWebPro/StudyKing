import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/data/models/llm_models.dart';

/// API key settings for storing API credentials
@immutable
class SettingsAPIKey {
  final String provider;
  final String key;
  final String? password;

  const SettingsAPIKey({
    required this.provider,
    required this.key,
    this.password,
  });

  /// Create from JSON
  factory SettingsAPIKey.fromJson(Map<String, dynamic> json) {
    return SettingsAPIKey(
      provider: json['provider'] ?? 'openrouter',
      key: json['key'] ?? '',
      password: json['password'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'key': key,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAPIKey &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          key == other.key &&
          password == other.password;

  @override
  int get hashCode => Object.hash(provider, key);
}

/// Usage record with full data
class UsageRecord {
  final String id;
  final DateTime timestamp;
  final String provider;
  final String modelId;
  final int inputTokens;
  final int outputTokens;
  final Map<String, dynamic>? promptTokensDetails;
  final Map<String, dynamic>? completionTokensDetails;
  final double totalCost;
  final double? cachedTokensCost;
  final int promptTokens;
  final int completionTokens;

  UsageRecord({
    required this.id,
    required this.timestamp,
    required this.provider,
    required this.modelId,
    required this.inputTokens,
    required this.outputTokens,
    this.promptTokensDetails,
    this.completionTokensDetails,
    required this.totalCost,
    this.cachedTokensCost,
    this.completionTokens = 0,
    this.promptTokens = 0,
  });

  /// Get total tokens
  int get totalTokens => inputTokens + outputTokens;

  /// Create from API response
  factory UsageRecord.fromResponse({
    required String id,
    required DateTime timestamp,
    required String provider,
    required String modelId,
    required Map<String, dynamic>? usage,
    Map<String, dynamic>? promptTokensDetails,
    Map<String, dynamic>? completionTokensDetails,
  }) {
    final inputTokens = usage?['prompt_tokens']?.toInt() ?? 0;
    final outputTokens = usage?['completion_tokens']?.toInt() ?? 0;
    final cachedTokens = usage?['cached_tokens']?.toInt() ?? 0;

    final totalCost = UsageRecord.calculateTotalCost(inputTokens, outputTokens, cachedTokens);

    return UsageRecord(
      id: id,
      timestamp: timestamp,
      provider: provider,
      modelId: modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCost: totalCost,
      promptTokensDetails: promptTokensDetails,
      completionTokensDetails: completionTokensDetails,
      promptTokens: inputTokens,
      completionTokens: outputTokens,
    );
  }

  /// Calculate total cost from tokens
  static double calculateTotalCost(int inputTokens, int outputTokens, int cachedTokensCost) {
    final cachedInputCost = (cachedTokensCost * 0.000005) / 1000000;
    final inputCost = (inputTokens * 0.000006) / 1000000;
    final outputCost = (outputTokens * 0.0000024) / 1000000;
    final total = cachedInputCost + inputCost + outputCost;
    return total;
  }

  /// Create price display string
  String get priceDisplay => '\$${totalCost.toStringAsFixed(4)}';

  /// Create token display string
  String get tokenDisplay => '($inputTokens in / $outputTokens out)';

  /// Format for list view
  String get formattedText => '${timestamp.toIso8601String().split(' ')[0]}: $priceDisplay, cost/tk: ${(totalCost / totalTokens).toStringAsFixed(10)}';

  @override
  String toString() => 'UsageRecord(\$: $formattedText)';
}

/// Complete settings model class
class LLMSettingsModel extends ChangeNotifier {
  SettingsAPIKey? _apiKey;
  final Map<String, ModelPrice> _modelPricing = {};
  final List<UsageRecord> _usageHistory = [];
  String? _lastCost;

  SettingsAPIKey? get apiKey => _apiKey;
  Map<String, ModelPrice> get modelPricing => Map.unmodifiable(_modelPricing);
  List<UsageRecord> get usageHistory => List.unmodifiable(_usageHistory);
  String? get lastCost => _lastCost;
  bool get hasApiKey => _apiKey?.key.isNotEmpty ?? false;

  /// Add API key
  void addApiKey(String provider, String key, {String? password}) {
    _apiKey = SettingsAPIKey(
      provider: provider,
      key: key,
      password: password,
    );
    notifyListeners();
  }

  /// Remove API key
  void removeApiKey() {
    _apiKey = null;
    notifyListeners();
  }

  /// Add usage record
  void addUsageRecord(UsageRecord record) {
    _usageHistory.insert(0, record);
    notifyListeners();
  }

  /// Set model pricing
  void setModelPricing(String modelId, ModelPrice pricing) {
    _modelPricing[modelId] = pricing;
    _lastCost = pricing.toString();
    notifyListeners();
  }

  /// Get total usage tokens across all records
  int getTotalTokens() {
    return _usageHistory.fold(0, (sum, record) => sum + record.totalTokens);
  }

  /// Get total cost across all records
  double getTotalCost() {
    return _usageHistory.fold(0.0, (sum, record) => sum + record.totalCost);
  }

  /// Get average cost per thousand tokens
  double get avgCostPer1000Tokens {
    final totalTokens = getTotalTokens();
    if (totalTokens == 0) return 0.0;
    return (getTotalCost() / totalTokens) * 1000;
  }

  /// Project monthly cost
  double get projectedMonthlyCost {
    if (_usageHistory.isEmpty) return 0.0;
    return (getTotalCost() / _usageHistory.length * 30);
  }

  /// Format usage summary
  String formatUsageSummary() {
    final totalTokens = getTotalTokens();
    final totalCost = getTotalCost();

    return 'Usage: \$${totalCost.toStringAsFixed(2)} over $totalTokens tokens, avg: \$${avgCostPer1000Tokens.toStringAsFixed(2)} per 1k tokens';
  }
}
