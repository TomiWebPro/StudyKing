import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/mentor/services/tools/schedule_lesson_tool.dart';

class FakePlannerService extends PlannerService {
  bool _scheduleResult = true;
  int scheduleCallCount = 0;
  String? lastTopicId;
  String? lastTopicTitle;
  String? lastSubjectId;
  DateTime? lastScheduledTime;
  int? lastDurationMinutes;

  FakePlannerService();

  void setScheduleResult(bool v) => _scheduleResult = v;

  @override
  Future<Result<bool>> scheduleLesson({
    required String topicId,
    required String topicTitle,
    required String subjectId,
    required DateTime scheduledTime,
    int durationMinutes = 30,
  }) async {
    scheduleCallCount++;
    lastTopicId = topicId;
    lastTopicTitle = topicTitle;
    lastSubjectId = subjectId;
    lastScheduledTime = scheduledTime;
    lastDurationMinutes = durationMinutes;
    return Result.success(_scheduleResult);
  }
}

void main() {
  group('ScheduleLessonTool', () {
    late FakePlannerService fakePlanner;
    late ScheduleLessonTool tool;

    setUp(() {
      fakePlanner = FakePlannerService();
      tool = ScheduleLessonTool(plannerService: fakePlanner);
    });

    test('name returns schedule_lesson', () {
      expect(tool.name, 'schedule_lesson');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      final properties = params['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll(['topicId', 'topicTitle', 'subjectId', 'scheduledTime', 'durationMinutes']));
      expect(properties['topicId']['type'], 'string');
      expect(properties['topicTitle']['type'], 'string');
      expect(properties['subjectId']['type'], 'string');
      expect(properties['scheduledTime']['type'], 'string');
      expect(properties['durationMinutes']['type'], 'integer');
      expect(properties['durationMinutes']['default'], 30);
      expect(params['required'], ['topicId', 'topicTitle', 'subjectId', 'scheduledTime']);
    });

    test('execute returns success message when scheduling succeeds', () async {
      fakePlanner.setScheduleResult(true);

      final result = await tool.execute({
        'topicId': 'topic-1',
        'topicTitle': 'Algebra Basics',
        'subjectId': 'subj-1',
        'scheduledTime': '2026-06-01T10:00:00Z',
      });

      expect(result['success'], true);
      expect(result['message'], 'Lesson scheduled: Algebra Basics');
      expect(fakePlanner.scheduleCallCount, 1);
    });

    test('execute returns failure message when scheduling returns failure result', () async {
      fakePlanner.setScheduleResult(false);

      final result = await tool.execute({
        'topicId': 'topic-1',
        'topicTitle': 'Algebra Basics',
        'subjectId': 'subj-1',
        'scheduledTime': '2026-06-01T10:00:00Z',
      });

      expect(result['success'], false);
      expect(result['message'], 'Failed to schedule lesson');
    });

    test('execute passes correct parameters to planner service', () async {
      final scheduledTime = DateTime(2026, 6, 1, 10, 0);

      await tool.execute({
        'topicId': 'topic-42',
        'topicTitle': 'Calculus',
        'subjectId': 'subj-math',
        'scheduledTime': scheduledTime.toIso8601String(),
      });

      expect(fakePlanner.lastTopicId, 'topic-42');
      expect(fakePlanner.lastTopicTitle, 'Calculus');
      expect(fakePlanner.lastSubjectId, 'subj-math');
      expect(fakePlanner.lastScheduledTime, scheduledTime);
    });

    test('execute uses default durationMinutes when omitted', () async {
      await tool.execute({
        'topicId': 'topic-1',
        'topicTitle': 'Physics',
        'subjectId': 'subj-1',
        'scheduledTime': '2026-06-01T10:00:00Z',
      });

      expect(fakePlanner.lastDurationMinutes, 30);
    });

    test('execute accepts custom durationMinutes', () async {
      await tool.execute({
        'topicId': 'topic-1',
        'topicTitle': 'Physics',
        'subjectId': 'subj-1',
        'scheduledTime': '2026-06-01T10:00:00Z',
        'durationMinutes': 60,
      });

      expect(fakePlanner.lastDurationMinutes, 60);
    });

    test('execute handles DateTime parsing from ISO string', () async {
      final result = await tool.execute({
        'topicId': 'topic-1',
        'topicTitle': 'History',
        'subjectId': 'subj-1',
        'scheduledTime': '2026-12-25T14:30:00.000Z',
      });

      expect(result['success'], true);
      expect(fakePlanner.lastScheduledTime, DateTime(2026, 12, 25, 14, 30));
    });
  });
}
