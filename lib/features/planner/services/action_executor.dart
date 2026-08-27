import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'planner_service.dart';

class ActionExecutor {
  static final Logger _logger = const Logger('ActionExecutor');

  final PlannerService _plannerService;

  ActionExecutor({
    required PlannerService plannerService,
  }) : _plannerService = plannerService;

  Future<Result<bool>> execute(PendingActionModel action) async {
    try {
      switch (action.actionType) {
        case 'schedule':
          return await _executeSchedule(action);
        case 'reschedule':
          return await _executeReschedule(action);
        case 'planAdjustment':
          return await _executePlanAdjustment(action);
        default:
          _logger.w('Unknown action type: ${action.actionType}');
          return Result.failure('Unknown action type: ${action.actionType}');
      }
    } catch (e) {
      _logger.w('Failed to execute action', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> _executeSchedule(PendingActionModel action) async {
    final topicId = action.payload['topicId'] as String?;
    final subjectId = action.payload['subjectId'] as String?;
    final topicTitle = action.topicTitle;
    final scheduledTimeStr = action.payload['scheduledTime'] as String?;

    if (topicId == null || subjectId == null || scheduledTimeStr == null) {
      _logger.w('Missing required fields for schedule action: topicId=$topicId, subjectId=$subjectId, scheduledTime=$scheduledTimeStr');
      return Result.failure('Missing required fields for schedule action');
    }

    final scheduledTime = DateTime.tryParse(scheduledTimeStr);
    if (scheduledTime == null) {
      _logger.w('Invalid scheduledTime for schedule action: $scheduledTimeStr');
      return Result.failure('Invalid scheduledTime: $scheduledTimeStr');
    }

    final durationMinutes = (action.payload['durationMinutes'] as num?)?.toInt() ?? 30;

    try {
      final result = await _plannerService.scheduleLesson(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      if (result.isFailure) {
        _logger.w('Failed to schedule lesson: ${result.error}');
        return Result.failure(result.error);
      }
      return Result.success(result.data ?? false);
    } catch (e) {
      _logger.w('Failed to schedule lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> _executeReschedule(PendingActionModel action) async {
    final sessionId = action.payload['sessionId'] as String?;
    final topicId = action.payload['topicId'] as String?;
    final subjectId = action.payload['subjectId'] as String?;
    final topicTitle = action.topicTitle;
    final scheduledTimeStr = action.payload['scheduledTime'] as String?;

    if (sessionId != null) {
      try {
        final cancelResult = await _plannerService.cancelLesson(sessionId);
        if (cancelResult.isFailure) {
          _logger.w('Failed to cancel lesson $sessionId: ${cancelResult.error}');
          return Result.failure(cancelResult.error);
        }
      } catch (e) {
        _logger.w('Failed to cancel lesson $sessionId', e);
        return Result.failure(e.toString());
      }
    }

    if (topicId == null || subjectId == null || scheduledTimeStr == null) {
      _logger.w('Missing required fields for reschedule action: topicId=$topicId, subjectId=$subjectId, scheduledTime=$scheduledTimeStr');
      return Result.failure('Missing required fields for reschedule action');
    }

    final scheduledTime = DateTime.tryParse(scheduledTimeStr);
    if (scheduledTime == null) {
      _logger.w('Invalid scheduledTime for reschedule action: $scheduledTimeStr');
      return Result.failure('Invalid scheduledTime: $scheduledTimeStr');
    }

    final durationMinutes = (action.payload['durationMinutes'] as num?)?.toInt() ?? 30;

    try {
      final result = await _plannerService.scheduleLesson(
        topicId: topicId,
        topicTitle: topicTitle,
        subjectId: subjectId,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );
      if (result.isFailure) {
        _logger.w('Failed to schedule lesson during reschedule: ${result.error}');
        return Result.failure(result.error);
      }
      return Result.success(result.data ?? false);
    } catch (e) {
      _logger.w('Failed to schedule lesson during reschedule', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> _executePlanAdjustment(PendingActionModel action) async {
    final adjustmentFactor = (action.payload['adjustmentFactor'] as num?)?.toDouble();
    if (adjustmentFactor == null) {
      _logger.w('Missing adjustmentFactor for planAdjustment action');
      return Result.failure('Missing adjustmentFactor for planAdjustment action');
    }

    try {
      final result = await _plannerService.planOrchestrator.suggestRegeneration(
        studentId: action.studentId,
        adjustmentFactor: adjustmentFactor,
      );
      if (result.isFailure) {
        _logger.w('Failed to suggest regeneration: ${result.error}');
        return Result.failure(result.error);
      }
      return Result.success(true);
    } catch (e) {
      _logger.w('Failed to suggest regeneration', e);
      return Result.failure(e.toString());
    }
  }
}
