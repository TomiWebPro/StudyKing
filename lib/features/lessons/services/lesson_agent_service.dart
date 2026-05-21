import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class LessonAgentService {
  static final Logger _logger = const Logger('LessonAgentService');

  final LlmService _llmService;
  final String _modelId;
  final LessonRepository _lessonRepository;
  final LlmTaskManager? _taskManager;

  LessonAgentService({
    required LlmService llmService,
    required String modelId,
    required LessonRepository lessonRepository,
    required DatabaseService database,
    LlmTaskManager? taskManager,
  })  : _llmService = llmService,
        _modelId = modelId,
        _lessonRepository = lessonRepository,
        _taskManager = taskManager;

  Future<Lesson?> generateLesson({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    required String localeName,
  }) async {
    final taskId = _taskManager?.createTask(feature: 'lesson_agent', modelId: _modelId) ?? '';
    _taskManager?.startTask(taskId);

    try {
      final blocks = await _generateLessonBlocks(subjectId, topicId, topicTitle, localeName);

      final lesson = Lesson(
        id: const Uuid().v4(),
        subjectId: subjectId,
        title: topicTitle,
        topicId: topicId,
        blocks: blocks,
        difficulty: 3,
        generatedBy: GeneratedBy.ai,
        createdAt: DateTime.now(),
      );

      final createResult = await _lessonRepository.create(lesson);
      if (createResult.isFailure) {
        _taskManager?.failTask(taskId, createResult.error!);
        return null;
      }

      _taskManager?.completeTask(taskId);
      return lesson;
    } catch (e) {
      _logger.w('Failed to generate lesson', e);
      _taskManager?.failTask(taskId, e.toString());
      return null;
    }
  }

  Future<List<LessonBlock>> _generateLessonBlocks(
    String subjectId,
    String topicId,
    String topicTitle,
    String localeName,
  ) async {
    final prompt = _buildLessonPrompt(topicTitle, localeName);

    final result = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: _lessonSystemPrompt(localeName),
      feature: 'lesson_agent',
    );

    if (result.isFailure || result.data == null) {
      _logger.w('LLM lesson generation failed: ${result.error}');
      return _fallbackBlocks(subjectId, topicId, topicTitle, localeName);
    }

    final blocks = _parseBlocks(result.data!, subjectId);
    if (blocks.isEmpty) {
      return _fallbackBlocks(subjectId, topicId, topicTitle, localeName);
    }

    return blocks.map((b) => b.copyWith(lessonId: topicId)).toList();
  }

  List<LessonBlock> _parseBlocks(String llmResponse, String subjectId) {
    try {
      final data = jsonDecode(llmResponse);
      if (data is List) {
        return data.map((item) => _parseBlock(item, subjectId)).whereType<LessonBlock>().toList();
      }
      if (data is Map && data.containsKey('blocks')) {
        return (data['blocks'] as List).map((item) => _parseBlock(item, subjectId)).whereType<LessonBlock>().toList();
      }
    } catch (e) {
      _logger.w('Failed to parse LLM lesson blocks, trying text fallback', e);
    }

    return _parseBlocksFromText(llmResponse, subjectId);
  }

  List<LessonBlock> _parseBlocksFromText(String text, String subjectId) {
    final blocks = <LessonBlock>[];
    final lines = text.split('\n');
    var order = 0;
    final buffer = StringBuffer();

    LessonBlockType? currentType;

    for (final line in lines) {
      final trimmed = line.normalized;
      if (trimmed.startsWith('#slide') || trimmed.startsWith('slide:')) {
        if (currentType != null && buffer.isNotEmpty) {
          blocks.add(LessonBlock(
            id: const Uuid().v4(),
            subjectId: subjectId,
            lessonId: '',
            type: currentType,
            content: buffer.toString().trim(),
            order: order++,
          ));
          buffer.clear();
        }
        currentType = LessonBlockType.slide;
        buffer.writeln(line.replaceFirst(RegExp(r'^#?slide:\s*', caseSensitive: false), ''));
      } else if (trimmed.startsWith('#quiz') || trimmed.startsWith('quiz:')) {
        if (currentType != null && buffer.isNotEmpty) {
          blocks.add(LessonBlock(
            id: const Uuid().v4(),
            subjectId: subjectId,
            lessonId: '',
            type: currentType,
            content: buffer.toString().trim(),
            order: order++,
          ));
          buffer.clear();
        }
        currentType = LessonBlockType.quiz;
        buffer.writeln(line.replaceFirst(RegExp(r'^#?quiz:\s*', caseSensitive: false), ''));
      } else if (trimmed.startsWith('#exercise') || trimmed.startsWith('exercise:')) {
        if (currentType != null && buffer.isNotEmpty) {
          blocks.add(LessonBlock(
            id: const Uuid().v4(),
            subjectId: subjectId,
            lessonId: '',
            type: currentType,
            content: buffer.toString().trim(),
            order: order++,
          ));
          buffer.clear();
        }
        currentType = LessonBlockType.exercise;
        buffer.writeln(line.replaceFirst(RegExp(r'^#?exercise:\s*', caseSensitive: false), ''));
      } else if (trimmed.startsWith('#summary') || trimmed.startsWith('summary:')) {
        if (currentType != null && buffer.isNotEmpty) {
          blocks.add(LessonBlock(
            id: const Uuid().v4(),
            subjectId: subjectId,
            lessonId: '',
            type: currentType,
            content: buffer.toString().trim(),
            order: order++,
          ));
          buffer.clear();
        }
        currentType = LessonBlockType.summary;
        buffer.writeln(line.replaceFirst(RegExp(r'^#?summary:\s*', caseSensitive: false), ''));
      } else if (trimmed.startsWith('#example') || trimmed.startsWith('example:')) {
        if (currentType != null && buffer.isNotEmpty) {
          blocks.add(LessonBlock(
            id: const Uuid().v4(),
            subjectId: subjectId,
            lessonId: '',
            type: currentType,
            content: buffer.toString().trim(),
            order: order++,
          ));
          buffer.clear();
        }
        currentType = LessonBlockType.example;
        buffer.writeln(line.replaceFirst(RegExp(r'^#?example:\s*', caseSensitive: false), ''));
      } else {
        currentType ??= LessonBlockType.text;
        buffer.writeln(line);
      }
    }

    if (buffer.isNotEmpty && currentType != null) {
      blocks.add(LessonBlock(
        id: const Uuid().v4(),
        subjectId: subjectId,
        lessonId: '',
        type: currentType,
        content: buffer.toString().trim(),
        order: order,
      ));
    }

    return blocks;
  }

  LessonBlock? _parseBlock(dynamic item, String subjectId) {
    try {
      final map = item as Map<String, dynamic>;
      final typeStr = map['type'] as String? ?? 'text';
      final type = LessonBlockType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => LessonBlockType.text,
      );
      return LessonBlock(
        id: const Uuid().v4(),
        subjectId: subjectId,
        lessonId: '',
        type: type,
        content: map['content'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  List<LessonBlock> _fallbackBlocks(String subjectId, String topicId, String topicTitle, String localeName) {
    final l10n = lookupAppLocalizations(Locale(localeName));
    return [
      LessonBlock(
        id: const Uuid().v4(),
        subjectId: subjectId,
        lessonId: topicId,
        type: LessonBlockType.text,
        content: '${l10n.lessonFallbackTitle}: $topicTitle',
        order: 0,
      ),
      LessonBlock(
        id: const Uuid().v4(),
        subjectId: subjectId,
        lessonId: topicId,
        type: LessonBlockType.text,
        content: l10n.lessonFallbackContent(topicTitle),
        order: 1,
      ),
    ];
  }

  String _buildLessonPrompt(String topicTitle, String localeName) {
    return lookupAppLocalizations(Locale(localeName)).lessonBuildPrompt(topicTitle, localeName);
  }

  String _lessonSystemPrompt(String localeName) {
    return lookupAppLocalizations(Locale(localeName)).lessonSystemPrompt(localeName);
  }

  Future<Lesson?> generateLessonFromSource({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    required String sourceContent,
    required String localeName,
  }) async {
    final prompt = lookupAppLocalizations(Locale(localeName)).lessonBuildPromptFromSource(sourceContent, topicTitle, localeName);

    final result = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: _lessonSystemPrompt(localeName),
      feature: 'lesson_agent',
    );

    if (result.isFailure || result.data == null) return null;

    final blocks = _parseBlocks(result.data!, subjectId);
    if (blocks.isEmpty) return null;

    final lesson = Lesson(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: topicTitle,
      topicId: topicId,
      blocks: blocks,
      generatedBy: GeneratedBy.ai,
      createdAt: DateTime.now(),
    );

    final createResult = await _lessonRepository.create(lesson);
    if (createResult.isFailure) return null;
    return lesson;
  }
}
