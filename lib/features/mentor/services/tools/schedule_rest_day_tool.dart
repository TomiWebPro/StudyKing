import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Agent tool that marks a study day as a rest day so the plan protects the
/// student from overwork.
///
/// Vision Next-Term §3.1 (`scenario_overworked_student`): "I've scheduled a
/// rest day for you tomorrow — confirm?" — confirmation is handled in the
/// mentor conversation (the LLM only calls this tool after the student
/// confirms), so the call itself is an explicit, non-silent schedule change.
class ScheduleRestDayTool extends AgentTool {
  static final Logger _logger = const Logger('ScheduleRestDayTool');
  final PlannerService _plannerService;
  final String _localeName;

  ScheduleRestDayTool({
    required PlannerService plannerService,
    required String localeName,
  })  : _plannerService = plannerService,
        _localeName = localeName;

  @override
  String get name => 'schedule_rest_day';

  @override
  String get description =>
      'Mark a study day as a rest day to reduce workload and protect the '
      'student from overwork. Only call after the student explicitly confirms '
      'they want a rest day — this alters the study plan.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'date': {
        'type': 'string',
        'description': 'ISO 8601 date or datetime to mark as a rest day '
            '(e.g. 2025-01-31T14:00:00Z)',
      },
    },
    'required': ['date'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final l10n = lookupAppLocalizations(Locale(_localeName));

    // The LLM may emit relative or non-ISO date strings (e.g. "tomorrow")
    // despite the schema. Parse defensively and report a validation failure
    // instead of letting FormatException escape execute().
    final dateRaw = args['date'];
    DateTime? date;
    if (dateRaw is String && dateRaw.isNotEmpty) {
      try {
        date = DateTime.parse(dateRaw);
      } catch (e) {
        _logger.w(
          'schedule_rest_day received unparseable date: $dateRaw',
          e,
        );
      }
    } else {
      _logger.w('schedule_rest_day called without a date string');
    }

    if (date == null) {
      return {
        'success': false,
        'message': l10n.toolScheduleRestDayInvalidDate,
      };
    }

    final result = await _plannerService.markRestDay(date, l10n: l10n);
    final applied = result.isSuccess && result.data == true;
    return {
      'success': applied,
      'date': date.toIso8601String(),
      'message': applied
          ? l10n.toolScheduleRestDayResult(date.toIso8601String())
          : l10n.toolScheduleRestDayFail,
    };
  }
}
