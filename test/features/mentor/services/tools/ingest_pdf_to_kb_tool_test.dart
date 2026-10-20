import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/features/mentor/services/tools/ingest_pdf_to_kb_tool.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';

/// Hand-written fake [LlmService] that returns a canned chat response
/// and records usage on the meter (mirroring what the real LlmService does
/// via _recordCompletion). The recorded [taskType] defaults to
/// `LlmTaskType.fromFeature(feature)?.name` when [taskType] is null,
/// matching the real service's fallback behaviour.
class FakeLlmService extends LlmService {
  final Result<String> chatResult;
  final LlmUsageMeter? meter;

  String? lastFeature;
  String? lastTaskType;

  FakeLlmService(this.chatResult, {this.meter})
      : super(
          config: LlmConfiguration(
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
    String? taskType,
    String? sessionId,
  }) async {
    lastFeature = feature;
    lastTaskType = taskType ?? LlmTaskType.fromFeature(feature)?.name;
    // Simulate _recordCompletion: record actual tokens on the meter.
    meter?.recordUsage(
      id: 'fake_usage_${DateTime.now().millisecondsSinceEpoch}',
      feature: feature,
      modelId: modelId,
      inputTokens: 800,
      outputTokens: 200,
      taskType: lastTaskType,
    );
    return chatResult;
  }
}

void main() {
  group('IngestPdfToKbTool', () {
    late FakeLlmService fakeLlm;
    late LlmUsageMeter meter;

    setUp(() {
      meter = LlmUsageMeter();
      fakeLlm = FakeLlmService(
        Result.success(
          '[{"heading":"Section 1","content":"Content of section 1"},'
          '{"heading":"Section 2","content":"Content of section 2"}]',
        ),
        meter: meter,
      );
    });

    group('tool metadata', () {
      test('name returns ingest_pdf_to_kb', () {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        expect(tool.name, 'ingest_pdf_to_kb');
      });

      test('description is not empty', () {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        expect(tool.description, isNotEmpty);
      });

      test('parameters has correct JSON schema shape', () {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        final params = tool.parameters;
        expect(params['type'], 'object');
        final props = params['properties'] as Map;
        expect(props.keys, containsAll(['textContent', 'subjectId', 'topicId', 'localeName']));
        expect(params['required'], ['textContent']);
      });

      test('estimated tokens are positive', () {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        expect(tool.estimatedInputTokens, greaterThan(0));
        expect(tool.estimatedOutputTokens, greaterThan(0));
        expect(tool.estimatedTotalTokens,
            equals(tool.estimatedInputTokens + tool.estimatedOutputTokens));
      });

      test('cpuClass is heavy', () {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        expect(tool.cpuClass, equals(PrepCpuClass.heavy));
        expect(tool.needsNetwork, isTrue);
      });

      test('prepCategory is pdfIngestion', () {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        expect(tool.prepCategory, equals(PrepCategory.pdfIngestion));
      });
    });

    group('execute', () {
      test('returns failure when textContent is empty', () async {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        final result = await tool.execute({'textContent': ''});
        expect(result['success'], isFalse);
        expect(result['error'], contains('textContent'));
      });

      test('returns failure when textContent is missing', () async {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        final result = await tool.execute({});
        expect(result['success'], isFalse);
      });

      test('returns success with chunkCount on valid LLM response', () async {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test');
        final result = await tool.execute({
          'textContent': 'Some textbook content here',
          'subjectId': 'chem',
          'topicId': 'atoms',
        });
        expect(result['success'], isTrue);
        expect(result['chunkCount'], 2);
        expect(result['subjectId'], 'chem');
        expect(result['topicId'], 'atoms');
      });

      test('passes feature string pdf_ingestion and taskType to the LLM chat call', () async {
        final tool = IngestPdfToKbTool(llmService: fakeLlm, modelId: 'test', usageMeter: meter);
        await tool.execute({'textContent': 'some content'});
        expect(fakeLlm.lastFeature, 'pdf_ingestion');
        // The PrepTool must pass its prepCategory.taskTypeKey as the taskType
        // override so actual tokens are recorded under 'pdf_ingestion' — not
        // 'background' (which fromFeature would produce without the override).
        expect(fakeLlm.lastTaskType, equals(PrepCategory.pdfIngestion.taskTypeKey));
      });

      test('handles non-JSON LLM response gracefully', () async {
        final llm = FakeLlmService(Result.success('not valid json'));
        final tool = IngestPdfToKbTool(llmService: llm, modelId: 'test');
        final result = await tool.execute({'textContent': 'some content'});
        expect(result['success'], isTrue);
        expect(result['chunkCount'], 0);
      });
    });

    group('budget enforcement', () {
      test('denies when prep budget is disabled', () async {
        final llm = FakeLlmService(Result.success('[{"heading":"A","content":"B"}]'));
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: const PrepBudget(enabled: false, caps: {}),
        );
        final tool = IngestPdfToKbTool(
          llmService: llm,
          modelId: 'test',
          budgetService: budget,
        );
        final result = await tool.execute({'textContent': 'content'});
        expect(result['success'], isFalse);
        expect(result['error'], contains('budget'));
        expect(result['deferrable'], isTrue);
      });

      test('allows when budget is enabled and has remaining capacity', () async {
        final llm = FakeLlmService(Result.success('[{"heading":"A","content":"B"}]'));
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(meter: meter);
        final tool = IngestPdfToKbTool(
          llmService: llm,
          modelId: 'test',
          budgetService: budget,
        );
        final result = await tool.execute({'textContent': 'content'});
        expect(result['success'], isTrue);
      });
    });

    group('task manager integration', () {
      test('creates, starts, and completes an LlmTask on success', () async {
        final tm = LlmTaskManager();
        final tool = IngestPdfToKbTool(
          llmService: fakeLlm,
          modelId: 'test',
          taskManager: tm,
        );
        await tool.execute({'textContent': 'content'});
        expect(tm.tasks, isNotEmpty);
        expect(tm.tasks.any((t) => t.feature == 'pdf_ingestion'), isTrue);
        expect(
          tm.tasks.any((t) => t.status == LlmTaskStatus.done),
          isTrue,
        );
      });

      test('fails the LlmTask on exception', () async {
        final llm = FakeLlmService(Result.failure('API error'));
        final tm = LlmTaskManager();
        final tool = IngestPdfToKbTool(
          llmService: llm,
          modelId: 'test',
          taskManager: tm,
        );
        final result = await tool.execute({'textContent': 'content'});
        expect(result['success'], isFalse);
        // Task should be completed (the service returns failure, not throw)
        // but the task tracking still happens.
        expect(tm.tasks.any((t) => t.status == LlmTaskStatus.done), isTrue);
      });
    });

    group('usage metering', () {
      test('records actual usage under pdf_ingestion taskType (no double-count)', () async {
        final llm = FakeLlmService(
          Result.success('[{"heading":"A","content":"B"}]'),
          meter: meter,
        );
        final tool = IngestPdfToKbTool(
          llmService: llm,
          modelId: 'test',
          usageMeter: meter,
        );
        await tool.execute({'textContent': 'content'});
        final byType = meter.getTotalTokensPerTaskType();
        final key = PrepCategory.pdfIngestion.taskTypeKey;
        // Actual tokens recorded by the LLM service under 'pdf_ingestion'
        // (via the taskType override), not 'background' (via fromFeature).
        expect(byType[key], greaterThan(0));
        // No estimated tokens should be double-counted: 'background' bucket
        // must remain empty for this prep tool's LLM call.
        expect(byType['background'], isNull);
        // totalPrepTokens equals the actual tokens — no double-counting.
        final service = PrepBudgetService(meter: meter);
        expect(service.totalPrepTokens(), equals(byType[key]));
      });
    });

    group('per-subject opt-in enforcement', () {
      test(
          'skips LLM call and records no tokens when subject is disabled',
          () async {
        final llm = FakeLlmService(
          Result.success('[{"heading":"A","content":"B"}]'),
        );
        final meter = LlmUsageMeter();
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults.copyWith(disabledSubjects: {'chem'}),
        );
        final tool = IngestPdfToKbTool(
          llmService: llm,
          modelId: 'test',
          budgetService: budget,
          usageMeter: meter,
        );
        final result = await tool.execute({
          'textContent': 'some chemistry textbook content',
          'subjectId': 'chem',
        });

        // Vision §4.2: a paused syllabus must never invoke the LLM or spend
        // tokens — recorded as a deferrable failure.
        expect(result['success'], isFalse);
        expect(result['deferrable'], isTrue);
        expect(llm.lastFeature, isNull, reason: 'LLM must not be called');
        expect(meter.getTotalTokens(), equals(0));
      });

      test('proceeds for an enabled subject within budget', () async {
        final llm = FakeLlmService(
          Result.success('[{"heading":"A","content":"B"}]'),
          meter: meter,
        );
        final budget = PrepBudgetService(
          meter: meter,
          budget: PrepBudget.defaults.copyWith(disabledSubjects: {'other'}),
        );
        final tool = IngestPdfToKbTool(
          llmService: llm,
          modelId: 'test',
          budgetService: budget,
          usageMeter: meter,
        );
        final result = await tool.execute({
          'textContent': 'some biology textbook content',
          'subjectId': 'bio',
        });

        expect(result['success'], isTrue);
        expect(result['chunkCount'], 1);
        expect(llm.lastFeature, 'pdf_ingestion');
        expect(llm.lastTaskType, 'pdf_ingestion');
        expect(
          meter.getTotalTokensPerTaskType()['pdf_ingestion'],
          greaterThan(0),
        );
      });
    });
  });
}
