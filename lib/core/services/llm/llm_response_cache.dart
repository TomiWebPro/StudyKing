import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';

class LlmResponseCache {
  static final Logger _logger = const Logger('LlmResponseCache');
  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(HiveBoxNames.llmResponseCache);
  }

  String buildKey(String modelId, String systemPrompt, String message) {
    final hash = sha256.convert(utf8.encode('$modelId|$systemPrompt|$message'));
    return hash.toString();
  }

  String? get(String modelId, String systemPrompt, String message) {
    if (_box == null || !_box!.isOpen) return null;
    final key = buildKey(modelId, systemPrompt, message);
    final entry = _box!.get(key);
    if (entry == null) return null;

    final expiresAt = entry['expiresAt'] as int?;
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
      _box!.delete(key);
      return null;
    }
    return entry['response'] as String?;
  }

  void set(
    String modelId,
    String systemPrompt,
    String message,
    String response, {
    Duration ttl = const Duration(minutes: 10),
  }) {
    if (_box == null || !_box!.isOpen) return;
    final key = buildKey(modelId, systemPrompt, message);
    final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
    _box!.put(key, {
      'response': response,
      'expiresAt': expiresAt,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'modelId': modelId,
    });
  }

  void invalidate(String modelId) {
    if (_box == null || !_box!.isOpen) return;
    final keysToDelete = <dynamic>[];
    for (final key in _box!.keys) {
      final entry = _box!.get(key);
      if (entry != null && entry['modelId'] == modelId) {
        keysToDelete.add(key);
      }
    }
    _box!.deleteAll(keysToDelete);
    _logger.w('Invalidated ${keysToDelete.length} cache entries for model $modelId');
  }

  void clear() {
    if (_box == null || !_box!.isOpen) return;
    _box!.deleteAll(_box!.keys.toList());
  }

  int get size => _box?.length ?? 0;

  Duration ttlForFeature(String feature) {
    return switch (feature) {
      'classification' => CacheConfig.classificationCacheTtl,
      'lesson_plan' || 'lessonPlan' => CacheConfig.lessonPlanCacheTtl,
      'tutor' || 'chat' => CacheConfig.tutorCacheTtl,
      _ => CacheConfig.defaultCacheTtl,
    };
  }
}
