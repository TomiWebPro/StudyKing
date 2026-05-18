import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/settings/data/models/settings_model.dart';

class LlmUsageRecord {
  final String id;
  final String feature;
  final String modelId;
  final int inputTokens;
  final int outputTokens;
  final double cost;
  final DateTime timestamp;
  final bool success;

  LlmUsageRecord({
    required this.id,
    required this.feature,
    required this.modelId,
    required this.inputTokens,
    required this.outputTokens,
    required this.cost,
    required this.timestamp,
    this.success = true,
  });

  int get totalTokens => inputTokens + outputTokens;

  Map<String, dynamic> toJson() => {
    'id': id,
    'feature': feature,
    'modelId': modelId,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'cost': cost,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
  };

  factory LlmUsageRecord.fromJson(Map<String, dynamic> json) => LlmUsageRecord(
    id: json['id'] as String,
    feature: json['feature'] as String,
    modelId: json['modelId'] as String,
    inputTokens: (json['inputTokens'] as num).toInt(),
    outputTokens: (json['outputTokens'] as num).toInt(),
    cost: (json['cost'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    success: json['success'] as bool? ?? true,
  );
}

class LlmUsageMeter {
  final List<LlmUsageRecord> _records = [];
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxNames.llmUsageRecords);
    _loadFromBox();
  }

  void _loadFromBox() {
    _records.clear();
    for (final entry in _box.values) {
      if (entry is Map) {
        _records.add(LlmUsageRecord.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
  }

  void _saveToBox() {
    _box.clear();
    for (final record in _records) {
      _box.put(record.id, record.toJson());
    }
  }

  LlmUsageRecord recordUsage({
    required String id,
    required String feature,
    required String modelId,
    required int inputTokens,
    required int outputTokens,
    bool success = true,
  }) {
    final pricing = UsageRecord.pricingConfig;
    final cost = pricing.calculateTotalCost(inputTokens, outputTokens, 0);
    final record = LlmUsageRecord(
      id: id,
      feature: feature,
      modelId: modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: cost,
      timestamp: DateTime.now(),
      success: success,
    );
    _records.add(record);
    if (_records.length > 1000) {
      _records.removeAt(0);
    }
    _saveToBox();
    return record;
  }

  List<LlmUsageRecord> getRecords({String? feature, int? limit}) {
    var result = _records.reversed.toList();
    if (feature != null) {
      result = result.where((r) => r.feature == feature).toList();
    }
    if (limit != null && limit < result.length) {
      result = result.take(limit).toList();
    }
    return result;
  }

  Map<String, int> getTotalTokensPerFeature() {
    final totals = <String, int>{};
    for (final record in _records) {
      totals[record.feature] = (totals[record.feature] ?? 0) + record.totalTokens;
    }
    return totals;
  }

  Map<String, double> getTotalCostPerFeature() {
    final totals = <String, double>{};
    for (final record in _records) {
      totals[record.feature] = (totals[record.feature] ?? 0.0) + record.cost;
    }
    return totals;
  }

  double getTotalCost() {
    return _records.fold(0.0, (sum, r) => sum + r.cost);
  }

  int getTotalTokens() {
    return _records.fold(0, (sum, r) => sum + r.totalTokens);
  }

  void clear() => _records.clear();
}


