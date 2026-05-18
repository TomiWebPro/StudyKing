import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class ScheduleLessonTool extends AgentTool {
  final PlannerService _plannerService;

  ScheduleLessonTool({required PlannerService plannerService})
      : _plannerService = plannerService;

  @override
  String get name => 'schedule_lesson';

  @override
  String get description =>
      'Schedule a lesson/session for a specific topic at a given time.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'topicId': {'type': 'string', 'description': 'Topic ID'},
      'topicTitle': {'type': 'string', 'description': 'Topic title'},
      'subjectId': {'type': 'string', 'description': 'Subject ID'},
      'scheduledTime': {
        'type': 'string',
        'description': 'ISO 8601 datetime for the lesson'
      },
      'durationMinutes': {
        'type': 'integer',
        'description': 'Duration in minutes',
        'default': 30,
      },
    },
    'required': ['topicId', 'topicTitle', 'subjectId', 'scheduledTime'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final success = await _plannerService.scheduleLesson(
      topicId: args['topicId'] as String,
      topicTitle: args['topicTitle'] as String,
      subjectId: args['subjectId'] as String,
      scheduledTime: DateTime.parse(args['scheduledTime'] as String),
      durationMinutes: (args['durationMinutes'] as num?)?.toInt() ?? 30,
    );
    return {
      'success': success,
      'message': success
          ? 'Lesson scheduled: ${args['topicTitle']}'
          : 'Failed to schedule lesson',
    };
  }
}
