import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';

/// Refresh mastery analysis as an off-period prep task (Vision Next-Term
/// §4.1, §4.3).
///
/// Identifies weak topics and at-risk questions, producing readiness
/// scoring and mastery-refresh proposals for the mentor to review. Proposals
/// are returned, never silently committed — follow-up actions require mentor
/// confirmation per `agent_must_read.md` §Mentor.
///
/// This tool is [PrepCpuClass.light] — it only reads existing data, no LLM
/// calls — so it proceeds immediately even under CPU pressure.
class RefreshMasteryTool extends PrepTool {
  static final Logger _logger = const Logger('RefreshMasteryTool');

  final MasteryGraphService _masteryService;
  final StudentIdService _studentIdService;
  final LlmTaskManager? _taskManager;
  final LlmUsageMeter? _usageMeter;
  final PrepBudgetService? _budgetService;

  RefreshMasteryTool({
    required MasteryGraphService masteryService,
    required StudentIdService studentIdService,
    LlmTaskManager? taskManager,
    LlmUsageMeter? usageMeter,
    PrepBudgetService? budgetService,
  })  : _masteryService = masteryService,
        _studentIdService = studentIdService,
        _taskManager = taskManager,
        _usageMeter = usageMeter,
        _budgetService = budgetService;

  @override
  String get name => 'refresh_mastery';

  @override
  String get description =>
      'Analyze weak topics and at-risk questions, then produce readiness '
      'scoring and mastery-refresh proposals for the mentor to review.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'studentId': {
            'type': 'string',
            'description': 'Student ID (uses StudentIdService if omitted)',
          },
        },
        'required': [],
      };

  @override
  int get estimatedInputTokens => 500;

  @override
  int get estimatedOutputTokens => 500;

  @override
  PrepCpuClass get cpuClass => PrepCpuClass.light;

  @override
  PrepCategory get prepCategory => PrepCategory.background;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final explicitStudentId = args['studentId'] as String? ?? '';
    final studentId = explicitStudentId.isNotEmpty
        ? explicitStudentId
        : (_studentIdService.getStudentId().data ?? '');

    if (studentId.isEmpty) {
      return {'success': false, 'error': 'No student ID available'};
    }

    final taskId = _taskManager?.createTask(
          feature: 'mastery_refresh',
          modelId: 'background',
          taskType: prepCategory.taskTypeKey,
        ) ??
        '';
    if (taskId.isNotEmpty) _taskManager?.startTask(taskId);

    try {
      final weakResult = await _masteryService.getWeakTopics(studentId);
      final atRiskResult =
          await _masteryService.getAtRiskQuestions(studentId);

      final weakTopics = weakResult.data ?? [];
      final atRiskQuestions = atRiskResult.data ?? [];

      if (taskId.isNotEmpty) {
        _taskManager?.completeTask(
          taskId,
          tokensUsed: estimatedInputTokens + estimatedOutputTokens,
        );
      }

      // Record estimated usage under the correct taskType so
      // PrepBudgetService can track spend per category.
      _usageMeter?.recordUsage(
        id: taskId.isNotEmpty
            ? taskId
            : 'mastery_refresh_${DateTime.now().millisecondsSinceEpoch}',
        feature: 'mastery_refresh',
        modelId: 'background',
        inputTokens: estimatedInputTokens,
        outputTokens: estimatedOutputTokens,
        taskType: prepCategory.taskTypeKey,
      );

      return {
        'success': true,
        'studentId': studentId,
        'weakTopicCount': weakTopics.length,
        'atRiskQuestionCount': atRiskQuestions.length,
        'needsReviewTopics': weakTopics.length,
      };
    } catch (e) {
      _logger.w('Mastery refresh failed: $e', e);
      if (taskId.isNotEmpty) _taskManager?.failTask(taskId, e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }
}
