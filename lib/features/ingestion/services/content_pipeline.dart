import 'dart:convert';

import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/utils/id_generator.dart';

class ContentPipeline {
  final LlmService _llmService;
  final SourceRepository _sourceRepository;
  final TopicRepository _topicRepository;
  final QuestionRepository _questionRepository;
  final DocumentExtractor _documentExtractor;
  final WebScraper _webScraper;
  final Logger _logger = const Logger('ContentPipeline');

  ContentPipeline({
    required LlmService llmService,
    required SourceRepository sourceRepository,
    required TopicRepository topicRepository,
    required QuestionRepository questionRepository,
    DocumentExtractor? documentExtractor,
    WebScraper? webScraper,
  })  : _llmService = llmService,
        _sourceRepository = sourceRepository,
        _topicRepository = topicRepository,
        _questionRepository = questionRepository,
        _documentExtractor = documentExtractor ?? DocumentExtractor(),
        _webScraper = webScraper ?? WebScraper();

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
      );

      await _sourceRepository.create(source);
      _logger.d('Source saved: ${source.id}');
      return Result.success(source);
    } catch (e) {
      _logger.e('Failed to save source', e);
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
  }) async {
    try {
      final sourceId = IdGenerator.generate('src');
      final source = Source(
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
      );
      await _sourceRepository.create(source);
      _logger.d('Source created: ${source.id}');

      Source updated = source;

      updated = _updateStatus(updated, ProcessingStatus.extracting);
      final extracted = _documentExtractor.extractText(
        rawContent: content,
        sourceType: type,
      );
      updated = updated.copyWith(extractedText: extracted);
      await _sourceRepository.save(updated.id, updated);
      _logger.d('Stage 1 complete: text extracted (${extracted.length} chars)');

      final textToClassify = extracted.isNotEmpty ? extracted : content;

      if (possibleTopics.isNotEmpty) {
        updated = _updateStatus(updated, ProcessingStatus.classifying);
        final matchedTopicId = await _classifyTopic(
          textToClassify,
          possibleTopics,
          modelId,
        );
        if (matchedTopicId.isNotEmpty) {
          updated = updated.copyWith(topicId: matchedTopicId);
          await _sourceRepository.save(updated.id, updated);
        }
        _logger.d('Stage 2 complete: topic classified');
      }

      updated = _updateStatus(updated, ProcessingStatus.classifying);
      final summary = await _generateSummary(textToClassify, modelId);
      if (summary.isNotEmpty) {
        updated = updated.copyWith(summary: summary);
        await _sourceRepository.save(updated.id, updated);
      }
      _logger.d('Stage 3 complete: summary generated');

      if (generateQuestions) {
        updated = _updateStatus(updated, ProcessingStatus.generatingQuestions);
        final questionIds = await _generateQuestions(
          textToClassify,
          subjectId,
          updated.topicId,
          sourceId,
          studentId,
          modelId,
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
      }

      updated = _updateStatus(updated, ProcessingStatus.completed);
      await _sourceRepository.save(updated.id, updated);
      _logger.d('Pipeline complete for source: ${updated.id}');

      return Result.success(updated);
    } catch (e) {
      _logger.e('Pipeline failed', e);
      try {
        final failed = Source(
          id: 'src_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          type: type,
          content: content,
          subjectId: subjectId,
          topicId: topicId,
          syllabusId: syllabusId,
          sourceUrl: sourceUrl,
          studentId: studentId,
          language: language,
          processingStatus: ProcessingStatus.failed.name,
        );
        await _sourceRepository.create(failed);
        return Result.success(failed);
      } catch (e2) {
        _logger.e('Failed to save failed source', e2);
        return Result.failure(e.toString());
      }
    }
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
  ) async {
    if (possibleTopics.isEmpty) return '';
    try {
      final prompt = '''
Classify the following content into one of these topics: ${possibleTopics.join(', ')}.

Content:
$content

Return only the single most relevant topic name from the list. Do not explain. Do not add extra text.''';

      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt:
            'You are a content classifier. Respond only with the topic name.',
        feature: 'content_classification',
      );

      final cleaned = response.trim();
      final validTopic = possibleTopics.where(
        (t) => cleaned.toLowerCase().contains(t.toLowerCase()) ||
            t.toLowerCase().contains(cleaned.toLowerCase()),
      );
      if (validTopic.isEmpty) return '';

      try {
        final topics = await _topicRepository.getAll();
        final topicTitle = validTopic.first;
        final topicMatch = topics.where(
          (t) => t.title.toLowerCase().contains(topicTitle.toLowerCase()),
        ).firstOrNull;
        if (topicMatch != null) return topicMatch.id;
      } catch (e) {
        _logger.e('Failed to look up topic by title', e);
      }

      return '';
    } catch (e) {
      _logger.e('Classification failed', e);
      return '';
    }
  }

  Future<String> _generateSummary(
    String content,
    String modelId,
  ) async {
    try {
      final prompt = '''
Summarize the following content in 3-5 concise sentences.

Content:
$content

Provide only the summary text.''';

      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt:
            'You are a summarization assistant. Provide concise summaries.',
        feature: 'content_summarization',
      );

      return response.trim();
    } catch (e) {
      _logger.e('Summary generation failed', e);
      return '';
    }
  }

  Future<List<String>> _generateQuestions(
    String content,
    String subjectId,
    String topicId,
    String sourceId,
    String studentId,
    String modelId,
  ) async {
    final questionIds = <String>[];
    try {
      final prompt = '''
Generate 3-5 practice questions based on the following content. Return ONLY a JSON array.
Each object must have: "text" (the question), "type" ("singleChoice"), "options" (list of 4 answer strings), "correctAnswer" (the correct option text), "explanation" (brief explanation).

Content:
$content''';

      final response = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt:
            'You are a question generator. Return only valid JSON array.',
        feature: 'question_generation',
      );

      final parsed = _parseQuestionResponse(response);
      for (final qData in parsed) {
        final qId = IdGenerator.generate('q');
        final question = Question(
          id: qId,
          text: qData['text'] as String? ?? '',
          type: QuestionType.singleChoice,
          subjectId: subjectId,
          topicId: topicId,
          sourceIds: [sourceId],
          options: (qData['options'] as List<dynamic>?)?.cast<String>() ?? [],
          markscheme: Markscheme(
            questionId: qId,
            correctAnswer: qData['correctAnswer'] as String? ?? '',
            explanation: qData['explanation'] as String?,
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
      _logger.e('Question generation failed', e);
    }
    return questionIds;
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
      _logger.e('Failed to parse question response', e);
    }
    return [];
  }

  void dispose() {
    _webScraper.dispose();
  }
}
