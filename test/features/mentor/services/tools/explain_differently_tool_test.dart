import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/mentor/services/tools/explain_differently_tool.dart';

/// Hand-written fake [LlmService] that returns a canned chat response.
class FakeLlmService extends LlmService {
  final Result<String> chatResult;
  String? lastMessage;
  String? lastFeature;

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
    return chatResult;
  }
}

void main() {
  group('ExplainDifferentlyTool', () {
    group('tool metadata', () {
      test('name returns explain_differently', () {
        final tool = ExplainDifferentlyTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        expect(tool.name, 'explain_differently');
      });

      test('description mentions explanation variation', () {
        final tool = ExplainDifferentlyTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        expect(tool.description, contains('different'));
        expect(tool.description, contains('explanation'));
      });

      test('validStyles contains visual, analogy, and step_by_step', () {
        expect(ExplainDifferentlyTool.validStyles,
            containsAll(['visual', 'analogy', 'step_by_step']));
      });

      test('parameters have correct JSON schema shape', () {
        final tool = ExplainDifferentlyTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final params = tool.parameters;
        expect(params['type'], 'object');
        final props = params['properties'] as Map;
        expect(props.keys, containsAll(['concept', 'currentExplanation', 'style']));
        expect(params['required'], contains('concept'));
        expect(params['required'], isNot(contains('currentExplanation')));
        expect(params['required'], isNot(contains('style')));
        expect((props['style'] as Map)['enum'],
            containsAll(['visual', 'analogy', 'step_by_step']));
      });
    });

    group('execute', () {
      test('returns failure when concept is empty', () async {
        final tool = ExplainDifferentlyTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final result = await tool.execute({'concept': ''});
        expect(result['success'], isFalse);
        expect(result['error'], contains('concept'));
      });

      test('returns failure when concept is missing', () async {
        final tool = ExplainDifferentlyTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final result = await tool.execute({});
        expect(result['success'], isFalse);
        expect(result['error'], contains('concept'));
      });

      test('returns failure when style is invalid', () async {
        final tool = ExplainDifferentlyTool(
          llmService: FakeLlmService(Result.success('test')),
          modelId: 'test',
        );
        final result = await tool.execute({
          'concept': 'fractions',
          'style': 'invalid_style',
        });
        expect(result['success'], isFalse);
        expect(result['error'], contains('Invalid style'));
      });

      test('returns failure when LLM call fails', () async {
        final llm = FakeLlmService(Result.failure('API timeout'));
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({'concept': 'fractions'});
        expect(result['success'], isFalse);
        expect(result['error'], contains('API timeout'));
        expect(result['concept'], 'fractions');
      });

      test('default style is step_by_step and maps to text block type',
          () async {
        final llm = FakeLlmService(
          Result.success('Step 1: Understand what a fraction is...'),
        );
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({'concept': 'fractions'});
        expect(result['success'], isTrue);
        expect(result['style'], 'step_by_step');
        expect(result['blockType'], 'text');
        expect(result['explanation'], contains('Step 1'));
      });

      test('visual style maps to LessonBlockType.visual', () async {
        final llm = FakeLlmService(
          Result.success('Imagine a pie chart divided into 4 equal slices...'),
        );
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'concept': 'fractions',
          'style': 'visual',
        });
        expect(result['success'], isTrue);
        expect(result['style'], 'visual');
        expect(result['blockType'], LessonBlockType.visual.name);
        expect(result['explanation'], contains('pie chart'));
      });

      test('analogy style maps to LessonBlockType.analogy', () async {
        final llm = FakeLlmService(
          Result.success('Think of fractions like pizza slices...'),
        );
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'concept': 'fractions',
          'style': 'analogy',
        });
        expect(result['success'], isTrue);
        expect(result['style'], 'analogy');
        expect(result['blockType'], LessonBlockType.analogy.name);
        expect(result['explanation'], contains('pizza'));
      });

      test('tolerates whitespace and case in style via .normalized', () async {
        final llm = FakeLlmService(
          Result.success('Picture a pie chart...'),
        );
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({
          'concept': 'fractions',
          'style': '  VISUAL  ',
        });
        expect(result['success'], isTrue);
        expect(result['style'], 'visual');
      });

      test('passes currentExplanation in the prompt to avoid repetition',
          () async {
        final llm = FakeLlmService(Result.success('New explanation'));
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        await tool.execute({
          'concept': 'fractions',
          'currentExplanation': 'Old explanation that did not work',
        });
        expect(llm.lastMessage, contains('Old explanation that did not work'));
        expect(llm.lastMessage, contains('Do NOT repeat'));
      });

      test('uses teaching_explanation feature for the LLM chat call', () async {
        final llm = FakeLlmService(Result.success('New explanation'));
        final tool = ExplainDifferentlyTool(llmService: llm, modelId: 'test');
        await tool.execute({'concept': 'fractions'});
        expect(llm.lastFeature, 'teaching_explanation');
      });
    });
  });
}
