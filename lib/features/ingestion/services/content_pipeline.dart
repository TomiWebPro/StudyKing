import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;

import 'package:flutter/material.dart';
import 'package:studyking/core/data/extraction/asr_engine.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/features/ingestion/services/chunked_content_processor.dart';
import 'package:studyking/features/ingestion/services/document_extractor.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/lessons/services/slide_deck_generator.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/features/flashcards/services/flashcard_generator.dart';

typedef QuestionValidator = bool Function(Map<String, dynamic> questionData);
typedef ProcessingProgressCallback = void Function(ProcessingStatus status, String stageDescription);

class ContentPipeline {
  final LlmService _llmService;
  final SourceRepository _sourceRepository;

  SourceRepository get sourceRepository => _sourceRepository;
  final TopicRepository _topicRepository;
  final QuestionRepository _questionRepository;
  final LessonAgentService? _lessonAgentService;
  final SlideDeckGenerator? _slideDeckGenerator;
  final FlashcardGenerator? _flashcardGenerator;
  final DocumentExtractor _documentExtractor;
  final WebScraper _webScraper;
  final ChunkedContentProcessor _chunkedProcessor;
  final String _localeName;
  final String _feature;
  static final Logger _logger = const Logger('ContentPipeline');

  AppLocalizations get _l10n => lookupAppLocalizations(Locale(_localeName));

  ContentPipeline({
    required LlmService llmService,
    required SourceRepository sourceRepository,
    required TopicRepository topicRepository,
    required QuestionRepository questionRepository,
    LessonAgentService? lessonAgentService,
    SlideDeckGenerator? slideDeckGenerator,
    FlashcardGenerator? flashcardGenerator,
    DocumentExtractor? documentExtractor,
    WebScraper? webScraper,
    ChunkedContentProcessor? chunkedProcessor,
    required String transcriptionModelId,
    required String localeName,
    AsrEngine? asrEngine,
    String feature = 'pdf_ingestion',
  })  : _llmService = llmService,
        _sourceRepository = sourceRepository,
        _topicRepository = topicRepository,
        _questionRepository = questionRepository,
        _lessonAgentService = lessonAgentService,
        _slideDeckGenerator = slideDeckGenerator,
        _flashcardGenerator = flashcardGenerator,
        _documentExtractor =
            documentExtractor ?? DocumentExtractor(llmService: llmService, modelId: transcriptionModelId, localeName: localeName, asrEngine: asrEngine),
        _webScraper = webScraper ?? WebScraper(),
        _chunkedProcessor = chunkedProcessor ??
            ChunkedContentProcessor(llmService: llmService, localeName: localeName, feature: feature),
        _localeName = localeName,
        _feature = feature;

  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    _chunkedProcessor.cancel();
  }

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
      final contentHash = _computeContentHash(content);
      final duplicate = await _findDuplicateByHash(contentHash);
      if (duplicate != null) {
        return Result.failure(
          'DUPLICATE:${duplicate.id}:${duplicate.title}',
        );
      }
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
        contentHash: contentHash,
      );

      final createResult = await _sourceRepository.create(source);
      if (createResult.isFailure) {
        _logger.w('Failed to save source ${source.id}', createResult.error);
        return Result.failure(createResult.error);
      }
      _logger.d('Source saved: ${source.id}');
      return Result.success(source);
    } catch (e) {
      _logger.w('Failed to save source', e);
      return Result.failure(e.toString());
    }
  }

  String _computeContentHash(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  Future<Source?> _findDuplicateByHash(String hash) async {
    try {
      final allResult = await _sourceRepository.getAll();
      final all = allResult.data ?? [];
      for (final s in all) {
        if (s.contentHash == hash) return s;
      }
    } catch (e) {
      _logger.w('Failed to check duplicates', e);
    }
    return null;
  }

  String userFriendlyError(dynamic error) {
    final l10n = _l10n;
    final msg = error.toString();
    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return l10n.pipelineErrorTimeout;
    }
    if (msg.contains('429') || msg.contains('rate limit') || msg.contains('Too many requests')) {
      return l10n.pipelineErrorRateLimited;
    }
    if (msg.contains('401') || msg.contains('API key') || msg.contains('auth')) {
      return l10n.pipelineErrorInvalidApiKey;
    }
    if (msg.contains('404') || msg.contains('not found') || msg.contains('Model not found')) {
      return l10n.pipelineErrorModelNotFound;
    }
    if (msg.contains('FormatException') || msg.contains('JSON') || msg.contains('parse')) {
      return l10n.pipelineErrorMalformedResponse;
    }
    if (msg.contains('pdf') || msg.contains('Could not read')) {
      return l10n.pipelineErrorUnreadableFile;
    }
    return msg;
  }

  Future<Result<Source>> processFullPipeline({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    bool generateSlideDecks = false,
    bool generateFlashcards = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = _defaultAllowedTypes,
    ProcessingProgressCallback? onProgress,
    String? existingSourceId,
    List<String> oldQuestionIds = const [],
  }) async {
    _cancelled = false;
    final sourceId = existingSourceId ?? IdGenerator.generate('src');
    Source source;
    try {
      final contentHash = _computeContentHash(content);
      if (existingSourceId == null) {
        final duplicate = await _findDuplicateByHash(contentHash);
        if (duplicate != null && duplicate.id != sourceId) {
          return Result.failure(
            'DUPLICATE:${duplicate.id}:${duplicate.title}',
          );
        }
      }
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
        contentHash: contentHash,
      );
      final persistResult = existingSourceId != null
          ? await _sourceRepository.save(sourceId, source)
          : await _sourceRepository.create(source);
      if (persistResult.isFailure) {
        _logger.w(
          'Failed to persist source ${source.id}',
          persistResult.error,
        );
        return Result.failure(persistResult.error);
      }
      _logger.d('Source created: ${source.id}');
    } catch (e) {
      _logger.w('Failed to create initial source', e);
      return Result.failure(e.toString());
    }

    try {
      Source updated = source;

      if (_cancelled) return Result.failure('Pipeline cancelled');
      onProgress?.call(ProcessingStatus.extracting, _l10n.pipelineStageExtracting);
      updated = _updateStatus(updated, ProcessingStatus.extracting);
      final extractionResult = await _documentExtractor.extractText(
        rawContent: content,
        sourceType: type,
        sourceUrl: sourceUrl,
      );

      // Vision integrity (agent_must_read.md §9, Vision Next-Term §3.1): never
      // persist a raw URL/path as `extractedText`. When extraction could not
      // recover real material (e.g. transcript missing, OCR unavailable for an
      // image/audio/video URL), the ExtractionResult is an error. Halt the
      // pipeline there and surface a student-readable failure instead of letting
      // the classification/summarisation/question stages run on a URL string as
      // if it were the student's material.
      if (extractionResult.isError) {
        final failed = updated.copyWith(
          processingStatus: ProcessingStatus.failed.name,
          extractionMethod: extractionResult.extractionMethod,
          extractedText: '',
          chunks: '',
          figuresJson: '',
          extractionMeta: jsonEncode(extractionResult.toMetaJson()),
          errorMessage: extractionResult.errorMessage ?? 'Extraction failed',
        );
        final failedSave = await _saveSource(failed);
        if (failedSave.isFailure) {
          _logger.w(
            'Failed to persist failed source ${source.id}',
            failedSave.error,
          );
        }
        _logger.w(
          'Extraction failed for source ${source.id}: '
          '${extractionResult.errorMessage}',
        );
        return Result.failure(
          userFriendlyError(extractionResult.errorMessage ?? 'Extraction failed'),
        );
      }

      updated = updated.copyWith(
        extractedText: extractionResult.text,
        extractionMethod: extractionResult.extractionMethod,
        chunks: extractionResult.chunksToJson(),
        figuresJson: extractionResult.figuresToJson(),
        extractionMeta: jsonEncode(extractionResult.toMetaJson()),
      );
      final extractionSave = await _saveSource(updated);
      if (extractionSave.isFailure) {
        return Result.failure(extractionSave.error);
      }
      _logger.d('Stage 1 complete: text extracted (${extractionResult.text.length} chars) via ${extractionResult.extractionMethod}');

      final textToClassify = extractionResult.text.isNotEmpty
          ? extractionResult.text
          : content;

      final chunks = extractionResult.chunks.isNotEmpty
          ? extractionResult.chunks
          : _chunkedProcessor.splitIntoChunks(textToClassify);

      _chunkedProcessor.reset();

      if (_cancelled) return Result.failure('Pipeline cancelled');
      if (possibleTopics.isNotEmpty) {
        onProgress?.call(ProcessingStatus.classifying, _l10n.pipelineStageClassifyingTopic);
        updated = _updateStatus(updated, ProcessingStatus.classifying);

        String matchedTopicId;
        if (chunks.length > 1) {
          final classificationResult = await _chunkedProcessor.classifyChunks(
            chunks: chunks,
            possibleTopics: possibleTopics,
            modelId: classificationModelId,
            subjectId: subjectId,
          );
          matchedTopicId = await _resolveClassifiedTopic(
            classificationResult.topicId,
            possibleTopics,
            subjectId,
          );
          _logger.d('Chunked classification: topic="${classificationResult.topicId}" confidence=${classificationResult.confidence.toStringAsFixed(2)}');
        } else {
          matchedTopicId = await _classifyTopic(
            textToClassify,
            possibleTopics,
            classificationModelId,
            subjectId,
          );
        }

        if (matchedTopicId.isNotEmpty) {
          updated = updated.copyWith(topicId: matchedTopicId);
          final topicSave = await _saveSource(updated);
          if (topicSave.isFailure) {
            return Result.failure(topicSave.error);
          }
        }
        _logger.d('Stage 2 complete: topic classified');
      } else if (subjectId.isNotEmpty && type == SourceType.syllabus) {
        onProgress?.call(ProcessingStatus.classifying, _l10n.pipelineStageExtractingSyllabusTopics);
        updated = _updateStatus(updated, ProcessingStatus.classifying);
        final extractedTopicIds = await _extractTopicsFromSyllabus(
          textToClassify,
          subjectId,
          classificationModelId,
        );
        if (extractedTopicIds.isNotEmpty) {
          updated = updated.copyWith(topicId: extractedTopicIds.first);
          final syllabusSave = await _saveSource(updated);
          if (syllabusSave.isFailure) {
            return Result.failure(syllabusSave.error);
          }
          _logger.d('Stage 2 alternative: ${extractedTopicIds.length} topics extracted from syllabus');
        }
      }

      if (_cancelled) return Result.failure('Pipeline cancelled');
      onProgress?.call(ProcessingStatus.summarizing, _l10n.pipelineStageSummarizing);
      updated = _updateStatus(updated, ProcessingStatus.summarizing);

      String summary = '';
      if (chunks.length > 1) {
        final summaryResult = await _chunkedProcessor.generateConsolidatedSummary(
          chunks: chunks,
          modelId: summarizationModelId,
        );
        if (summaryResult.isFailure) {
          _logger.w('Failed to generate consolidated summary: ${summaryResult.error}');
        } else {
          summary = summaryResult.data ?? '';
        }
      } else {
        summary = await _generateSummary(textToClassify, summarizationModelId);
      }

      if (summary.isNotEmpty) {
        updated = updated.copyWith(summary: summary);
        final summarySave = await _saveSource(updated);
        if (summarySave.isFailure) {
          return Result.failure(summarySave.error);
        }
      }
      _logger.d('Stage 3 complete: summary generated');

      if (_cancelled) return Result.failure('Pipeline cancelled');
      if (generateQuestions) {
        onProgress?.call(ProcessingStatus.generatingQuestions, _l10n.pipelineStageGeneratingQuestions);
        updated = _updateStatus(updated, ProcessingStatus.generatingQuestions);

        if (oldQuestionIds.isNotEmpty) {
          for (final oldId in oldQuestionIds) {
            final deleteResult = await _questionRepository.delete(oldId);
            if (deleteResult.isFailure) {
              _logger.w(
                'Failed to delete stale question $oldId',
                deleteResult.error,
              );
              return Result.failure(deleteResult.error);
            }
          }
        }

        List<String> questionIds;
        if (chunks.length > 1) {
          questionIds = await _generateQuestionsChunked(
            chunks: chunks,
            subjectId: subjectId,
            topicId: updated.topicId,
            sourceId: sourceId,
            studentId: studentId,
            generationModelId: generationModelId,
            validator: validator,
            allowedTypes: allowedQuestionTypes,
          );
        } else {
          questionIds = await _generateQuestions(
            textToClassify,
            subjectId,
            updated.topicId,
            sourceId,
            studentId,
            generationModelId,
            validator: validator,
            allowedTypes: allowedQuestionTypes,
          );
        }

        if (questionIds.isNotEmpty) {
          updated = updated.copyWith(
            generatedQuestionIds: questionIds,
          );
          final questionsSave = await _saveSource(updated);
          if (questionsSave.isFailure) {
            return Result.failure(questionsSave.error);
          }
        }
        _logger.d(
          'Stage 4 complete: ${questionIds.length} questions generated',
        );

        // Surface partial failures from chunk-level LLM processing.
        // Instead of silently marking as completed, record the failure count
        // in extractionMeta and surface errorMessage so the student sees a
        // signal (agent_must_read.md §9: content must not be blindly trusted).
        final failedChunks = _chunkedProcessor.failedChunkCount;
        if (failedChunks > 0) {
          final currentMeta = jsonDecode(updated.extractionMeta.isNotEmpty
              ? updated.extractionMeta
              : '{}') as Map<String, dynamic>;
          currentMeta['failedChunkCount'] = failedChunks;
          updated = updated.copyWith(
            extractionMeta: jsonEncode(currentMeta),
            errorMessage: '$failedChunks chunk(s) failed during LLM processing '
                'after retries; partial results generated.',
          );
          _logger.w(
            'Partial failure: $failedChunks chunk(s) failed after retries '
            'for source ${updated.id}',
          );
        }

        if (_cancelled) return Result.failure('Pipeline cancelled');
        onProgress?.call(ProcessingStatus.validating, _l10n.pipelineStageValidatingQuestions);
        updated = _updateStatus(updated, ProcessingStatus.validating);
        final validationResults = _validateGeneratedQuestions(
          updated,
          questionIds,
        );
        if (validationResults.isNotEmpty) {
          _logger.w('Question validation warnings: $validationResults');
        }
        updated = _updateStatus(updated, ProcessingStatus.completed);

        if (updated.topicId.isEmpty && questionIds.isNotEmpty) {
          _logger.w('Questions generated with empty topicId for source ${updated.id}');
        }
      }

      if (_cancelled) return Result.failure('Pipeline cancelled');
      if (generateLessons && _lessonAgentService != null && updated.topicId.isNotEmpty) {
        onProgress?.call(ProcessingStatus.generatingQuestions, _l10n.pipelineStageGeneratingLesson);
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

      if (_cancelled) return Result.failure('Pipeline cancelled');
      if (generateSlideDecks && _slideDeckGenerator != null && updated.topicId.isNotEmpty) {
        onProgress?.call(ProcessingStatus.generatingQuestions, _l10n.pipelineStageGeneratingSlideDeck);
        final textForSlideDeck = updated.extractedText.isNotEmpty ? updated.extractedText : content;
        final slideDeckResult = await _slideDeckGenerator.generateSlideDeck(
          subjectId: updated.subjectId.isNotEmpty ? updated.subjectId : subjectId,
          topicId: updated.topicId,
          topicTitle: title,
          sourceContent: textForSlideDeck,
          localeName: _localeName,
        );
        if (slideDeckResult.isSuccess) {
          _logger.d('Stage 6 complete: slide deck generated from source');
        } else {
          _logger.w(
            'Stage 6 failed: slide deck was not persisted: '
            '${slideDeckResult.error}',
          );
        }
      }

      if (_cancelled) return Result.failure('Pipeline cancelled');
      if (generateFlashcards && _flashcardGenerator != null && updated.topicId.isNotEmpty) {
        onProgress?.call(ProcessingStatus.generatingFlashcards, _l10n.pipelineStageGeneratingFlashcards);
        updated = _updateStatus(updated, ProcessingStatus.generatingFlashcards);
        final textForFlashcards = updated.extractedText.isNotEmpty ? updated.extractedText : content;
        final flashcardResult = await _flashcardGenerator.generateFlashcards(
          content: textForFlashcards,
          sourceId: sourceId,
          topicId: updated.topicId,
          subjectId: updated.subjectId.isNotEmpty ? updated.subjectId : subjectId,
          modelId: generationModelId,
          localeName: _localeName,
        );
        if (flashcardResult.isSuccess) {
          final flashcardIds = flashcardResult.data!.map((f) => f.id).toList();
          updated = updated.copyWith(generatedFlashcardIds: flashcardIds);
          final flashcardsSave = await _saveSource(updated);
          if (flashcardsSave.isFailure) {
            return Result.failure(flashcardsSave.error);
          }
        }
        _logger.d('Stage 7 complete: ${flashcardResult.data?.length ?? 0} flashcards generated from source');
      }

      if (_cancelled) return Result.failure('Pipeline cancelled');
      onProgress?.call(ProcessingStatus.completed, _l10n.pipelineStageComplete);
      updated = _updateStatus(updated, ProcessingStatus.completed);
      final completionSave = await _saveSource(updated);
      if (completionSave.isFailure) {
        return Result.failure(completionSave.error);
      }
      _logger.d('Pipeline complete for source: ${updated.id}');

      return Result.success(updated);
    } catch (e) {
      final userMsg = userFriendlyError(e);
      _logger.w('Pipeline failed', e);
      try {
        final failed = source.copyWith(
          processingStatus: ProcessingStatus.failed.name,
          errorMessage: userMsg,
        );
        await _saveSource(failed);
        return Result.failure(userMsg);
      } catch (e2) {
        _logger.w('Failed to save failed source', e2);
        return Result.failure(userMsg);
      }
    }
  }

  Future<Result<Source>> reprocessSource(
    Source source, {
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    bool generateSlideDecks = false,
    bool generateFlashcards = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = _defaultAllowedTypes,
    ProcessingProgressCallback? onProgress,
    List<String>? oldQuestionIds,
  }) async {
    final textToProcess = source.extractedText.isNotEmpty ? source.extractedText : source.content;
    if (textToProcess.isEmpty) {
      return Result.failure('Source has no content to reprocess');
    }
    final oldIds = oldQuestionIds ?? List<String>.from(source.generatedQuestionIds);
    return processFullPipeline(
      title: source.title,
      content: textToProcess,
      type: source.type,
      studentId: source.studentId.isNotEmpty ? source.studentId : '',
      classificationModelId: classificationModelId,
      summarizationModelId: summarizationModelId,
      generationModelId: generationModelId,
      subjectId: source.subjectId,
      sourceUrl: source.sourceUrl,
      language: source.language,
      possibleTopics: possibleTopics,
      generateQuestions: generateQuestions,
      generateLessons: generateLessons,
      generateSlideDecks: generateSlideDecks,
      generateFlashcards: generateFlashcards,
      validator: validator,
      allowedQuestionTypes: allowedQuestionTypes,
      onProgress: onProgress,
      existingSourceId: source.id,
      oldQuestionIds: oldIds,
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
    final result = await _webScraper.fetchPageContent(url);
    return result.map((page) => page.content);
  }

  Source _updateStatus(Source source, ProcessingStatus status) {
    return source.copyWith(processingStatus: status.name);
  }

  Future<Result<void>> _saveSource(Source source) async {
    final result = await _sourceRepository.save(source.id, source);
    if (result.isFailure) {
      _logger.w('Failed to save source ${source.id}', result.error);
    }
    return result;
  }

  Future<String> _resolveClassifiedTopic(
    String classifiedTopicName,
    List<String> possibleTopics,
    String subjectId,
  ) async {
    if (classifiedTopicName.isEmpty) return '';

    final matchedTopic = possibleTopics.where(
      (t) => classifiedTopicName.normalized.contains(t.normalized) ||
          t.normalized.contains(classifiedTopicName.normalized),
    );
    if (matchedTopic.isEmpty) return '';

    try {
      final topicsResult = await _topicRepository.getAll();
      final topics = topicsResult.data ?? [];
      final topicTitle = matchedTopic.first;
      final topicMatch = topics.where(
        (t) => t.title.normalized.contains(topicTitle.normalized),
      ).firstOrNull;
      if (topicMatch != null) return topicMatch.id;

      if (subjectId.isNotEmpty) {
        final newTopic = Topic(
          id: IdGenerator.generate('topic'),
          subjectId: subjectId,
          title: topicTitle,
          description: 'Auto-created from content classification',
          syllabusText: '',
        );
        final createResult = await _topicRepository.create(newTopic);
        if (createResult.isFailure) {
          _logger.w(
            'Failed to auto-create topic "$topicTitle" under subject $subjectId',
            createResult.error,
          );
          // Do not link or return a topic id that was never persisted.
          return '';
        }
        final subjRepo = SubjectRepository();
        await subjRepo.init();
        await subjRepo.addTopicToSubject(subjectId, newTopic.id);
        _logger.i('Auto-created topic "$topicTitle" under subject $subjectId');
        return newTopic.id;
      }
    } catch (e) {
      _logger.w('Failed to resolve classified topic', e);
    }

    return '';
  }

  Future<List<String>> _generateQuestionsChunked({
    required List<SourceChunk> chunks,
    required String subjectId,
    required String topicId,
    required String sourceId,
    required String studentId,
    required String generationModelId,
    QuestionValidator? validator,
    List<String> allowedTypes = _defaultAllowedTypes,
  }) async {
    final questionIds = <String>[];
    try {
        final chunkResults = await _chunkedProcessor.generateQuestionsFromChunks(
          chunks: chunks,
          modelId: generationModelId,
          questionParser: QuestionParser(),
        );

      final seenTexts = <String>{};
      for (final chunkResult in chunkResults) {
        final qData = chunkResult.questionData;
        final text = qData['text'] as String? ?? '';

        final normalizedText = text.normalized;
        if (seenTexts.contains(normalizedText)) {
          _logger.d('Skipping duplicate question: $text');
          continue;
        }
        seenTexts.add(normalizedText);

        if (!_isValidGeneratedQuestion(qData, validator: validator, allowedTypes: allowedTypes)) {
          _logger.w('Skipping invalid question: $text');
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
          text: text,
          type: questionType,
          subjectId: subjectId,
          topicId: topicId,
          sourceIds: [sourceId],
          options: options,
          tags: ['chunk_${chunkResult.chunkIndex}'],
          markscheme: Markscheme(
            questionId: qId,
            correctAnswer: correctAnswer,
            explanation: qData['explanation'] as String?,
            acceptableAnswers: acceptableAnswers,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // AI-generated artefacts must be marked as unvalidated until a
          // human/validator reviews them (vision_next_term.md §4.3;
          // agent_must_read.md §9: content must not be blindly trusted).
          validationStatus: ValidationStatus.pending,
        );
        final result = await _questionRepository.create(question);
        if (result.isSuccess) {
          questionIds.add(qId);
        }
      }
    } catch (e) {
      _logger.w('Chunked question generation failed, falling back to single-call', e);
      return _generateQuestions(
        chunks.map((c) => c.text).join('\n\n'),
        subjectId,
        topicId,
        sourceId,
        studentId,
        generationModelId,
        validator: validator,
        allowedTypes: allowedTypes,
      );
    }
    return questionIds;
  }

  Future<String> _classifyTopic(
    String content,
    List<String> possibleTopics,
    String classificationModelId,
    String subjectId,
  ) async {
    if (possibleTopics.isEmpty) return '';
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.classifyUserPrompt(possibleTopics.join(', '), content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: classificationModelId,
        systemPrompt: l10n.classifySystemPrompt,
        feature: _feature,
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
          final createResult = await _topicRepository.create(newTopic);
          if (createResult.isFailure) {
            _logger.w(
              'Failed to auto-create topic "$topicTitle" under subject $subjectId',
              createResult.error,
            );
            // Do not link or return a topic id that was never persisted.
            return '';
          }
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
    String classificationModelId,
  ) async {
    try {
      final prompt = 'Extract a list of topic names from the following syllabus content. '
          'Return ONLY a JSON array of strings, one per topic. No explanation, no extra text.'
          '\n\nContent:\n$content';

      final result = await _llmService.chat(
        message: prompt,
        modelId: classificationModelId,
        systemPrompt: 'You are a syllabus parser. Extract topic names as a JSON array of strings.',
        feature: _feature,
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
        final createResult = await _topicRepository.create(topic);
        if (createResult.isFailure) {
          _logger.w(
            'Failed to auto-create syllabus topic "$name" under subject $subjectId',
            createResult.error,
          );
          // Skip topics that were not persisted; their ids must not be
          // linked to the subject or returned to the caller.
          continue;
        }
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
    String summarizationModelId,
  ) async {
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.summarizeUserPrompt(content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: summarizationModelId,
        systemPrompt: l10n.summarizeSystemPrompt,
        feature: _feature,
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
    String generationModelId, {
    QuestionValidator? validator,
    List<String> allowedTypes = _defaultAllowedTypes,
  }) async {
    final questionIds = <String>[];
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.generateQuestionUserPrompt(content);

      final result = await _llmService.chat(
        message: prompt,
        modelId: generationModelId,
        systemPrompt: l10n.generateQuestionSystemPrompt,
        feature: _feature,
      );
      if (result.isFailure) return [];
      final response = result.data!;

      final parsed = _parseQuestionResponse(response);
      // Single-chunk path: this chunk represents the whole source, so apply the
      // per-chunk cap to prevent a dense page from flooding the bank in one
      // call. Excess is logged for follow-up prep.
      final clamped = parsed.take(ChunkedContentProcessor.maxQuestionsPerChunk).toList();
      if (parsed.length > ChunkedContentProcessor.maxQuestionsPerChunk) {
        _logger.i(
          'Clamping ${parsed.length} generated questions to per-chunk cap of '
          '${ChunkedContentProcessor.maxQuestionsPerChunk}; overflow queued '
          'for follow-up prep',
        );
      }
      for (final qData in clamped) {
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
          // AI-generated artefacts must be marked as unvalidated until a
          // human/validator reviews them (vision_next_term.md §4.3;
          // agent_must_read.md §9: content must not be blindly trusted).
          validationStatus: ValidationStatus.pending,
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
