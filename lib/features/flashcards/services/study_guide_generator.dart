import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/flashcards/data/models/study_guide_model.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';

class StudyGuideGenerator {
  static final Logger _logger = const Logger('StudyGuideGenerator');
  final LlmService _llmService;
  final StudyGuideRepository _repository;

  StudyGuideGenerator({
    required LlmService llmService,
    required StudyGuideRepository repository,
  })  : _llmService = llmService,
        _repository = repository;

  Future<Result<StudyGuide>> generateStudyGuide({
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
        feature: 'study_guide_generation',
      );

      if (result.isFailure) {
        _logger.w('Study guide generation failed: ${result.error}');
        return Result.failure(result.error!);
      }

      final guideContent = result.data!.trim();
      if (guideContent.isEmpty) {
        return Result.failure('Empty study guide response');
      }

      final guide = StudyGuide(
        id: IdGenerator.generate('sg'),
        sourceId: sourceId,
        topicId: topicId,
        subjectId: subjectId,
        title: 'Study Guide: $topicTitle',
        content: guideContent,
        createdAt: DateTime.now(),
      );

      final saveResult = await _repository.create(guide);
      if (saveResult.isFailure) {
        _logger.w('Failed to save study guide: ${saveResult.error}');
        return Result.failure(saveResult.error!);
      }

      _logger.d('Generated study guide for source $sourceId');
      return Result.success(guide);
    } catch (e) {
      _logger.w('Study guide generation failed', e);
      return Result.failure(e.toString());
    }
  }

  String _buildPrompt(String content, String topicTitle) {
    final truncated =
        content.length > 8000 ? '${content.substring(0, 8000)}\n...[truncated]' : content;

    return 'Create a condensed study guide for the following content on "$topicTitle".\n\n'
        'Content:\n$truncated\n\n'
        'The study guide should include:\n'
        '1. Key Concepts - bullet-point summary of the most important ideas\n'
        '2. Key Formulas/Equations - if applicable, list important formulas\n'
        '3. Key Terms & Definitions - important vocabulary\n'
        '4. Key Dates/Events - if applicable\n'
        '5. Common Mistakes to Avoid\n'
        '6. Quick Practice Questions - 3-5 self-test questions with answers\n\n'
        'Format as clean markdown. Be concise but comprehensive.';
  }

  String _buildSystemPrompt(String localeName) {
    return 'You are an expert educator creating condensed study guides for exam preparation. '
        'Focus on the most testable, high-yield content. '
        'Return well-structured markdown. Respond in $localeName when possible.';
  }
}
