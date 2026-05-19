import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/services/action_executor.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class FakePlannerService extends PlannerService {
  bool scheduleCalled = false;
  bool cancelCalled = false;
  bool regenerateCalled = false;
  String? lastTopicId;
  String? lastTopicTitle;
  String? lastSubjectId;
  DateTime? lastScheduledTime;
  int lastDurationMinutes = 30;
  String? lastSessionId;
  double? lastAdjustmentFactor;
  bool scheduleResult = true;
  bool cancelResult = true;
  bool regenerateResult = true;
  bool throwOnSchedule = false;
  bool throwOnCancel = false;
  bool throwOnRegenerate = false;

  FakePlannerService() : super();

  @override
  Future<bool> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    if (throwOnSchedule) throw Exception('Schedule failed');
    scheduleCalled = true;
    lastTopicId = topicId;
    lastTopicTitle = topicTitle;
    lastSubjectId = subjectId;
    lastScheduledTime = scheduledTime;
    lastDurationMinutes = durationMinutes;
    return scheduleResult;
  }

  @override
  Future<bool> cancelLesson(String sessionId) async {
    if (throwOnCancel) throw Exception('Cancel failed');
    cancelCalled = true;
    lastSessionId = sessionId;
    return cancelResult;
  }

  @override
  Future<bool> suggestPlanRegeneration({
    required String studentId,
    required double adjustmentFactor,
  }) async {
    if (throwOnRegenerate) throw Exception('Regenerate failed');
    regenerateCalled = true;
    lastAdjustmentFactor = adjustmentFactor;
    return regenerateResult;
  }
}

PendingActionModel createAction({
  String id = 'action-1',
  String studentId = 'student-1',
  String actionType = 'schedule',
  String topicTitle = 'Algebra',
  String? sessionId,
  Map<String, dynamic> payload = const {},
  String status = 'pending',
}) {
  return PendingActionModel(
    id: id,
    studentId: studentId,
    actionType: actionType,
    topicTitle: topicTitle,
    sessionId: sessionId,
    payload: payload,
    status: status,
  );
}

void main() {
  group('ActionExecutor', () {
    late FakePlannerService plannerService;
    late ActionExecutor executor;

    setUp(() {
      plannerService = FakePlannerService();
      executor = ActionExecutor(plannerService: plannerService);
    });

    group('execute', () {
      test('returns false for unknown action type', () async {
        final action = createAction(actionType: 'unknown');
        final result = await executor.execute(action);
        expect(result, isFalse);
      });

      group('schedule', () {
        test('executes schedule action with valid payload', () async {
          final action = createAction(
            actionType: 'schedule',
            topicTitle: 'Algebra',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-01T10:00:00.000',
              'durationMinutes': 45,
            },
          );
          final result = await executor.execute(action);
          expect(result, isTrue);
          expect(plannerService.scheduleCalled, isTrue);
          expect(plannerService.lastTopicId, 'topic-1');
          expect(plannerService.lastTopicTitle, 'Algebra');
          expect(plannerService.lastSubjectId, 'subject-1');
          expect(plannerService.lastDurationMinutes, 45);
        });

        test('uses default duration when not specified', () async {
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-01T10:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isTrue);
          expect(plannerService.lastDurationMinutes, 30);
        });

        test('returns false when topicId is missing', () async {
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-01T10:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when subjectId is missing', () async {
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'topicId': 'topic-1',
              'scheduledTime': '2026-06-01T10:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when scheduledTime is missing', () async {
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when scheduledTime is invalid', () async {
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': 'invalid-date',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when plannerService returns false', () async {
          plannerService.scheduleResult = false;
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-01T10:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when plannerService throws', () async {
          plannerService.throwOnSchedule = true;
          final action = createAction(
            actionType: 'schedule',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-01T10:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });
      });

      group('reschedule without sessionId', () {
        test('schedules new lesson when no sessionId in payload', () async {
          final action = createAction(
            actionType: 'reschedule',
            payload: {
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-02T14:00:00.000',
              'durationMinutes': 45,
            },
          );
          final result = await executor.execute(action);
          expect(result, isTrue);
          expect(plannerService.cancelCalled, isFalse);
          expect(plannerService.scheduleCalled, isTrue);
          expect(plannerService.lastDurationMinutes, 45);
        });
      });

      group('reschedule', () {
        test('executes reschedule with sessionId, cancels old then schedules new', () async {
          final action = createAction(
            actionType: 'reschedule',
            payload: {
              'sessionId': 'session-1',
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-02T14:00:00.000',
              'durationMinutes': 60,
            },
          );
          final result = await executor.execute(action);
          expect(result, isTrue);
          expect(plannerService.cancelCalled, isTrue);
          expect(plannerService.lastSessionId, 'session-1');
          expect(plannerService.scheduleCalled, isTrue);
          expect(plannerService.lastDurationMinutes, 60);
        });

        test('returns false when topicId is missing in reschedule', () async {
          final action = createAction(
            actionType: 'reschedule',
            payload: {
              'sessionId': 'session-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-02T14:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when scheduledTime is invalid in reschedule', () async {
          final action = createAction(
            actionType: 'reschedule',
            payload: {
              'sessionId': 'session-1',
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': 'bad-date',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when cancelLesson throws', () async {
          plannerService.throwOnCancel = true;
          final action = createAction(
            actionType: 'reschedule',
            payload: {
              'sessionId': 'session-1',
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-02T14:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when scheduleLesson throws in reschedule', () async {
          plannerService.throwOnSchedule = true;
          final action = createAction(
            actionType: 'reschedule',
            payload: {
              'sessionId': 'session-1',
              'topicId': 'topic-1',
              'subjectId': 'subject-1',
              'scheduledTime': '2026-06-02T14:00:00.000',
            },
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });
      });

      group('planAdjustment', () {
        test('executes plan adjustment with valid adjustmentFactor', () async {
          final action = createAction(
            actionType: 'planAdjustment',
            payload: {'adjustmentFactor': 0.8},
          );
          final result = await executor.execute(action);
          expect(result, isTrue);
          expect(plannerService.regenerateCalled, isTrue);
          expect(plannerService.lastAdjustmentFactor, 0.8);
        });

        test('returns false when adjustmentFactor is missing', () async {
          final action = createAction(
            actionType: 'planAdjustment',
            payload: {},
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });

        test('returns false when suggestPlanRegeneration throws', () async {
          plannerService.throwOnRegenerate = true;
          final action = createAction(
            actionType: 'planAdjustment',
            payload: {'adjustmentFactor': 0.8},
          );
          final result = await executor.execute(action);
          expect(result, isFalse);
        });
      });
    });
  });
}
