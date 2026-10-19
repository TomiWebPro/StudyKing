import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Agent tool that generates a genuinely different explanation for a concept
/// when a student says "I don't get this, explain differently."
///
/// Vision Next-Term §3.1 (`scenario_confused_student_fractions` Step 2):
/// > "The tutor should vary the explanation style: visual/pie-chart, real-world
/// > analogy (pizza slices), step-by-step breakdown."
///
/// This is an LLM-backed tool (like [IngestPdfToKbTool]): it calls
/// [LlmService.chat] with a prompt that directs the model to produce a
/// different modality. The returned [LessonBlockType] hint (`visual`,
/// `analogy`, or `text` for step-by-step) lets the caller store the
/// alternative explanation with the correct block type.
///
/// The available styles map to the [LessonBlockType] variants added for this
/// issue: `visual`, `analogy`. Step-by-step keeps `LessonBlockType.text`
/// (it is text broken into micro-steps).
class ExplainDifferentlyTool extends AgentTool {
  static final Logger _logger = const Logger('ExplainDifferentlyTool');

  final LlmService _llmService;
  final String _modelId;

  ExplainDifferentlyTool({
    required LlmService llmService,
    required String modelId,
  })  : _llmService = llmService,
        _modelId = modelId;

  /// The explanation modalities the tool can request.
  static const List<String> validStyles = ['visual', 'analogy', 'step_by_step'];

  @override
  String get name => 'explain_differently';

  @override
  String get description =>
      'Generate an alternative explanation for a concept in a different '
      'style. Use this when a student says "I do not get this" or '
      '"explain differently." Available styles: visual (diagrams, pie-charts, '
      'color-coded descriptions), analogy (real-world metaphor), or '
      'step_by_step (broken into small sequential steps). Never repeats the '
      'current explanation — each style produces a genuinely different '
      'approach. Returns the new explanation text and a suggested '
      'LessonBlockType for storage.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'concept': {
            'type': 'string',
            'description':
                'The concept the student is struggling with '
                '(e.g. "fractions", "photosynthesis"). Required.',
          },
          'currentExplanation': {
            'type': 'string',
            'description':
                'The explanation the student did not understand. Provide '
                'this so the tool generates a genuinely different approach '
                'rather than repeating the same content.',
          },
          'style': {
            'type': 'string',
            'description':
                'Desired explanation style: "visual", "analogy", or '
                '"step_by_step". If omitted, defaults to step_by_step.',
            'enum': validStyles,
            'default': 'step_by_step',
          },
        },
        'required': ['concept'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final concept = args['concept']?.toString() ?? '';
    if (concept.isEmpty) {
      _logger.w('explain_differently received empty concept');
      return {
        'success': false,
        'error': 'concept is required and must not be empty',
      };
    }

    final currentExplanation = args['currentExplanation']?.toString();
    final styleRaw = args['style']?.toString() ?? 'step_by_step';
    final style = styleRaw.normalized;

    if (!validStyles.contains(style)) {
      _logger.w('explain_differently received invalid style: $style');
      return {
        'success': false,
        'error': 'Invalid style: "$style". Must be one of: $validStyles',
        'concept': concept,
      };
    }

    final result = await _generateAlternativeExplanation(
      concept,
      currentExplanation,
      style,
    );

    if (result.isFailure) {
      _logger.w('explain_differently LLM call failed: ${result.error}');
      return {
        'success': false,
        'error': result.error ?? 'LLM call failed',
        'concept': concept,
        'style': style,
      };
    }

    final explanation = result.data ?? '';
    final blockType = _styleToBlockType(style);

    return {
      'success': true,
      'concept': concept,
      'style': style,
      'blockType': blockType.name,
      'explanation': explanation,
    };
  }

  /// Maps a style string to the corresponding [LessonBlockType].
  LessonBlockType _styleToBlockType(String style) {
    switch (style) {
      case 'visual':
        return LessonBlockType.visual;
      case 'analogy':
        return LessonBlockType.analogy;
      case 'step_by_step':
      default:
        return LessonBlockType.text;
    }
  }

  Future<Result<String>> _generateAlternativeExplanation(
    String concept,
    String? currentExplanation,
    String style,
  ) async {
    final prompt = StringBuffer();
    prompt.writeln(
      'A student is struggling with "$concept" and asked for a different '
      'explanation.',
    );

    if (currentExplanation != null && currentExplanation.isNotEmpty) {
      prompt.writeln('The explanation they did not understand was:');
      prompt.writeln('"$currentExplanation"');
      prompt.writeln('Do NOT repeat or paraphrase this. Generate a genuinely '
          'different approach.');
    } else {
      prompt.writeln('Generate a fresh, alternative explanation.');
    }

    switch (style) {
      case 'visual':
        prompt.writeln('Explain using a visual description: describe pie-charts, '
            'diagrams, color-coding, and spatial relationships the student can '
            'visualize in their mind.');
        break;
      case 'analogy':
        prompt.writeln('Explain using a real-world analogy: relate the concept '
            'to familiar objects, stories, or everyday experiences.');
        break;
      case 'step_by_step':
        prompt.writeln('Break the concept into small, sequential micro-steps. '
            'Do not skip any intermediate reasoning.');
        break;
    }

    prompt.writeln('Respond with ONLY the new explanation text. '
        'No meta-commentary, no headings.');

    final llmResult = await _llmService.chat(
      message: prompt.toString(),
      modelId: _modelId,
      localeName: 'en',
      feature: 'teaching_explanation',
    );

    if (llmResult.isFailure) {
      return Result.failure(llmResult.error ?? 'LLM call failed');
    }
    return Result.success(llmResult.data ?? '');
  }
}
