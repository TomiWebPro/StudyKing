import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'planner_service.dart';

class ActionExecutor {
  final PlannerService _plannerService;

  ActionExecutor({
    PlannerService? plannerService,
  })  : _plannerService = plannerService ?? PlannerService();

  Future<bool> execute(PendingActionModel action) async {
    switch (action.actionType) {
      case 'schedule':
        return _executeSchedule(action);
      case 'reschedule':
        return _executeReschedule(action);
      case 'planAdjustment':
        return _executePlanAdjustment(action);
      default:
        return false;
    }
  }

  Future<bool> _executeSchedule(PendingActionModel action) async {
    final topicId = action.payload['topicId'] as String?;
    final subjectId = action.payload['subjectId'] as String?;
    final topicTitle = action.topicTitle;
    final scheduledTimeStr = action.payload['scheduledTime'] as String?;

    if (topicId == null || subjectId == null || scheduledTimeStr == null) {
      return false;
    }

    final scheduledTime = DateTime.tryParse(scheduledTimeStr);
    if (scheduledTime == null) return false;

    final durationMinutes = (action.payload['durationMinutes'] as num?)?.toInt() ?? 30;

    return _plannerService.scheduleLesson(
      topicId: topicId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      scheduledTime: scheduledTime,
      durationMinutes: durationMinutes,
    );
  }

  Future<bool> _executeReschedule(PendingActionModel action) async {
    final sessionId = action.payload['sessionId'] as String?;
    final topicId = action.payload['topicId'] as String?;
    final subjectId = action.payload['subjectId'] as String?;
    final topicTitle = action.topicTitle;
    final scheduledTimeStr = action.payload['scheduledTime'] as String?;

    if (sessionId != null) {
      await _plannerService.cancelLesson(sessionId);
    }

    if (topicId == null || subjectId == null || scheduledTimeStr == null) {
      return false;
    }

    final scheduledTime = DateTime.tryParse(scheduledTimeStr);
    if (scheduledTime == null) return false;

    final durationMinutes = (action.payload['durationMinutes'] as num?)?.toInt() ?? 30;

    return _plannerService.scheduleLesson(
      topicId: topicId,
      topicTitle: topicTitle,
      subjectId: subjectId,
      scheduledTime: scheduledTime,
      durationMinutes: durationMinutes,
    );
  }

  Future<bool> _executePlanAdjustment(PendingActionModel action) async {
    final adjustmentFactor = (action.payload['adjustmentFactor'] as num?)?.toDouble();
    if (adjustmentFactor == null) return false;

    final studentId = action.studentId;
    final result = await _plannerService.planAdapter.suggestRegeneration(
      studentId: studentId,
      adjustmentFactor: adjustmentFactor,
    );
    return result.isSuccess;
  }
}
