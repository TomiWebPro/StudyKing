import 'dart:convert';

import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/system_monitor_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/mentor/services/tools/prep_tool.dart';

/// Parse PDF / textbook / notes text into structured knowledge-base chunks
/// so that later lessons, questions, and embeddings can draw on pre-parsed
/// material (Vision Next-Term §4.1, §4.3).
///
/// This is an off-period prep tool — it is designed to be enqueued via
/// [LlmAgent.enqueuePrepTask] and tracked in [LlmTaskManagerScreen] under its
/// configured prep category.
class IngestPdfToKbTool extends PrepTool {
  static final Logger _logger = const Logger('IngestPdfToKbTool');

  final LlmService _llmService;
  final String _modelId;
  final LlmTaskManager? _taskManager;
  // ignore: unused_field
  final LlmUsageMeter? _usageMeter;
  final PrepBudgetService? _budgetService;
  final SystemMonitorService? _systemMonitor;

  IngestPdfToKbTool({
    required LlmService llmService,
    required String modelId,
    LlmTaskManager? taskManager,
    LlmUsageMeter? usageMeter,
    PrepBudgetService? budgetService,
    SystemMonitorService? systemMonitor,
  })  : _llmService = llmService,
        _modelId = modelId,
        _taskManager = taskManager,
        _usageMeter = usageMeter,
        _budgetService = budgetService,
        _systemMonitor = systemMonitor;

  @override
  String get name => 'ingest_pdf_to_kb';

  @override
  String get description =>
      'Parse PDF or textbook text into structured knowledge-base chunks for '
      'offline reference during lessons. Call this after a student uploads '
      'study materials.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'textContent': {
            'type': 'string',
            'description': 'Text content extracted from the PDF or document',
          },
          'subjectId': {
            'type': 'string',
            'description': 'Subject ID to associate chunks with',
          },
          'topicId': {
            'type': 'string',
            'description': 'Topic ID to associate chunks with',
          },
          'localeName': {
            'type': 'string',
            'description': 'Locale for chunk content',
            'default': 'en',
          },
        },
        'required': ['textContent'],
      };

  @override
  int get estimatedInputTokens => 10000;

  @override
  int get estimatedOutputTokens => 2000;

  @override
  PrepCpuClass get cpuClass => PrepCpuClass.heavy;

  @override
  PrepCategory get prepCategory => PrepCategory.pdfIngestion;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final textContent = args['textContent'] as String? ?? '';
    final subjectId = args['subjectId'] as String? ?? '';
    final topicId = args['topicId'] as String? ?? '';
    final localeName = args['localeName'] as String? ?? 'en';

    if (textContent.trim().isEmpty) {
      return {'success': false, 'error': 'textContent is required'};
    }

    // Vision Next-Term §4.3: this is a heavy (CPU + LLM) prep tool. The
    // [IdleExecutor] gates enqueued tasks on [SystemMonitorService.canRunHeavyPrepNow],
    // but the agent can invoke this tool *directly* during conversation, bypassing
    // that queue. Enforce the device gate here too, so a constrained device (low
    // battery, high CPU, battery-saver) never starts an LLM parse it cannot finish.
    // The failure is `deferrable` so an idle queue can retry it once conditions recover.
    if (cpuClass == PrepCpuClass.heavy &&
        _systemMonitor != null &&
        !_systemMonitor.canRunHeavyPrepNow) {
      _logger.w(
        'PDF ingestion deferred: device under load (cpuClass=$cpuClass)',
      );
      return {
        'success': false,
        'error': 'Device constrained: heavy prep deferred until conditions recover',
        'deferrable': true,
      };
    }

    // Vision §4.2: per-subject opt-in. The IdleExecutor gates enqueued tasks,
    // but the agent can invoke this tool directly, so it enforces the gate
    // itself: no LLM call, no token spend, for a subject the student paused.
    final subjectGate = _budgetService;
    if (subjectGate != null &&
        subjectId.isNotEmpty &&
        !subjectGate.isPrepEnabledForSubject(subjectId)) {
      _logger.d(
        'PDF ingestion skipped: subject "$subjectId" disabled by student',
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
        'PDF ingestion denied: prep budget exhausted for ${prepCategory.taskTypeKey}',
      );
      return {
        'success': false,
        'error': 'Preparation budget exhausted for pdf_ingestion',
        'deferrable': true,
      };
    }

    final taskId = _taskManager?.createTask(
          feature: 'pdf_ingestion',
          modelId: _modelId,
          taskType: prepCategory.taskTypeKey,
        ) ??
        '';
    if (taskId.isNotEmpty) _taskManager?.startTask(taskId);

    try {
      final result = await _parseText(textContent, subjectId, topicId, localeName);

      if (taskId.isNotEmpty) {
        _taskManager?.completeTask(
          taskId,
          tokensUsed: estimatedInputTokens + estimatedOutputTokens,
        );
      }

      return {
        'success': result.isSuccess,
        'chunkCount': result.data?.length ?? 0,
        'subjectId': subjectId,
        'topicId': topicId,
      };
    } catch (e) {
      _logger.w('PDF ingestion failed: $e', e);
      if (taskId.isNotEmpty) _taskManager?.failTask(taskId, e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Result<List<Map<String, String>>>> _parseText(
    String textContent,
    String subjectId,
    String topicId,
    String localeName,
  ) async {
    final prompt = 'Parse the following text into structured knowledge-base '
        'chunks. Return ONLY a JSON array of objects, each with '
        '"heading" and "content" fields. Split by natural sections. '
        'No extra text.\n\nText:\n$textContent';

    final llmResult = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      localeName: localeName,
      feature: 'pdf_ingestion',
      taskType: prepCategory.taskTypeKey,
    );

    if (llmResult.isFailure) {
      return Result.failure(llmResult.error ?? 'LLM call failed');
    }

    final chunks = _parseChunks(llmResult.data ?? '');
    return Result.success(chunks);
  }

  List<Map<String, String>> _parseChunks(String response) {
    try {
      final cleaned = response
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => {
                  'heading': (m['heading'] as String? ?? '').toString(),
                  'content': (m['content'] as String? ?? '').toString(),
                })
            .toList();
      }
    } catch (e) {
      _logger.w('Failed to parse KB chunk JSON: $e', e);
    }
    return [];
  }
}
