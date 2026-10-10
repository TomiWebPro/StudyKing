import 'package:flutter/material.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ScheduleLessonTool extends AgentTool {
  static final Logger _logger = const Logger('ScheduleLessonTool');
  final PlannerService _plannerService;
  final String _localeName;

  ScheduleLessonTool({required PlannerService plannerService, required String localeName})
      : _plannerService = plannerService,
        _localeName = localeName;

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
    final l10n = lookupAppLocalizations(Locale(_localeName));

    // The LLM may emit relative or non-ISO date strings (e.g. "tomorrow
    // 5pm") despite the schema. Parse defensively and report a validation
    // failure instead of letting FormatException escape execute().
    final scheduledTimeRaw = args['scheduledTime'];
    DateTime? scheduledTime;
    if (scheduledTimeRaw is String && scheduledTimeRaw.isNotEmpty) {
      try {
        scheduledTime = DateTime.parse(scheduledTimeRaw);
      } catch (e) {
        _logger.w(
          'schedule_lesson received unparseable scheduledTime: '
          '$scheduledTimeRaw',
          e,
        );
      }
    } else {
      _logger.w('schedule_lesson called without a scheduledTime string');
    }

    if (scheduledTime == null) {
      return {
        'success': false,
        'message': l10n.toolScheduleLessonInvalidTime,
      };
    }

    final successResult = await _plannerService.scheduleLesson(
      topicId: args['topicId'] as String,
      topicTitle: args['topicTitle'] as String,
      subjectId: args['subjectId'] as String,
      scheduledTime: scheduledTime,
      durationMinutes: (args['durationMinutes'] as num?)?.toInt() ?? 30,
    );
    final success = successResult.data ?? false;
    return {
      'success': success,
      'message': success
          ? l10n.toolScheduleLessonResult(args['topicTitle'] as String)
          : l10n.toolScheduleLessonFail,
    };
  }
}
