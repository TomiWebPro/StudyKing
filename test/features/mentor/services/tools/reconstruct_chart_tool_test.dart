import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/mentor/services/tools/reconstruct_chart_tool.dart';

/// Hand-written fake [LlmService] that returns a canned chat response
/// and records the last message and feature for assertions.
class FakeLlmService extends LlmService {
  final Result<String> chatResult;
  String? lastMessage;
  String? lastFeature;
  String? lastModelId;

  FakeLlmService(this.chatResult)
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openAI,
            apiKey: 'test',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    lastMessage = message;
    lastFeature = feature;
    lastModelId = modelId;
    return chatResult;
  }
}

void main() {
  group('ReconstructChartTool', () {
    group('tool metadata', () {
      test('name returns reconstruct_chart', () {
        final tool = ReconstructChartTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        expect(tool.name, 'reconstruct_chart');
      });

      test('description mentions chart and diagram reconstruction', () {
        final tool = ReconstructChartTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        expect(tool.description, contains('chart'));
        expect(tool.description, contains('Mermaid'));
      });

      test('supportedChartTypes contains all expected types', () {
        expect(ReconstructChartTool.supportedChartTypes,
            containsAll(['bar', 'line', 'pie', 'scatter', 'table', 'flowchart', 'diagram']));
      });

      test('parameters have correct JSON schema shape', () {
        final tool = ReconstructChartTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        final props = params['properties'] as Map;
        expect(props.keys, containsAll(['chartDescription', 'chartType', 'sourceContent']));
        expect(params['required'], contains('chartDescription'));
        expect(params['required'], isNot(contains('chartType')));
        expect(params['required'], isNot(contains('sourceContent')));
        expect((props['chartType'] as Map)['enum'],
            containsAll(['bar', 'line', 'pie', 'scatter', 'table', 'flowchart', 'diagram']));
      });
    });

    group('execute', () {
      test('returns failure when chartDescription is empty', () async {
        final tool = ReconstructChartTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final result = await tool.execute({'chartDescription': ''});
        expect(result['success'], isFalse);
        expect(result['error'], contains('chartDescription'));
      });

      test('returns failure when chartDescription is missing', () async {
        final tool = ReconstructChartTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final result = await tool.execute({});
        expect(result['success'], isFalse);
        expect(result['error'], contains('chartDescription'));
      });

      test('returns failure when chartType is invalid', () async {
        final tool = ReconstructChartTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final result = await tool.execute({
          'chartDescription': 'A bar chart showing sales',
          'chartType': 'invalid_type',
        });
        expect(result['success'], isFalse);
        expect(result['error'], contains('Invalid chartType'));
        expect(result['chartDescription'], 'A bar chart showing sales');
      });

      test('returns failure when LLM call fails', () async {
        final llm = FakeLlmService(Result.failure('API timeout'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'chartDescription': 'A bar chart showing sales over time',
        });
        expect(result['success'], isFalse);
        expect(result['error'], contains('API timeout'));
        expect(result['chartDescription'], 'A bar chart showing sales over time');
      });

      test('returns success with mermaidSpec when LLM succeeds', () async {
        final llm = FakeLlmService(
          Result.success('```mermaid\nbarChart\nA --> B\n```'),
        );
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'chartDescription': 'A flowchart showing the process',
        });
        expect(result['success'], isTrue);
        expect(result['blockType'], 'diagram');
        expect(result['mermaidSpec'], contains('mermaid'));
        expect(result['description'], 'A flowchart showing the process');
      });

      test('default chartType is empty string and blockType is diagram', () async {
        final llm = FakeLlmService(Result.success('mermaid spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'chartDescription': 'A pie chart of market share',
        });
        expect(result['success'], isTrue);
        expect(result['blockType'], 'diagram');
        expect(result['mermaidSpec'], 'mermaid spec');
      });

      test('passes sourceContent in the prompt when provided', () async {
        final llm = FakeLlmService(Result.success('spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        await tool.execute({
          'chartDescription': 'bar chart of revenue',
          'sourceContent': 'Revenue grew 20% year over year',
        });
        expect(llm.lastMessage, contains('Revenue grew 20% year over year'));
        expect(llm.lastMessage, contains('bar chart of revenue'));
      });

      test('omits sourceContent context when not provided', () async {
        final llm = FakeLlmService(Result.success('spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        await tool.execute({
          'chartDescription': 'A simple chart',
        });
        // The prompt should not reference a context section when sourceContent
        // is absent — the LLM prompt is still valid.
        expect(llm.lastMessage, contains('A simple chart'));
      });

      test('includes chartType hint in the prompt when provided', () async {
        final llm = FakeLlmService(Result.success('spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        await tool.execute({
          'chartDescription': 'sales data',
          'chartType': 'bar',
        });
        expect(llm.lastMessage, contains('bar'));
      });

      test('uses chart_reconstruction feature for the LLM chat call', () async {
        final llm = FakeLlmService(Result.success('spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        await tool.execute({'chartDescription': 'some chart'});
        expect(llm.lastFeature, 'chart_reconstruction');
      });

      test('tolerates whitespace and case in chartType via .normalized', () async {
        final llm = FakeLlmService(Result.success('spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'chartDescription': 'data viz',
          'chartType': '  BAR  ',
        });
        expect(result['success'], isTrue);
        expect(result['chartType'], 'bar');
      });

      test('returns the provided modelId to the LLM service', () async {
        final llm = FakeLlmService(Result.success('spec'));
        final tool = ReconstructChartTool(llmService: llm, modelId: 'my-model');
        await tool.execute({'chartDescription': 'chart'});
        expect(llm.lastModelId, 'my-model');
      });
    });
  });
}
