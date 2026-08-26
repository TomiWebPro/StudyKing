import 'package:flutter/foundation.dart';
import 'package:studyking/core/constants/llm_defaults.dart' show defaultModelForProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart' show LlmProvider;
import 'package:studyking/core/utils/logger.dart';

/// The distinct kinds of AI work StudyKing performs. Each maps to a model
/// selection strategy via [ModelRouter].
enum LlmTaskType {
  tutor,
  mentor,
  classification,
  generation,
  summarization,
  evaluation,
  transcription,
  background;

  /// A representative feature string emitted by the corresponding consumer.
  /// Used by [LlmTaskType.fromFeature] to map usage records to a task type.
  String get featureHint {
    switch (this) {
      case LlmTaskType.tutor:
        return 'tutor';
      case LlmTaskType.mentor:
        return 'mentor';
      case LlmTaskType.classification:
        return 'content_classification';
      case LlmTaskType.generation:
        return 'question_generation';
      case LlmTaskType.summarization:
        return 'content_summarization';
      case LlmTaskType.evaluation:
        return 'teaching_evaluation';
      case LlmTaskType.transcription:
        return 'transcription';
      case LlmTaskType.background:
        return 'background';
    }
  }

  /// Best-effort mapping from an arbitrary `feature` string passed to the
  /// LLM service to a [LlmTaskType]. Returns `null` when the feature cannot
  /// be confidently classified.
  static LlmTaskType? fromFeature(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('transcription') || f.contains('ocr')) {
      return LlmTaskType.transcription;
    }
    if (f.contains('classif')) return LlmTaskType.classification;
    if (f.contains('question_generation') ||
        f.contains('variant_generation') ||
        f.contains('flashcard_generation') ||
        f.contains('study_guide') ||
        f.contains('concept_map') ||
        f.contains('slide_deck') ||
        f.contains('lesson_agent')) {
      return LlmTaskType.generation;
    }
    if (f.contains('summar')) return LlmTaskType.summarization;
    if (f.contains('evaluation') || f.contains('_eval')) {
      return LlmTaskType.evaluation;
    }
    if (f.contains('mentor')) return LlmTaskType.mentor;
    if (f.contains('tutor') || f.contains('teaching')) {
      return LlmTaskType.tutor;
    }
    if (f.contains('background') || f.contains('idle')) {
      return LlmTaskType.background;
    }
    return null;
  }
}

/// Per-task model configuration. Any field left empty falls back to the
/// router's sensible default for that task.
@immutable
class TaskModelConfig {
  final String tutorModelId;
  final String mentorModelId;
  final String classificationModelId;
  final String generationModelId;
  final String summarizationModelId;
  final String evaluationModelId;
  final String transcriptionModelId;
  final bool useLocalForBackground;

  const TaskModelConfig({
    this.tutorModelId = '',
    this.mentorModelId = '',
    this.classificationModelId = '',
    this.generationModelId = '',
    this.summarizationModelId = '',
    this.evaluationModelId = '',
    this.transcriptionModelId = '',
    this.useLocalForBackground = false,
  });

  factory TaskModelConfig.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value) => value?.toString() ?? '';
    return TaskModelConfig(
      tutorModelId: asString(json['tutorModelId']),
      mentorModelId: asString(json['mentorModelId']),
      classificationModelId: asString(json['classificationModelId']),
      generationModelId: asString(json['generationModelId']),
      summarizationModelId: asString(json['summarizationModelId']),
      evaluationModelId: asString(json['evaluationModelId']),
      transcriptionModelId: asString(json['transcriptionModelId']),
      useLocalForBackground: json['useLocalForBackground'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tutorModelId': tutorModelId,
        'mentorModelId': mentorModelId,
        'classificationModelId': classificationModelId,
        'generationModelId': generationModelId,
        'summarizationModelId': summarizationModelId,
        'evaluationModelId': evaluationModelId,
        'transcriptionModelId': transcriptionModelId,
        'useLocalForBackground': useLocalForBackground,
      };

  TaskModelConfig copyWith({
    String? tutorModelId,
    String? mentorModelId,
    String? classificationModelId,
    String? generationModelId,
    String? summarizationModelId,
    String? evaluationModelId,
    String? transcriptionModelId,
    bool? useLocalForBackground,
  }) {
    return TaskModelConfig(
      tutorModelId: tutorModelId ?? this.tutorModelId,
      mentorModelId: mentorModelId ?? this.mentorModelId,
      classificationModelId: classificationModelId ?? this.classificationModelId,
      generationModelId: generationModelId ?? this.generationModelId,
      summarizationModelId: summarizationModelId ?? this.summarizationModelId,
      evaluationModelId: evaluationModelId ?? this.evaluationModelId,
      transcriptionModelId: transcriptionModelId ?? this.transcriptionModelId,
      useLocalForBackground: useLocalForBackground ?? this.useLocalForBackground,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelConfig &&
          runtimeType == other.runtimeType &&
          tutorModelId == other.tutorModelId &&
          mentorModelId == other.mentorModelId &&
          classificationModelId == other.classificationModelId &&
          generationModelId == other.generationModelId &&
          summarizationModelId == other.summarizationModelId &&
          evaluationModelId == other.evaluationModelId &&
          transcriptionModelId == other.transcriptionModelId &&
          useLocalForBackground == other.useLocalForBackground;

  @override
  int get hashCode => Object.hash(
        tutorModelId,
        mentorModelId,
        classificationModelId,
        generationModelId,
        summarizationModelId,
        evaluationModelId,
        transcriptionModelId,
        useLocalForBackground,
      );
}

/// Resolves the model ID to use for a given [LlmTaskType], honoring explicit
/// per-task configuration when present and applying capability-based fallback
/// (e.g. transcription requires a multimodal-capable model) with a warning.
class ModelRouter {
  static final Logger _logger = const Logger('ModelRouter');

  final TaskModelConfig config;
  final String fallbackModelId;
  final LlmProvider provider;

  /// Substrings that identify a model as multimodal-capable (vision/OCR).
  static const Set<String> _multimodalKeywords = {
    'vision',
    'gemini',
    'gpt-4o',
    'gpt-4-vision',
    'claude',
    'llava',
    'qwen-vl',
    'pixtral',
    'molmo',
    'internvl',
  };

  const ModelRouter({
    required this.config,
    required this.fallbackModelId,
    required this.provider,
  });

  /// Returns the model ID to use for [taskType].
  String resolve(LlmTaskType taskType) {
    final configured = _configuredFor(taskType);
    final candidate = configured.isNotEmpty ? configured : _defaultFor(taskType);

    if (taskType == LlmTaskType.background && config.useLocalForBackground) {
      if (provider == LlmProvider.ollama) {
        return configured.isNotEmpty ? configured : 'llama3';
      }
      _logger.w(
        'useLocalForBackground enabled but provider is not ollama; '
        'cannot run a local model, falling back to main model',
      );
      return fallbackModelId.isNotEmpty
          ? fallbackModelId
          : defaultModelForProvider(provider);
    }

    if (taskType == LlmTaskType.transcription && !_isMultimodal(candidate)) {
      _logger.w(
        'Configured transcription model "$candidate" is not known to be '
        'multimodal; falling back to a multimodal-capable model',
      );
      return fallbackModelId.isNotEmpty
          ? fallbackModelId
          : _multimodalDefault();
    }

    return candidate;
  }

  String _configuredFor(LlmTaskType taskType) {
    switch (taskType) {
      case LlmTaskType.tutor:
        return config.tutorModelId;
      case LlmTaskType.mentor:
        return config.mentorModelId;
      case LlmTaskType.classification:
        return config.classificationModelId;
      case LlmTaskType.generation:
        return config.generationModelId;
      case LlmTaskType.summarization:
        return config.summarizationModelId;
      case LlmTaskType.evaluation:
        return config.evaluationModelId;
      case LlmTaskType.transcription:
        return config.transcriptionModelId;
      case LlmTaskType.background:
        return '';
    }
  }

  String _defaultFor(LlmTaskType taskType) {
    switch (taskType) {
      case LlmTaskType.tutor:
      case LlmTaskType.mentor:
      case LlmTaskType.generation:
      case LlmTaskType.summarization:
      case LlmTaskType.evaluation:
        return fallbackModelId.isNotEmpty
            ? fallbackModelId
            : defaultModelForProvider(provider);
      case LlmTaskType.classification:
        return _cheapDefault();
      case LlmTaskType.background:
        return _cheapDefault();
      case LlmTaskType.transcription:
        return _multimodalDefault();
    }
  }

  String _cheapDefault() {
    switch (provider) {
      case LlmProvider.openRouter:
        return 'google/gemma-2-2b-it';
      case LlmProvider.ollama:
        return 'llama3.2';
      case LlmProvider.openAI:
        return 'gpt-4o-mini';
      case LlmProvider.custom:
        return 'gpt-4o-mini';
    }
  }

  String _multimodalDefault() {
    switch (provider) {
      case LlmProvider.openRouter:
        return 'google/gemini-2.0-flash-001';
      case LlmProvider.ollama:
        return 'llava';
      case LlmProvider.openAI:
        return 'gpt-4o-mini';
      case LlmProvider.custom:
        return 'gpt-4o-mini';
    }
  }

  static bool _isMultimodal(String modelId) {
    final m = modelId.toLowerCase();
    return _multimodalKeywords.any((keyword) => m.contains(keyword));
  }
}
