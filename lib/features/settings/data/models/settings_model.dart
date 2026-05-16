import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/token_pricing_config.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/features/settings/data/models/llm_models.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

  factory SettingsAPIKey.fromJson(Map<String, dynamic> json) {
    return SettingsAPIKey(
      provider: json['provider'] ?? 'openrouter',
      key: json['key'] ?? '',
      password: json['password'],
    );
  }

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

  int get totalTokens => inputTokens + outputTokens;

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

  static TokenPricingConfig pricingConfig = TokenPricingConfig();

  static double calculateTotalCost(int inputTokens, int outputTokens, int cachedTokensCost) {
    return pricingConfig.calculateTotalCost(inputTokens, outputTokens, cachedTokensCost);
  }

  String priceDisplayWithLocale(String localeName) => formatCurrency(totalCost, localeName, minFractionDigits: 4, maxFractionDigits: 4);

  String get priceDisplay => formatCurrency(totalCost, 'en', minFractionDigits: 4, maxFractionDigits: 4);

  String get tokenDisplay => '($inputTokens in / $outputTokens out)';

  String formattedTextWithLocale(String localeName) => '${timestamp.toIso8601String().split(' ')[0]}: ${priceDisplayWithLocale(localeName)}, cost/tk: ${formatDecimal(totalCost / totalTokens, localeName, minFractionDigits: 10, maxFractionDigits: 10)}';

  String get formattedText => '${timestamp.toIso8601String().split(' ')[0]}: $priceDisplay, cost/tk: ${formatDecimal(totalCost / totalTokens, 'en', minFractionDigits: 10, maxFractionDigits: 10)}';

  String formattedTextWithL10n(AppLocalizations l10n) => l10n.usageRecordFormat(
    timestamp.toIso8601String().split(' ')[0],
    priceDisplayWithLocale(l10n.localeName),
    formatDecimal(totalCost / totalTokens, l10n.localeName, minFractionDigits: 10, maxFractionDigits: 10),
  );

  @override
  String toString() => 'UsageRecord(\$: $formattedText)';
}

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

  void addApiKey(String provider, String key, {String? password}) {
    _apiKey = SettingsAPIKey(
      provider: provider,
      key: key,
      password: password,
    );
    notifyListeners();
  }

  void removeApiKey() {
    _apiKey = null;
    notifyListeners();
  }

  void addUsageRecord(UsageRecord record) {
    _usageHistory.insert(0, record);
    notifyListeners();
  }

  void setModelPricing(String modelId, ModelPrice pricing) {
    _modelPricing[modelId] = pricing;
    _lastCost = pricing.toString();
    notifyListeners();
  }

  int getTotalTokens() {
    return _usageHistory.fold(0, (sum, record) => sum + record.totalTokens);
  }

  double getTotalCost() {
    return _usageHistory.fold(0.0, (sum, record) => sum + record.totalCost);
  }

  double get avgCostPer1000Tokens {
    final totalTokens = getTotalTokens();
    if (totalTokens == 0) return 0.0;
    return (getTotalCost() / totalTokens) * 1000;
  }

  double get projectedMonthlyCost {
    if (_usageHistory.isEmpty) return 0.0;
    return (getTotalCost() / _usageHistory.length * 30);
  }

  String formatUsageSummary([String localeName = 'en']) {
    final totalTokens = getTotalTokens();
    final totalCost = getTotalCost();

    return 'Usage: ${formatCurrency(totalCost, localeName, minFractionDigits: 2, maxFractionDigits: 2)} over $totalTokens tokens, avg: ${formatCurrency(avgCostPer1000Tokens, localeName, minFractionDigits: 2, maxFractionDigits: 2)} per 1k tokens';
  }

  String formatUsageSummaryWithL10n(AppLocalizations l10n) {
    final totalTokens = getTotalTokens();
    final totalCost = getTotalCost();
    final localeName = l10n.localeName;

    return l10n.usageSummary(
      formatCurrency(totalCost, localeName, minFractionDigits: 2, maxFractionDigits: 2),
      totalTokens.toString(),
      formatCurrency(avgCostPer1000Tokens, localeName, minFractionDigits: 2, maxFractionDigits: 2),
    );
  }
}
