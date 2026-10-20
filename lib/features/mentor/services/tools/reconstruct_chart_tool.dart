import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Agent tool that reconstructs a textual description of a chart / diagram
/// into a renderable spec (Mermaid / Markdown) so the mentor agent can surface
/// visual content in lessons even when the original image bytes are unavailable.
///
/// Vision Next-Term §24 + agent_must_read.md §24 (rich rendering for
/// mathematical and scientific content, including graphs and charts). When a
/// source figure is encountered the agent can call this tool to produce a
/// Mermaid block that the lesson renderer can display inline.
///
/// This is an LLM-backed tool (like [ExplainDifferentlyTool]): it calls
/// [LlmService.chat] with a prompt directing the model to emit only a Mermaid
/// specification. The result includes a [blockTypeHint] of `"diagram"` so the
/// caller knows the content is a rendered spec rather than prose.
class ReconstructChartTool extends AgentTool {
  static final Logger _logger = const Logger('ReconstructChartTool');

  final LlmService _llmService;
  final String _modelId;

  ReconstructChartTool({
    required LlmService llmService,
    required String modelId,
  })  : _llmService = llmService,
        _modelId = modelId;

  /// Chart categories the LLM is guided to produce.
  static const List<String> supportedChartTypes = [
    'bar',
    'line',
    'pie',
    'scatter',
    'table',
    'flowchart',
    'diagram',
  ];

  @override
  String get name => 'reconstruct_chart';

  @override
  String get description =>
      'Reconstruct a described chart, graph, or diagram into a renderable '
      'Mermaid or Markdown specification. Use this when the student or a '
      'lesson needs a visual representation of data that was originally an '
      'image (e.g. "a bar chart showing sales over 5 years" or "a flowchart of '
      'the scientific method"). Provide a detailed description of what the '
      'chart shows; the tool will return a Mermaid spec that can be rendered '
      'as a diagram. Returns the rendered spec text and a block type hint of '
      '"diagram".';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'chartDescription': {
            'type': 'string',
            'description':
                'A detailed description of the chart, graph, or diagram to '
                'reconstruct. Include axes, data points, categories, trends, '
                'and any labels or headings. Required.',
          },
          'chartType': {
            'type': 'string',
            'description':
                'Hint for the chart type: "bar", "line", "pie", "scatter", '
                '"table", "flowchart", or "diagram". If omitted, the tool '
                'infers the best type from the description.',
            'enum': supportedChartTypes,
          },
          'sourceContent': {
            'type': 'string',
            'description':
                'Optional surrounding context from the source material so the '
                'reconstruction is grounded in the real data.',
          },
        },
        'required': ['chartDescription'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final description = args['chartDescription']?.toString() ?? '';
    if (description.isEmpty) {
      _logger.w('reconstruct_chart received empty chartDescription');
      return {
        'success': false,
        'error': 'chartDescription is required and must not be empty',
      };
    }

    final chartTypeRaw = args['chartType']?.toString() ?? '';
    final chartType = chartTypeRaw.normalized;
    if (chartType.isNotEmpty && !supportedChartTypes.contains(chartType)) {
      _logger.w('reconstruct_chart received invalid chartType: $chartType');
      return {
        'success': false,
        'error': 'Invalid chartType: "$chartType". '
            'Must be one of: $supportedChartTypes',
        'chartDescription': description,
      };
    }

    final sourceContent = args['sourceContent']?.toString() ?? '';

    final result = await _generateChartSpec(
      description,
      chartType,
      sourceContent,
    );

    if (result.isFailure) {
      _logger.w('reconstruct_chart LLM call failed: ${result.error}');
      return {
        'success': false,
        'error': result.error ?? 'LLM call failed',
        'chartDescription': description,
        'chartType': chartType,
      };
    }

    final spec = result.data ?? '';

    return {
      'success': true,
      'chartType': chartType,
      'blockType': 'diagram',
      'mermaidSpec': spec,
      'description': description,
    };
  }

  /// Calls the LLM to produce a Mermaid / Markdown spec for the described chart.
  Future<Result<String>> _generateChartSpec(
    String description,
    String chartType,
    String sourceContent,
  ) async {
    final prompt = StringBuffer();
    prompt.writeln(
      'Reconstruct the following described chart, graph, or diagram into a '
      'renderable specification.',
    );

    if (sourceContent.isNotEmpty) {
      prompt.writeln('Context from the source material:');
      prompt.writeln(sourceContent);
      prompt.writeln();
    }

    prompt.writeln('Chart description:');
    prompt.writeln('"$description"');
    prompt.writeln();

    if (chartType.isNotEmpty) {
      prompt.writeln('Prefer the "$chartType" chart type.');
    } else {
      prompt.writeln('Infer the most appropriate chart type from the description.');
    }

    prompt.writeln(
      'Respond with ONLY a Mermaid diagram specification (e.g. '
      '```mermaid\\nflowchart TD\\nA --> B\\n```, '
      '```mermaid\\nbarChart\\n```, or a markdown table if appropriate). '
      'Do NOT include any explanation, headings, or prose outside the code block. '
      'The output must be directly renderable.',
    );

    final llmResult = await _llmService.chat(
      message: prompt.toString(),
      modelId: _modelId,
      localeName: 'en',
      feature: 'chart_reconstruction',
    );

    if (llmResult.isFailure) {
      return Result.failure(llmResult.error ?? 'LLM call failed');
    }
    return Result.success(llmResult.data ?? '');
  }
}
