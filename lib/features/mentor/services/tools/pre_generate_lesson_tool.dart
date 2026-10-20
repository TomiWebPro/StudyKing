import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/lessons/services/lesson_agent_service.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';

/// Pre-generate lesson blocks (slides, examples, exercises, homework,
/// recap) ahead of each scheduled lesson as an off-period prep task
/// (Vision Next-Term §4.1, §4.3).
///
/// This is the prep-time counterpart of [GenerateLessonBlocksTool] — same
/// underlying service, but enqueued during off-periods so live lessons
/// start with rich, pre-built material.
class PreGenerateLessonTool extends PrepTool {
  static final Logger _logger = const Logger('PreGenerateLessonTool');

  final LessonAgentService _lessonAgentService;
  final LlmTaskManager? _taskManager;
  final LlmUsageMeter? _usageMeter;
  final PrepBudgetService? _budgetService;

  PreGenerateLessonTool({
    required LessonAgentService lessonAgentService,
    LlmTaskManager? taskManager,
    LlmUsageMeter? usageMeter,
    PrepBudgetService? budgetService,
  })  : _lessonAgentService = lessonAgentService,
        _taskManager = taskManager,
        _usageMeter = usageMeter,
        _budgetService = budgetService;

  @override
  String get name => 'pre_generate_lesson';

  @override
  String get description =>
      'Pre-generate structured lesson blocks (slides, examples, exercises, '
      'homework, recap) for a topic during off-periods so live lessons start '
      'with rich, pre-built material.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {'type': 'string', 'description': 'Subject ID'},
          'topicId': {'type': 'string', 'description': 'Topic ID'},
          'topicTitle': {'type': 'string', 'description': 'Topic title'},
          'localeName': {
            'type': 'string',
            'description': 'Locale for content',
            'default': 'en',
          },
        },
        'required': ['subjectId', 'topicId', 'topicTitle'],
      };

  @override
  int get estimatedInputTokens => 8000;

  @override
  int get estimatedOutputTokens => 3000;

  @override
  PrepCpuClass get cpuClass => PrepCpuClass.heavy;

  @override
  PrepCategory get prepCategory => PrepCategory.lessonPrep;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final subjectId = args['subjectId'] as String? ?? '';
    final topicId = args['topicId'] as String? ?? '';
    final topicTitle = args['topicTitle'] as String? ?? '';
    final localeName = args['localeName'] as String? ?? 'en';

    if (subjectId.isEmpty || topicId.isEmpty || topicTitle.isEmpty) {
      return {
        'success': false,
        'error': 'subjectId, topicId, and topicTitle are required',
      };
    }

    // Vision §4.2: per-subject opt-in. The IdleExecutor gates enqueued tasks,
    // but the mentor agent can also invoke this tool directly, so the tool
    // enforces the gate itself: no LLM call, no token spend, for a subject the
    // student has paused. Checked before the budget gate so a disabled subject
    // short-circuits immediately regardless of remaining budget.
    final subjectGate = _budgetService;
    if (subjectGate != null &&
        subjectId.isNotEmpty &&
        !subjectGate.isPrepEnabledForSubject(subjectId)) {
      _logger.d(
        'Lesson prep skipped: subject "$subjectId" disabled by student',
      );
      return {
        'success': false,
        'error': 'Subject $subjectId prep disabled by student',
        'deferrable': true,
      };
    }

    // Vision §4.2: respect the preparation budget before spending tokens.
    final budget = _budgetService;
    if (budget != null &&
        !budget.canSpend(prepCategory, estimatedTotalTokens)) {
      _logger.w(
        'Lesson pre-generation denied: prep budget exhausted for ${prepCategory.taskTypeKey}',
      );
      return {
        'success': false,
        'error': 'Preparation budget exhausted for lesson_prep',
        'deferrable': true,
      };
    }

    final taskId = _taskManager?.createTask(
          feature: 'lesson_prep',
          modelId: 'lesson_generation',
          taskType: prepCategory.taskTypeKey,
        ) ??
        '';
    if (taskId.isNotEmpty) _taskManager?.startTask(taskId);

    try {
      final lesson = await _lessonAgentService.generateLesson(
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        localeName: localeName,
        // Vision §4.1/§4.3 + §0 token principle: when this tool runs as an
        // off-period prep task, the underlying LLM call must record its tokens
        // under the 'lesson_prep' feature so LlmTaskType.fromFeature maps it
        // to a prep-category task type ('background') instead of the live
        // 'generation' bucket. Without this, actual lesson-prep tokens leak
        // into totalLiveTokens() and corrupt the prep-vs-live ratio.
        feature: PrepCategory.lessonPrep.taskTypeKey,
        taskType: PrepCategory.lessonPrep.taskTypeKey,
      );

      if (taskId.isNotEmpty) {
        _taskManager?.completeTask(
          taskId,
          tokensUsed: estimatedInputTokens + estimatedOutputTokens,
        );
      }

      if (lesson == null) {
        return {'success': false, 'message': 'Failed to generate lesson'};
      }

      return {
        'success': true,
        'lessonId': lesson.id,
        'blockCount': lesson.blocks.length,
        'title': lesson.title,
      };
    } catch (e) {
      _logger.w('Lesson pre-generation failed: $e', e);
      if (taskId.isNotEmpty) _taskManager?.failTask(taskId, e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }
}
