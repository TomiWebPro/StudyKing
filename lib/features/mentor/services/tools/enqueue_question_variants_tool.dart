import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/questions/services/question_variant_service.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';

/// Generate concept-preserving, value-varying question variants as an
/// off-period prep task (Vision Next-Term §4.1, §4.3).
///
/// Enqueues variant generation for a specific question so that spaced
/// repetition can re-test the same concept with different values.
class EnqueueQuestionVariantsTool extends PrepTool {
  static final Logger _logger = const Logger('EnqueueQuestionVariantsTool');

  final QuestionVariantService _variantService;
  final QuestionRepository _questionRepo;
  final LlmTaskManager? _taskManager;
  final LlmUsageMeter? _usageMeter;
  final PrepBudgetService? _budgetService;

  EnqueueQuestionVariantsTool({
    required QuestionVariantService variantService,
    required QuestionRepository questionRepo,
    LlmTaskManager? taskManager,
    LlmUsageMeter? usageMeter,
    PrepBudgetService? budgetService,
  })  : _variantService = variantService,
        _questionRepo = questionRepo,
        _taskManager = taskManager,
        _usageMeter = usageMeter,
        _budgetService = budgetService;

  @override
  String get name => 'enqueue_question_variants';

  @override
  String get description =>
      'Generate concept-preserving, value-varying variants of an existing '
      'question for adaptive practice and spaced repetition.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'questionId': {
            'type': 'string',
            'description': 'ID of the source question to variant',
          },
          'count': {
            'type': 'integer',
            'description': 'Number of variants to generate',
            'default': 3,
          },
        },
        'required': ['questionId'],
      };

  @override
  int get estimatedInputTokens => 5000;

  @override
  int get estimatedOutputTokens => 3000;

  @override
  PrepCpuClass get cpuClass => PrepCpuClass.heavy;

  @override
  PrepCategory get prepCategory => PrepCategory.questionVariants;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final questionId = args['questionId'] as String? ?? '';
    final count = AgentTool.intArg(args, 'count') ?? 3;

    if (questionId.isEmpty) {
      return {'success': false, 'error': 'questionId is required'};
    }
    if (count <= 0) {
      return {'success': false, 'error': 'count must be a positive integer'};
    }

    // Vision §4.2: respect the preparation budget before spending tokens.
    final budget = _budgetService;
    if (budget != null &&
        !budget.canSpend(prepCategory, estimatedTotalTokens)) {
      _logger.w(
        'Question variant generation denied: prep budget exhausted for ${prepCategory.taskTypeKey}',
      );
      return {
        'success': false,
        'error': 'Preparation budget exhausted for question_variants',
        'deferrable': true,
      };
    }

    final taskId = _taskManager?.createTask(
          feature: 'question_variants',
          modelId: 'variant_generation',
          taskType: prepCategory.taskTypeKey,
        ) ??
        '';
    if (taskId.isNotEmpty) _taskManager?.startTask(taskId);

    try {
      final fetchResult = await _questionRepo.get(questionId);
      final question = fetchResult.data;

      if (question == null) {
        if (taskId.isNotEmpty) _taskManager?.failTask(taskId, 'Question not found');
        return {'success': false, 'error': 'Question not found: $questionId'};
      }

      final variantResult = await _generateVariants(question, count);

      if (taskId.isNotEmpty) {
        _taskManager?.completeTask(
          taskId,
          tokensUsed: estimatedInputTokens + estimatedOutputTokens,
        );
      }

      final variants = variantResult.data ?? [];

      // Record estimated usage under the correct taskType so
      // PrepBudgetService can track spend per category.
      _usageMeter?.recordUsage(
        id: taskId.isNotEmpty
            ? taskId
            : 'question_variants_${DateTime.now().millisecondsSinceEpoch}',
        feature: 'question_variants',
        modelId: 'variant_generation',
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
        taskType: prepCategory.taskTypeKey,
      );

      return {
        'success': variantResult.isSuccess,
        'variantCount': variants.length,
        'variantIds': variants.map((v) => v.id).toList(),
        'sourceQuestionId': questionId,
      };
    } catch (e) {
      _logger.w('Question variant generation failed: $e', e);
      if (taskId.isNotEmpty) _taskManager?.failTask(taskId, e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Result<List<Question>>> _generateVariants(
    Question source,
    int count,
  ) {
    return _variantService.generateVariants(source, count: count);
  }
}
