import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class CreatePlanTool extends AgentTool {
  final PlannerService _plannerService;
  final String _localeName;

  CreatePlanTool({required PlannerService plannerService, required String localeName})
      : _plannerService = plannerService,
        _localeName = localeName;

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
    final daysValue = AgentTool.intArg(args, 'daysValue');
    final hoursValue = AgentTool.intArg(args, 'hoursValue') ?? 2;
    if (daysValue == null || daysValue <= 0) {
      return {
        'success': false,
        'error': 'daysValue parameter is required and must be a positive integer',
      };
    }

    final result = await _plannerService.generatePlan(
      course: args['course'] as String,
      daysValue: daysValue,
      hoursValue: hoursValue,
    );
    final plan = result.data;

    final l10n = lookupAppLocalizations(Locale(_localeName));

    return {
      'success': plan != null,
      'planId': plan?.planId ?? '',
      'totalDays': plan?.dailyPlans.length ?? 0,
      'message': plan != null
          ? l10n.toolCreatePlanResult(args['course'] as String, daysValue)
          : l10n.toolCreatePlanFail,
    };
  }
}
