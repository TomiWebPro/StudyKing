import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/features/planner/services/planner_service.dart';

class CreatePlanTool extends AgentTool {
  final PlannerService _plannerService;

  CreatePlanTool({required PlannerService plannerService})
      : _plannerService = plannerService;

  @override
  String get name => 'create_plan';

  @override
  String get description =>
      'Create a learning plan or roadmap for a course over a specified number of days.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'course': {'type': 'string', 'description': 'Course name'},
      'daysValue': {'type': 'integer', 'description': 'Number of days for plan'},
      'hoursValue': {
        'type': 'integer',
        'description': 'Hours per day',
        'default': 2,
      },
    },
    'required': ['course', 'daysValue'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final plan = await _plannerService.generatePlan(
      course: args['course'] as String,
      daysValue: (args['daysValue'] as num).toInt(),
      hoursValue: (args['hoursValue'] as num?)?.toInt() ?? 2,
    );

    return {
      'success': plan != null,
      'planId': plan?.studentId ?? '',
      'totalDays': plan?.dailyPlans.length ?? 0,
      'message': plan != null
          ? 'Plan created for ${args['course']} over ${args['daysValue']} days'
          : 'Failed to create plan',
    };
  }
}
