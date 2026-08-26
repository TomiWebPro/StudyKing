import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/ingestion/data/models/source_chunk.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ChunkedContentProcessor {
  final LlmService _llmService;
  final String _localeName;
  static final Logger _logger = const Logger('ChunkedContentProcessor');

  static const int _maxCharsPerChunk = 3000;
  static const int _parallelBatchSize = 3;
  static const Duration _delayBetweenBatches = Duration(milliseconds: 500);

  ChunkedContentProcessor({
    required LlmService llmService,
    required String localeName,
  })  : _llmService = llmService,
        _localeName = localeName;

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
    final headingPattern = RegExp(
      r'(?:^|\n)(?=#{1,6}\s|.{1,80}\n={3,}|.{1,80}\n-{3,})',
      multiLine: true,
    );
    final sections = text.split(headingPattern);
    return sections.where((s) => s.trim().isNotEmpty).toList();
  }

  String? _extractLeadingHeading(String text) {
    final lines = text.split('\n').take(3);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        return trimmed.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
      }
      if (trimmed.isNotEmpty && trimmed.length < 100 && trimmed == trimmed.toUpperCase()) {
        return trimmed;
      }
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
      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.classifySystemPrompt,
        feature: 'content_classification',
      );
      if (result.isFailure) return '';
      return result.data!.trim();
    } catch (e) {
      _logger.w('Chunk classification failed for chunk ${chunk.chunkIndex}', e);
      return '';
    }
  }

  Future<String> generateConsolidatedSummary({
    required List<SourceChunk> chunks,
    required String modelId,
    String? existingTopicTitle,
  }) async {
    if (chunks.isEmpty) return '';

    if (chunks.length == 1) {
      return _summarizeChunk(chunks.first, modelId);
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

    if (chunkSummaries.isEmpty) return '';

    if (chunkSummaries.length == 1) return chunkSummaries.first;

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
        feature: 'content_summarization',
      );
      if (result.isFailure) return chunkSummaries.join('\n\n');
      return result.data!.trim();
    } catch (e) {
      _logger.w('Summary consolidation failed, using concatenated chunk summaries', e);
      return chunkSummaries.join('\n\n');
    }
  }

  Future<String> _summarizeChunk(SourceChunk chunk, String modelId) async {
    try {
      final l10n = lookupAppLocalizations(Locale(_localeName));
      final prompt = l10n.summarizeUserPrompt(chunk.text);
      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.summarizeSystemPrompt,
        feature: 'content_summarization',
      );
      if (result.isFailure) return '';
      return result.data!.trim();
    } catch (e) {
      _logger.w('Chunk summarization failed for chunk ${chunk.chunkIndex}', e);
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
      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: l10n.generateQuestionSystemPrompt,
        feature: 'question_generation',
      );
      if (result.isFailure) return [];
      final response = result.data!;

      final parsed = questionParser.parse(response);
      return parsed.map((qData) => ChunkQuestionResult(
        questionData: qData,
        chunkIndex: chunk.chunkIndex,
      )).toList();
    } catch (e) {
      _logger.w('Chunk question generation failed for chunk ${chunk.chunkIndex}', e);
      return [];
    }
  }

  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  void reset() {
    _cancelled = false;
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
