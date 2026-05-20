import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/id_generator.dart';

typedef QuestionValidator = bool Function(Map<String, dynamic> questionData);
typedef ProcessingProgressCallback = void Function(ProcessingStatus status, String stageDescription);

class ContentPipeline {
  final LlmService _llmService;
  final SourceRepository _sourceRepository;

  SourceRepository get sourceRepository => _sourceRepository;
  final TopicRepository _topicRepository;
  final QuestionRepository _questionRepository;
  final LessonAgentService? _lessonAgentService;
  final DocumentExtractor _documentExtractor;
  final WebScraper _webScraper;
  final String _localeName;
  static final Logger _logger = const Logger('ContentPipeline');

  ContentPipeline({
    required LlmService llmService,
    required SourceRepository sourceRepository,
    required TopicRepository topicRepository,
    required QuestionRepository questionRepository,
    LessonAgentService? lessonAgentService,
    DocumentExtractor? documentExtractor,
    WebScraper? webScraper,
    required String modelId,
    String localeName = 'en',
  })  : _llmService = llmService,
        _sourceRepository = sourceRepository,
        _topicRepository = topicRepository,
        _questionRepository = questionRepository,
        _lessonAgentService = lessonAgentService,
        _documentExtractor =
            documentExtractor ?? DocumentExtractor(llmService: llmService, modelId: modelId),
        _webScraper = webScraper ?? WebScraper(),
        _localeName = localeName;

  Future<Result<Source>> processUpload({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
  }) async {
    try {
      final source = Source(
        id: IdGenerator.generate('src'),
        title: title,
        type: type,
        content: content,
        subjectId: subjectId,
        topicId: topicId,
        syllabusId: syllabusId,
        sourceUrl: sourceUrl,
        studentId: studentId,
        language: language,
        processingStatus: ProcessingStatus.pending.name,
        createdAt: DateTime.now(),
      );

      await _sourceRepository.create(source);
      _logger.d('Source saved: ${source.id}');
      return Result.success(source);
    } catch (e) {
      _logger.w('Failed to save source', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<Source>> processFullPipeline({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required String modelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = _defaultAllowedTypes,
    ProcessingProgressCallback? onProgress,
  }) async {
    final sourceId = IdGenerator.generate('src');
    Source source;
    try {
      source = Source(
        id: sourceId,
        title: title,
        type: type,
        content: content,
        subjectId: subjectId,
        topicId: topicId,
        syllabusId: syllabusId,
        sourceUrl: sourceUrl,
        studentId: studentId,
        language: language,
        processingStatus: ProcessingStatus.pending.name,
        createdAt: DateTime.now(),
      );
      await _sourceRepository.create(source);
      _logger.d('Source created: ${source.id}');
    } catch (e) {
      _logger.w('Failed to create initial source', e);
      return Result.failure(e.toString());
    }

    try {
      Source updated = source;

      onProgress?.call(ProcessingStatus.extracting, 'Extracting text from content...');
      updated = _updateStatus(updated, ProcessingStatus.extracting);
      final extractionResult = await _documentExtractor.extractText(
        rawContent: content,
        sourceType: type,
        sourceUrl: sourceUrl,
      );
      updated = updated.copyWith(
        extractedText: extractionResult.text,
        extractionMethod: extractionResult.extractionMethod,
        chunks: extractionResult.chunksToJson(),
        extractionMeta: jsonEncode(extractionResult.toMetaJson()),
      );
      await _sourceRepository.save(updated.id, updated);
      _logger.d('Stage 1 complete: text extracted (${extractionResult.text.length} chars) via ${extractionResult.extractionMethod}');

      final textToClassify = extractionResult.text.isNotEmpty
          ? extractionResult.text
          : content;

      if (possibleTopics.isNotEmpty) {
        onProgress?.call(ProcessingStatus.classifying, 'Classifying content topic...');
        updated = _updateStatus(updated, ProcessingStatus.classifying);
        final matchedTopicId = await _classifyTopic(
          textToClassify,
          possibleTopics,
          modelId,
          subjectId,
        );
        if (matchedTopicId.isNotEmpty) {
          updated = updated.copyWith(topicId: matchedTopicId);
          await _sourceRepository.save(updated.id, updated);
        }
        _logger.d('Stage 2 complete: topic classified');
      } else if (subjectId.isNotEmpty && type == SourceType.syllabus) {
        onProgress?.call(ProcessingStatus.classifying, 'Extracting topics from syllabus...');
        updated = _updateStatus(updated, ProcessingStatus.classifying);
        final extractedTopicIds = await _extractTopicsFromSyllabus(
          textToClassify,
          subjectId,
          modelId,
        );
        if (extractedTopicIds.isNotEmpty) {
          updated = updated.copyWith(topicId: extractedTopicIds.first);
          await _sourceRepository.save(updated.id, updated);
          _logger.d('Stage 2 alternative: ${extractedTopicIds.length} topics extracted from syllabus');
        }
      }

      onProgress?.call(ProcessingStatus.classifying, 'Generating summary...');
      updated = _updateStatus(updated, ProcessingStatus.classifying);
      final summary = await _generateSummary(textToClassify, modelId);
      if (summary.isNotEmpty) {
        updated = updated.copyWith(summary: summary);
        await _sourceRepository.save(updated.id, updated);
      }
      _logger.d('Stage 3 complete: summary generated');

      if (generateQuestions) {
        onProgress?.call(ProcessingStatus.generatingQuestions, 'Generating questions from content...');
        updated = _updateStatus(updated, ProcessingStatus.generatingQuestions);
        final questionIds = await _generateQuestions(
          textToClassify,
          subjectId,
          updated.topicId,
          sourceId,
          studentId,
          modelId,
          validator: validator,
          allowedTypes: allowedQuestionTypes,
        );
        if (questionIds.isNotEmpty) {
          updated = updated.copyWith(
            generatedQuestionIds: questionIds,
          );
          await _sourceRepository.save(updated.id, updated);
        }
        _logger.d(
          'Stage 4 complete: ${questionIds.length} questions generated',
        );

        onProgress?.call(ProcessingStatus.validating, 'Validating generated questions...');
        updated = _updateStatus(updated, ProcessingStatus.validating);
        final validationResults = _validateGeneratedQuestions(
          updated,
          questionIds,
        );
        if (validationResults.isNotEmpty) {
          _logger.w('Question validation warnings: $validationResults');
        }
        updated = _updateStatus(updated, ProcessingStatus.completed);
      }

      if (generateLessons && _lessonAgentService != null && updated.topicId.isNotEmpty) {
        onProgress?.call(ProcessingStatus.generatingQuestions, 'Generating lesson from content...');
        final textForLesson = updated.extractedText.isNotEmpty ? updated.extractedText : content;
        await _lessonAgentService.generateLessonFromSource(
          subjectId: updated.subjectId.isNotEmpty ? updated.subjectId : subjectId,
          topicId: updated.topicId,
          topicTitle: title,
          sourceContent: textForLesson,
          localeName: _localeName,
        );
        _logger.d('Stage 5 complete: lesson generated from source');
      }

      onProgress?.call(ProcessingStatus.completed, 'Pipeline complete');
      updated = _updateStatus(updated, ProcessingStatus.completed);
      await _sourceRepository.save(updated.id, updated);
      _logger.d('Pipeline complete for source: ${updated.id}');

      return Result.success(updated);
    } catch (e) {
      _logger.w('Pipeline failed', e);
      try {
        final failed = source.copyWith(
          processingStatus: ProcessingStatus.failed.name,
        );
        await _sourceRepository.save(failed.id, failed);
        return Result.failure(e.toString());
      } catch (e2) {
        _logger.w('Failed to save failed source', e2);
        return Result.failure(e.toString());
      }
    }
  }

  Future<Result<Source>> reprocessSource(
    Source source, {
    required String modelId,
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = _defaultAllowedTypes,
    ProcessingProgressCallback? onProgress,
  }) async {
    final textToProcess = source.extractedText.isNotEmpty ? source.extractedText : source.content;
    if (textToProcess.isEmpty) {
      return Result.failure('Source has no content to reprocess');
    }
    return processFullPipeline(
      title: source.title,
      content: textToProcess,
      type: source.type,
      studentId: source.studentId.isNotEmpty ? source.studentId : '',
      modelId: modelId,
      subjectId: source.subjectId,
      sourceUrl: source.sourceUrl,
      language: source.language,
      possibleTopics: possibleTopics,
      generateQuestions: generateQuestions,
      generateLessons: generateLessons,
      validator: validator,
      allowedQuestionTypes: allowedQuestionTypes,
      onProgress: onProgress,
    );
  }

  List<String> _validateGeneratedQuestions(
    Source source,
    List<String> questionIds,
  ) {
    final warnings = <String>[];
    if (questionIds.isEmpty) {
      warnings.add('No questions were generated for source ${source.id}');
    }
    return warnings;
  }

  Future<Result<String>> fetchAndScrapeUrl(String url) async {
    return _webScraper.fetchPageContent(url);
  }

  Source _updateStatus(Source source, ProcessingStatus status) {
    return source.copyWith(processingStatus: status.name);
  }

  Future<String> _classifyTopic(
    String content,
    List<String> possibleTopics,
    String modelId,
    String subjectId,
  ) async {
    if (possibleTopics.isEmpty) return '';
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.classifyUserPrompt(possibleTopics.join(', '), content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.classifySystemPrompt,
        feature: 'content_classification',
      );
      if (result.isFailure) return '';
      final response = result.data!;

      final cleaned = response.trim();
      final validTopic = possibleTopics.where(
        (t) => cleaned.normalized.contains(t.normalized) ||
            t.normalized.contains(cleaned.normalized),
      );
      if (validTopic.isEmpty) return '';

      try {
        final topicsResult = await _topicRepository.getAll();
        final topics = topicsResult.data ?? [];
        final topicTitle = validTopic.first;
        final topicMatch = topics.where(
          (t) => t.title.normalized.contains(topicTitle.normalized),
        ).firstOrNull;
        if (topicMatch != null) return topicMatch.id;

        if (subjectId.isNotEmpty) {
          final newTopic = Topic(
            id: IdGenerator.generate('topic'),
            subjectId: subjectId,
            title: topicTitle,
            description: 'Auto-created from syllabus upload',
            syllabusText: '',
          );
          await _topicRepository.create(newTopic);
          final subjRepo = SubjectRepository();
          await subjRepo.init();
          await subjRepo.addTopicToSubject(subjectId, newTopic.id);
          _logger.i('Auto-created topic "$topicTitle" under subject $subjectId');
          return newTopic.id;
        }
      } catch (e) {
        _logger.w('Failed to look up topic by title', e);
      }

      return '';
    } catch (e) {
      _logger.w('Classification failed', e);
      return '';
    }
  }

  Future<List<String>> _extractTopicsFromSyllabus(
    String content,
    String subjectId,
    String modelId,
  ) async {
    try {
      final prompt = 'Extract a list of topic names from the following syllabus content. '
          'Return ONLY a JSON array of strings, one per topic. No explanation, no extra text.'
          '\n\nContent:\n$content';

      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: 'You are a syllabus parser. Extract topic names as a JSON array of strings.',
        feature: 'syllabus_topic_extraction',
      );
      if (result.isFailure) return [];

      final response = result.data!.trim();
      final cleaned = response
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();

      List<String> topicNames;
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is List) {
          topicNames = decoded.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } else {
          return [];
        }
      } catch (e) {
        _logger.w('Failed to decode LLM topic list JSON, falling back to split parsing', e);
        topicNames = cleaned
            .split(RegExp(r'[\n,]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && !s.startsWith('[') && !s.startsWith(']'))
            .toList();
      }

      if (topicNames.isEmpty) return [];

      final createdIds = <String>[];
      await _topicRepository.init();
      final subjRepo = SubjectRepository();
      await subjRepo.init();

      for (final name in topicNames) {
        final topic = Topic(
          id: IdGenerator.generate('topic'),
          subjectId: subjectId,
          title: name,
          description: 'Auto-created from syllabus upload',
          syllabusText: '',
        );
        await _topicRepository.create(topic);
        await subjRepo.addTopicToSubject(subjectId, topic.id);
        createdIds.add(topic.id);
        _logger.i('Auto-created syllabus topic "$name" under subject $subjectId');
      }

      return createdIds;
    } catch (e) {
      _logger.w('Failed to extract topics from syllabus', e);
      return [];
    }
  }

  Future<String> _generateSummary(
    String content,
    String modelId,
  ) async {
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.summarizeUserPrompt(content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.summarizeSystemPrompt,
        feature: 'content_summarization',
      );
      if (result.isFailure) return '';
      final response = result.data!;

      return response.trim();
    } catch (e) {
      _logger.w('Summary generation failed', e);
      return '';
    }
  }

  QuestionType? _parseQuestionType(String typeStr) {
    for (final t in QuestionType.values) {
      if (t.name == typeStr) return t;
    }
    return null;
  }

  static const List<String> _defaultAllowedTypes = [
    'singleChoice',
    'multiChoice',
    'typedAnswer',
    'mathExpression',
    'essay',
    'canvas',
    'graphDrawing',
    'stepByStep',
    'fileUpload',
    'audioRecording',
  ];

  Future<List<String>> _generateQuestions(
    String content,
    String subjectId,
    String topicId,
    String sourceId,
    String studentId,
    String modelId, {
    QuestionValidator? validator,
    List<String> allowedTypes = _defaultAllowedTypes,
  }) async {
    final questionIds = <String>[];
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.generateQuestionUserPrompt(content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.generateQuestionSystemPrompt,
        feature: 'question_generation',
      );
      if (result.isFailure) return [];
      final response = result.data!;

      final parsed = _parseQuestionResponse(response);
      for (final qData in parsed) {
        if (!_isValidGeneratedQuestion(qData, validator: validator, allowedTypes: allowedTypes)) {
          _logger.w('Skipping invalid question: ${qData['text']}');
          continue;
        }
        final qId = IdGenerator.generate('q');
        final typeStr = qData['type'] as String? ?? 'singleChoice';
        final questionType = _parseQuestionType(typeStr) ?? QuestionType.singleChoice;
        final options = (qData['options'] as List<dynamic>?)?.cast<String>() ?? [];
        final correctAnswer = qData['correctAnswer'] as String? ?? '';
        final acceptableAnswers = qData['acceptableAnswers'] != null
            ? List<String>.from(qData['acceptableAnswers'] as List)
            : (correctAnswer.isNotEmpty ? [correctAnswer] : <String>[]);

        final question = Question(
          id: qId,
          text: qData['text'] as String? ?? '',
          type: questionType,
          subjectId: subjectId,
          topicId: topicId,
          sourceIds: [sourceId],
          options: options,
          markscheme: Markscheme(
            questionId: qId,
            correctAnswer: correctAnswer,
            explanation: qData['explanation'] as String?,
            acceptableAnswers: acceptableAnswers,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await _questionRepository.create(question);
        if (result.isSuccess) {
          questionIds.add(qId);
        }
      }
    } catch (e) {
      _logger.w('Question generation failed', e);
    }
    return questionIds;
  }

  bool _isValidGeneratedQuestion(
    Map<String, dynamic> qData, {
    QuestionValidator? validator,
    List<String> allowedTypes = _defaultAllowedTypes,
  }) {
    final text = qData['text'] as String? ?? '';
    if (text.isEmpty) return false;

    final typeStr = qData['type'] as String? ?? 'singleChoice';
    if (!allowedTypes.contains(typeStr)) return false;

    final questionType = _parseQuestionType(typeStr);
    if (questionType == null) return false;

    switch (questionType) {
      case QuestionType.singleChoice:
      case QuestionType.multiChoice:
        final options = (qData['options'] as List<dynamic>?)?.cast<String>() ?? [];
        if (options.length < 2) return false;
        final correctAnswer = qData['correctAnswer'] as String? ?? '';
        if (correctAnswer.isEmpty) return false;
        if (!options.contains(correctAnswer)) return false;
        break;
      case QuestionType.typedAnswer:
      case QuestionType.mathExpression:
      case QuestionType.essay:
        final correctAnswer = qData['correctAnswer'] as String? ?? '';
        if (correctAnswer.isEmpty) return false;
        break;
      case QuestionType.canvas:
      case QuestionType.graphDrawing:
        break;
      case QuestionType.stepByStep:
      case QuestionType.fileUpload:
      case QuestionType.audioRecording:
        break;
    }

    final explanation = qData['explanation'] as String? ?? '';
    if (explanation.isEmpty) return false;

    if (validator != null && !validator(qData)) return false;

    return true;
  }

  List<Map<String, dynamic>> _parseQuestionResponse(String response) {
    try {
      final cleaned = response
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      if (decoded is Map && decoded['questions'] is List) {
        return List<Map<String, dynamic>>.from(decoded['questions']);
      }
    } catch (e) {
      _logger.w('Failed to parse question response', e);
    }
    return [];
  }

  void dispose() {
    _webScraper.dispose();
    _documentExtractor.dispose();
  }
}
