import 'dart:convert';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';

class FlashcardGenerator {
  static final Logger _logger = const Logger('FlashcardGenerator');
  final LlmService _llmService;
  final FlashcardRepository _flashcardRepository;

  FlashcardGenerator({
    required LlmService llmService,
    required FlashcardRepository flashcardRepository,
  })  : _llmService = llmService,
        _flashcardRepository = flashcardRepository;

  Future<Result<List<Flashcard>>> generateFlashcards({
    required String content,
    required String sourceId,
    required String topicId,
    required String subjectId,
    required String modelId,
    String localeName = 'en',
    int maxCards = 20,
  }) async {
    try {
      final prompt = _buildFlashcardPrompt(content, maxCards);
      final systemPrompt = _buildSystemPrompt(localeName);

      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: systemPrompt,
        feature: 'flashcard_generation',
      );

      if (result.isFailure) {
        _logger.w('Flashcard generation LLM call failed: ${result.error}');
        return Result.failure(result.error!);
      }

      final flashcards = _parseFlashcards(
        result.data!,
        sourceId: sourceId,
        topicId: topicId,
        subjectId: subjectId,
      );

      if (flashcards.isEmpty) {
        return Result.failure('No valid flashcards could be generated');
      }

      final savedIds = <String>[];
      for (final card in flashcards) {
        final saveResult = await _flashcardRepository.create(card);
        if (saveResult.isSuccess) {
          savedIds.add(card.id);
        }
      }

      _logger.d('Generated ${savedIds.length} flashcards for source $sourceId');
      return Result.success(flashcards);
    } catch (e) {
      _logger.w('Flashcard generation failed', e);
      return Result.failure(e.toString());
    }
  }

  List<Flashcard> _parseFlashcards(
    String response, {
    required String sourceId,
    required String topicId,
    required String subjectId,
  }) {
    try {
      final cleaned = response
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();

      final decoded = jsonDecode(cleaned);

      List<dynamic> flashcardsList;
      if (decoded is List) {
        flashcardsList = decoded;
      } else if (decoded is Map && decoded.containsKey('flashcards')) {
        flashcardsList = decoded['flashcards'] as List;
      } else {
        _logger.w('Unexpected flashcard response structure');
        return [];
      }

      final now = DateTime.now();
      final flashcards = <Flashcard>[];

      for (final item in flashcardsList) {
        try {
          final map = item as Map<String, dynamic>;
          final front = map['front'] as String? ?? '';
          final back = map['back'] as String? ?? '';

          if (front.isEmpty || back.isEmpty) continue;

          final tags = (map['tags'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              [];

          flashcards.add(Flashcard(
            id: IdGenerator.generate('fc'),
            sourceId: sourceId,
            topicId: topicId,
            subjectId: subjectId,
            front: front,
            back: back,
            tags: tags,
            createdAt: now,
            updatedAt: now,
          ));
        } catch (e) {
          _logger.w('Skipping malformed flashcard item: $item', e);
        }
      }

      return flashcards;
    } catch (e) {
      _logger.w('Failed to parse flashcard response', e);
      return [];
    }
  }

  String _buildFlashcardPrompt(String content, int maxCards) {
    final truncated =
        content.length > 8000 ? '${content.substring(0, 8000)}\n...[truncated]' : content;

    return 'Generate flashcard pairs from the following educational content.\n\n'
        'Content:\n$truncated\n\n'
        'Create up to $maxCards flashcards as a JSON array. Each flashcard must have:\n'
        '- "front": a concise term, question, or concept to recall\n'
        '- "back": a clear, complete definition or answer\n'
        '- "tags": an array of relevant topic tags\n\n'
        'Guidelines:\n'
        '- Focus on key terms, definitions, formulas, and core concepts\n'
        '- Keep the front side concise (one phrase or question)\n'
        '- Keep the back side informative but brief (1-3 sentences)\n'
        '- Each flashcard should test one specific concept\n'
        '- Avoid trivially easy or overly complex cards\n'
        '- Return ONLY the JSON array, no explanation';
  }

  String _buildSystemPrompt(String localeName) {
    return 'You are an expert educator creating flashcards for active recall study. '
        'Generate clear, accurate, and pedagogically effective flashcard pairs. '
        'Return valid JSON only. Respond in $localeName when possible.';
  }
}
