import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ChunkedContentProcessor {
  final LlmService _llmService;
  final String _localeName;
  final String _feature;
  static final Logger _logger = const Logger('ChunkedContentProcessor');

  static const int _maxCharsPerChunk = 3000;
  static const int _parallelBatchSize = 3;
  static const Duration _delayBetweenBatches = Duration(milliseconds: 500);

  /// Per-chunk question cap (K). A single dense page can yield hundreds of
  /// questions from one LLM call; we keep at most this many per chunk so token
  /// spend and the question bank are bounded. Excess is logged as follow-up prep
  /// (agent_must_read.md §9: generated content must not be blindly trusted).
  static const int maxQuestionsPerChunk = 8;

  /// Per-source question cap (M). Total questions produced for a single source
  /// across all chunks; once reached, remaining chunks are skipped (early break
  /// saves tokens) and the overflow is logged for follow-up prep.
  static const int maxQuestionsPerSource = 48;

  /// Maximum number of retry attempts for transient LLM failures (e.g. 429
  /// rate-limit, timeouts). Per-chunk failures that exhaust retries are
  /// counted in [failedChunkCount] so the pipeline can surface partial
  /// results instead of silently marking everything `completed`.
  final int _maxRetryAttempts;
  final Duration _retryInitialDelay;

  /// Number of chunks that failed all retry attempts during the current
  /// processing run. Reset by [reset].
  int failedChunkCount = 0;

  ChunkedContentProcessor({
    required LlmService llmService,
    required String localeName,
    int maxRetryAttempts = 3,
    Duration retryInitialDelay = const Duration(milliseconds: 500),
    String feature = 'pdf_ingestion',
  })  : _llmService = llmService,
        _localeName = localeName,
        _maxRetryAttempts = maxRetryAttempts,
        _retryInitialDelay = retryInitialDelay,
        _feature = feature;

  List<SourceChunk> splitIntoChunks(String text) {
    if (text.isEmpty) return [];
    if (text.length <= _maxCharsPerChunk) {
      return [
        SourceChunk(chunkIndex: 0, text: text),
      ];
    }

    final chunks = <SourceChunk>[];
    final sections = _splitBySections(text);

    if (sections.length > 1) {
      var currentBuffer = StringBuffer();

      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
        if (currentBuffer.length + section.length > _maxCharsPerChunk &&
            currentBuffer.isNotEmpty) {
          chunks.add(SourceChunk(
            chunkIndex: chunks.length,
            text: currentBuffer.toString().trim(),
            heading: _extractLeadingHeading(currentBuffer.toString()),
          ));
          currentBuffer = StringBuffer();
        }
        currentBuffer.write(section);
      }

      if (currentBuffer.isNotEmpty) {
        chunks.add(SourceChunk(
          chunkIndex: chunks.length,
          text: currentBuffer.toString().trim(),
          heading: _extractLeadingHeading(currentBuffer.toString()),
        ));
      }
    } else {
      var start = 0;
      while (start < text.length) {
        var end = start + _maxCharsPerChunk;
        if (end < text.length) {
          final lastNewline = text.lastIndexOf('\n', end);
          if (lastNewline > start + _maxCharsPerChunk ~/ 2) {
            end = lastNewline + 1;
          }
        } else {
          end = text.length;
        }

        final chunkText = text.substring(start, end).trim();
        if (chunkText.isNotEmpty) {
          chunks.add(SourceChunk(
            chunkIndex: chunks.length,
            text: chunkText,
          ));
        }
        start = end;
      }
    }

    for (var i = 0; i < chunks.length; i++) {
      if (chunks[i].chunkIndex != i) {
        chunks[i] = SourceChunk(
          chunkIndex: i,
          pageStart: chunks[i].pageStart,
          pageEnd: chunks[i].pageEnd,
          text: chunks[i].text,
          heading: chunks[i].heading,
        );
      }
    }

    return chunks;
  }

  List<String> _splitBySections(String text) {
    // Lookahead alternatives that mark a section boundary at the position
    // after a newline (or start of string):
    //   • Markdown ATX headers (#..######)
    //   • Markdown Setext headers (text + === / --- on the next line)
    //   • Textbook chapter/section headings (Chapter 1, Section 2.3, Unit I…)
    //   • Multi-level numbered headings (1.1 Title, 2.3.4 Deep Dive)
    final headingPattern = RegExp(
      r'(?:^|\n)(?=#{1,6}\s|.{1,80}\n={3,}|.{1,80}\n-{3,}|(?:Chapter|Section|Unit|Lesson|Appendix)[ \t]+[0-9IVXLCDMivxlcdm]+(?:[.]\d+)*(?:[.:]?[ \t]+)?|[ \t]*[1-9]\d{0,7}(?:[.]\d+){1}[.:]?[ \t]+[^\n])',
      multiLine: true,
      caseSensitive: false,
    );
    final sections = text.split(headingPattern);
    return sections.where((s) => s.trim().isNotEmpty).toList();
  }

  String? _extractLeadingHeading(String text) {
    final lines = text.split('\n').take(3);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('#')) {
        return trimmed.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
      }
      final chapterHeading = _detectChapterHeading(trimmed);
      if (chapterHeading != null) {
        return chapterHeading;
      }
      if (trimmed.isNotEmpty && trimmed.length < 100 && trimmed == trimmed.toUpperCase()) {
        return trimmed;
      }
    }
    return null;
  }

  /// Detects textbook-style chapter/section headings on a single line.
  /// Recognizes:
  /// - "Chapter 1", "Section 2.3", "Unit I", "Lesson 3", "Appendix A"
  /// - "Chapter 1 Introduction", "Section 2.3 The Nervous System"
  /// - Numbered headings: "1.1 Introduction", "2.3.4 Deep Dive" (multi-level)
  static final _chapterHeadingRegex = RegExp(
    r'^(?:Chapter|Section|Unit|Lesson|Appendix)\s+[IVXLCDMivxlcdm\d]+(?:\.\d+)*(?:\.|\s|$)',
    caseSensitive: false,
  );

  static final _numberedHeadingRegex = RegExp(
    r'^[1-9]\d{0,7}(?:\.\d+){1,}\.?\s+\S',
  );

  static String? _detectChapterHeading(String line) {
    if (_chapterHeadingRegex.hasMatch(line)) {
      return line.trim();
    }
    if (_numberedHeadingRegex.hasMatch(line)) {
      return line.trim();
    }
    return null;
  }

  Future<ClassificationResult> classifyChunks({
    required List<SourceChunk> chunks,
    required List<String> possibleTopics,
    required String modelId,
    required String subjectId,
  }) async {
    if (chunks.isEmpty) return ClassificationResult(topicId: '', confidence: 0);
    if (possibleTopics.isEmpty) return ClassificationResult(topicId: '', confidence: 0);

    final votes = <String, int>{};
    final l10n = lookupAppLocalizations(Locale(_localeName));

    for (var i = 0; i < chunks.length; i += _parallelBatchSize) {
      if (_cancelled) break;
      final batchEnd = (i + _parallelBatchSize).clamp(0, chunks.length);
      final batch = chunks.sublist(i, batchEnd);

      final results = await Future.wait(
        batch.map((chunk) => _classifyChunk(
          chunk: chunk,
          possibleTopics: possibleTopics,
          modelId: modelId,
          l10n: l10n,
        )),
      );

      for (final result in results) {
        if (result.isNotEmpty) {
          votes[result] = (votes[result] ?? 0) + 1;
        }
      }

      if (batchEnd < chunks.length) {
        await Future.delayed(_delayBetweenBatches);
      }
    }

    if (votes.isEmpty) return ClassificationResult(topicId: '', confidence: 0);

    final sortedVotes = votes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final winningTopic = sortedVotes.first.key;
    final confidence = sortedVotes.first.value / votes.values.reduce((a, b) => a + b);

    return ClassificationResult(
      topicId: winningTopic,
      confidence: confidence,
    );
  }

  Future<String> _classifyChunk({
    required SourceChunk chunk,
    required List<String> possibleTopics,
    required String modelId,
    required AppLocalizations l10n,
  }) async {
    try {
      final prompt = l10n.classifyUserPrompt(possibleTopics.join(', '), chunk.text);
      final result = await _chatWithRetry(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.classifySystemPrompt,
        feature: _feature,
      );
      if (result.isFailure) {
        _logger.w(
          'Chunk classification exhausted retries for chunk ${chunk.chunkIndex}',
          result.error,
        );
        failedChunkCount++;
        return '';
      }
      return result.data!.trim();
    } catch (e) {
      _logger.w('Chunk classification failed for chunk ${chunk.chunkIndex}', e);
      failedChunkCount++;
      return '';
    }
  }

  Future<Result<String>> generateConsolidatedSummary({
    required List<SourceChunk> chunks,
    required String modelId,
    String? existingTopicTitle,
  }) async {
    try {
      if (chunks.isEmpty) return Result.success('');

      if (chunks.length == 1) {
        final single = await _summarizeChunk(chunks.first, modelId);
        if (single.isEmpty) {
          _logger.w('Failed to summarize single chunk ${chunks.first.chunkIndex}');
          return Result.failure('Failed to summarize chunk');
        }
        return Result.success(single);
      }

      final chunkSummaries = <String>[];
      final l10n = lookupAppLocalizations(Locale(_localeName));

      for (var i = 0; i < chunks.length; i += _parallelBatchSize) {
        if (_cancelled) break;
        final batchEnd = (i + _parallelBatchSize).clamp(0, chunks.length);
        final batch = chunks.sublist(i, batchEnd);

        final results = await Future.wait(
          batch.map((chunk) => _summarizeChunk(chunk, modelId)),
        );

        chunkSummaries.addAll(results.where((s) => s.isNotEmpty));

        if (batchEnd < chunks.length) {
          await Future.delayed(_delayBetweenBatches);
        }
      }

      if (chunkSummaries.isEmpty) {
        _logger.w('Failed to generate consolidated summary: no chunk summaries produced');
        return Result.failure('No chunk summaries produced');
      }

      if (chunkSummaries.length == 1) return Result.success(chunkSummaries.first);

      final consolidatedPrompt = l10n.summarizeUserPrompt(
        chunkSummaries.asMap().entries.map((e) =>
          'Section ${e.key + 1}:\n${e.value}'
        ).join('\n\n'),
      );

      try {
        final result = await _llmService.chat(
          message: consolidatedPrompt,
          modelId: modelId,
          systemPrompt: l10n.summarizeSystemPrompt,
          feature: _feature,
          taskType: _feature,
        );
        if (result.isFailure) {
          _logger.w('Summary consolidation failed: ${result.error}');
          return Result.failure(result.error ?? 'Failed to consolidate summary');
        }
        return Result.success(result.data!.trim());
      } catch (e, stack) {
        _logger.w('Summary consolidation failed', e, stack);
        return Result.failure(e.toString());
      }
    } catch (e, stack) {
      _logger.w('Failed to generate consolidated summary', e, stack);
      return Result.failure(e.toString());
    }
  }

  Future<String> _summarizeChunk(SourceChunk chunk, String modelId) async {
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.summarizeUserPrompt(chunk.text);
      final result = await _chatWithRetry(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.summarizeSystemPrompt,
        feature: _feature,
      );
      if (result.isFailure) {
        _logger.w(
          'Chunk summarization exhausted retries for chunk ${chunk.chunkIndex}',
          result.error,
        );
        failedChunkCount++;
        return '';
      }
      return result.data!.trim();
    } catch (e) {
      _logger.w('Chunk summarization failed for chunk ${chunk.chunkIndex}', e);
      failedChunkCount++;
      return '';
    }
  }

  Future<List<ChunkQuestionResult>> generateQuestionsFromChunks({
    required List<SourceChunk> chunks,
    required String modelId,
    required QuestionParser questionParser,
  }) async {
    final allResults = <ChunkQuestionResult>[];

    for (var i = 0; i < chunks.length; i += _parallelBatchSize) {
      if (_cancelled) break;
      final batchEnd = (i + _parallelBatchSize).clamp(0, chunks.length);
      final batch = chunks.sublist(i, batchEnd);

      final results = await Future.wait(
        batch.map((chunk) => _generateQuestionsForChunk(
          chunk: chunk,
          modelId: modelId,
          questionParser: questionParser,
        )),
      );

      for (final result in results) {
        allResults.addAll(result);
      }

      // Per-source cap (M): once we have enough questions for this source,
      // stop processing remaining chunks — this saves tokens on dense inputs —
      // and clamp to the cap. The overflow is logged for follow-up prep.
      if (allResults.length >= maxQuestionsPerSource) {
        if (allResults.length > maxQuestionsPerSource) {
          _logger.i(
            'Capping question bank for this source to $maxQuestionsPerSource '
            '(generated ${allResults.length}); remaining questions queued '
            'for follow-up prep',
          );
          allResults.removeRange(maxQuestionsPerSource, allResults.length);
        }
        break;
      }

      if (batchEnd < chunks.length) {
        await Future.delayed(_delayBetweenBatches);
      }
    }

    return allResults;
  }

  Future<List<ChunkQuestionResult>> _generateQuestionsForChunk({
    required SourceChunk chunk,
    required String modelId,
    required QuestionParser questionParser,
  }) async {
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.generateQuestionUserPrompt(chunk.text);
      final result = await _chatWithRetry(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.generateQuestionSystemPrompt,
        feature: _feature,
      );
      if (result.isFailure) {
        _logger.w(
          'Chunk question generation exhausted retries for chunk ${chunk.chunkIndex}',
          result.error,
        );
        failedChunkCount++;
        return [];
      }
      final response = result.data!;

      final parsed = questionParser.parse(response);
      // Per-chunk cap (K): clamp a dense page's response so the bank is not
      // flooded in a single call; overflow is logged for follow-up prep.
      final clamped = parsed.take(maxQuestionsPerChunk).toList();
      if (parsed.length > maxQuestionsPerChunk) {
        _logger.i(
          'Clamping ${parsed.length} questions from chunk ${chunk.chunkIndex} '
          'to per-chunk cap of $maxQuestionsPerChunk; overflow queued '
          'for follow-up prep',
        );
      }
      return clamped.map((qData) => ChunkQuestionResult(
        questionData: qData,
        chunkIndex: chunk.chunkIndex,
      )).toList();
    } catch (e) {
      _logger.w('Chunk question generation failed for chunk ${chunk.chunkIndex}', e);
      failedChunkCount++;
      return [];
    }
  }

  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  void reset() {
    _cancelled = false;
    failedChunkCount = 0;
  }

  /// Calls the LLM with exponential-backoff retry for transient failures
  /// (rate limits, timeouts). Returns the original [Result] after exhausting
  /// [_maxRetryAttempts] retries so the caller can decide how to handle a
  /// persistent failure.
  Future<Result<String>> _chatWithRetry({
    required String message,
    required String modelId,
    String? systemPrompt,
    required String feature,
  }) async {
    Result<String> result;
    var attempt = 0;
    var delay = _retryInitialDelay;

    while (true) {
      result = await _llmService.chat(
        message: message,
        modelId: modelId,
        systemPrompt: systemPrompt,
        feature: feature,
        taskType: feature,
      );

      if (result.isSuccess || attempt >= _maxRetryAttempts || _cancelled) {
        break;
      }

      attempt++;
      _logger.w(
        'LLM call failed for feature=$feature, attempt $attempt/$_maxRetryAttempts',
        result.error,
      );
      await Future.delayed(delay);
      delay *= 2;
    }

    return result;
  }
}

class ClassificationResult {
  final String topicId;
  final double confidence;

  ClassificationResult({
    required this.topicId,
    required this.confidence,
  });
}

class ChunkQuestionResult {
  final Map<String, dynamic> questionData;
  final int chunkIndex;

  ChunkQuestionResult({
    required this.questionData,
    required this.chunkIndex,
  });
}

class QuestionParser {
  static final Logger _logger = const Logger('QuestionParser');

  List<Map<String, dynamic>> parse(String response) {
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
}
