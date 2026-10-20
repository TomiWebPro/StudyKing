import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/constants/app_runtime_config.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

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
    final normalized = feature.normalized;
    return switch (normalized) {
      // Classification results are stable per source document.
      'classification' || 'content_classification' =>
        CacheConfig.classificationCacheTtl,
      // Bulk PDF ingestion pipeline calls share the pdf_ingestion feature
      // so they are attributed to the background prep bucket in the meter.
      // Pipeline artifacts (per-chunk classify/summarize/generate) are stable
      // per source document, so cache them like generation work.
      'pdf_ingestion' => CacheConfig.generationCacheTtl,
      // Lesson planning and lesson content generation.
      'lesson_plan' ||
      'lessonplan' ||
      'teaching_lesson_plan' ||
      'lesson_agent' => CacheConfig.lessonPlanCacheTtl,
      // Conversational features.
      'tutor' || 'chat' || 'mentor' => CacheConfig.tutorCacheTtl,
      // Answer evaluation is stable per question and answer.
      'evaluation' || 'teaching_evaluation' => CacheConfig.evaluationCacheTtl,
      // Generated artifacts are deterministic for a given source and prompt.
      // 'question_variants' is the feature string used by
      // QuestionVariantService.generateVariants() (prep-category, §4.1).
      // 'question_variant_generation' is retained for cache-key continuity
      // with entries created before the feature-string alignment fix.
      'generation' ||
      'question_generation' ||
      'question_variants' ||
      'question_variant_generation' ||
      'flashcard_generation' ||
      'concept_map_generation' ||
      'study_guide_generation' ||
      'slide_deck_structure' ||
      'slide_deck_chapter' => CacheConfig.generationCacheTtl,
      // Summaries and compression of stable content.
      'summarization' ||
      'content_summarization' ||
      'teaching_summary' ||
      'teaching_lesson_recap' ||
      'long_term_memory_summary' ||
      'conversation_memory_compression' => CacheConfig.summarizationCacheTtl,
      _ => CacheConfig.defaultCacheTtl,
    };
  }
}
