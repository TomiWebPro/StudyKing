import 'dart:convert';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/flashcards/data/models/concept_map_model.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';

class ConceptMapGenerator {
  static final Logger _logger = const Logger('ConceptMapGenerator');
  final LlmService _llmService;
  final ConceptMapRepository _repository;

  ConceptMapGenerator({
    required LlmService llmService,
    required ConceptMapRepository repository,
  })  : _llmService = llmService,
        _repository = repository;

  Future<Result<ConceptMap>> generateConceptMap({
    required String content,
    required String sourceId,
    required String topicId,
    required String subjectId,
    required String topicTitle,
    required String modelId,
    String localeName = 'en',
  }) async {
    try {
      final prompt = _buildPrompt(content, topicTitle);
      final systemPrompt = _buildSystemPrompt(localeName);

      final result = await _llmService.chat(
        message: prompt,
        modelId: modelId,
        systemPrompt: systemPrompt,
        feature: 'concept_map_generation',
      );

      if (result.isFailure) {
        _logger.w('Concept map generation failed: ${result.error}');
        return Result.failure(result.error!);
      }

      final parsed = _parseConceptMap(
        result.data!,
        sourceId: sourceId,
        topicId: topicId,
        subjectId: subjectId,
        title: topicTitle,
      );

      if (parsed == null) {
        return Result.failure('Failed to parse concept map response');
      }

      final saveResult = await _repository.create(parsed);
      if (saveResult.isFailure) {
        _logger.w('Failed to save concept map: ${saveResult.error}');
        return Result.failure(saveResult.error!);
      }

      _logger.d('Generated concept map with ${parsed.nodes.length} nodes and ${parsed.edges.length} edges');
      return Result.success(parsed);
    } catch (e) {
      _logger.w('Concept map generation failed', e);
      return Result.failure(e.toString());
    }
  }

  ConceptMap? _parseConceptMap(
    String response, {
    required String sourceId,
    required String topicId,
    required String subjectId,
    required String title,
  }) {
    try {
      final cleaned = response
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();

      final decoded = jsonDecode(cleaned);
      final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

      final nodesList = map['nodes'] as List<dynamic>? ?? [];
      final edgesList = map['edges'] as List<dynamic>? ?? [];

      final nodes = nodesList.map((item) {
        final m = item as Map<String, dynamic>;
        return ConceptNode(
          id: m['id'] as String? ?? IdGenerator.generate('cn'),
          label: m['label'] as String? ?? '',
          description: m['description'] as String?,
        );
      }).toList();

      final edges = edgesList.map((item) {
        final m = item as Map<String, dynamic>;
        return ConceptEdge(
          fromId: m['fromId'] as String? ?? '',
          toId: m['toId'] as String? ?? '',
          relationship: m['relationship'] as String? ?? '',
        );
      }).toList();

      if (nodes.isEmpty) return null;

      return ConceptMap(
        id: IdGenerator.generate('cm'),
        sourceId: sourceId,
        topicId: topicId,
        subjectId: subjectId,
        title: 'Concept Map: $title',
        nodes: nodes,
        edges: edges,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      _logger.w('Failed to parse concept map response', e);
      return null;
    }
  }

  String _buildPrompt(String content, String topicTitle) {
    final truncated =
        content.length > 8000 ? '${content.substring(0, 8000)}\n...[truncated]' : content;

    return 'Extract a concept map from the following educational content on "$topicTitle".\n\n'
        'Content:\n$truncated\n\n'
        'Return a JSON object with:\n'
        '- "nodes": array of concepts, each with "id" (string), "label" (short name), '
        'and optional "description" (1-sentence explanation)\n'
        '- "edges": array of relationships, each with "fromId", "toId", '
        'and "relationship" (a short phrase describing how they connect)\n\n'
        'Guidelines:\n'
        '- Include 5-15 key concepts\n'
        '- Show prerequisite, causal, and compositional relationships\n'
        '- Use clear, concise labels\n'
        '- Return ONLY the JSON, no explanation';
  }

  String _buildSystemPrompt(String localeName) {
    return 'You are an expert at extracting knowledge structures from educational content. '
        'Create clear, accurate concept maps that show how ideas relate. '
        'Return valid JSON only. Respond in $localeName when possible.';
  }
}
