import 'package:flutter/material.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Agent tool that sets wellbeing reminders (bedtime, break, pacing) so the
/// mentor can convert overwork / late-night context into a concrete,
/// persisted adjustment.
///
/// Vision Next-Term §3.1 (`scenario_overworked_student`):
/// > "I've set a bedtime reminder for 22:00 — confirm?" — confirmation is
/// > handled in the mentor conversation; the LLM only calls this tool after
/// > the student explicitly confirms, so the call itself is an explicit,
/// > non-silent adjustment (see `agent_must_read.md` §Mentor).
///
/// Follows the [SwitchProviderTool] callback pattern: the tool validates the
/// LLM-supplied arguments and delegates persistence to [onAdjust], keeping the
/// tool independent of Hive / Riverpod at test time.
class WellbeingAdjustScheduleTool extends AgentTool {
  static final Logger _logger = const Logger('WellbeingAdjustScheduleTool');

  /// Valid reminder-type keys accepted by the tool.
  static const Set<String> validReminderTypes = {
    'bedtime',
    'break',
    'pacing',
  };

  final String _localeName;

  /// Callback that persists the wellbeing reminder. In production this is
  /// wired (via the provider) to [SettingsService.saveWellbeingReminder];
  /// in tests it is a recording stub.
  final Future<Result<void>> Function({
    required String reminderType,
    required String time,
    required bool enabled,
    String? note,
  }) onAdjust;

  WellbeingAdjustScheduleTool({
    required String localeName,
    required this.onAdjust,
  }) : _localeName = localeName;

  @override
  String get name => 'wellbeing_adjust_schedule';

  @override
  String get description =>
      'Set or toggle a wellbeing reminder (bedtime, break, pacing) for the '
      "student. Only call this tool AFTER the student explicitly confirms "
      "they want the adjustment — this modifies the student's wellbeing "
      "schedule and must never be applied silently.";

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'reminderType': {
        'type': 'string',
        'description':
            'Type of wellbeing reminder: bedtime, break, or pacing.',
        'enum': validReminderTypes.toList()..sort(),
      },
      'time': {
        'type': 'string',
        'description':
            'Time in HH:MM format (e.g. 22:00). Ignored when enabled is false.',
      },
      'enabled': {
        'type': 'boolean',
        'description':
            'Whether to enable (true) or disable (false) the reminder. '
            'Defaults to true.',
        'default': true,
      },
      'note': {
        'type': 'string',
        'description': 'Optional free-text note from the student.',
      },
    },
    'required': ['reminderType', 'time'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final l10n = lookupAppLocalizations(Locale(_localeName));

    final reminderTypeRaw = args['reminderType']?.toString() ?? '';
    final timeRaw = args['time']?.toString() ?? '';
    final enabled = args['enabled'] as bool? ?? true;
    final note = args['note']?.toString();

    // Validate reminderType — tolerate case/whitespace differences from the LLM.
    final reminderType = reminderTypeRaw.normalized;
    if (!validReminderTypes.contains(reminderType)) {
      _logger.w(
        'wellbeing_adjust_schedule received invalid reminderType: '
        '$reminderTypeRaw',
      );
      return {
        'success': false,
        'message': l10n.toolWellbeingReminderInvalidType,
      };
    }

    // Validate time format when the reminder is being enabled.
    if (enabled && !_isValidTime(timeRaw)) {
      _logger.w(
        'wellbeing_adjust_schedule received invalid time: $timeRaw',
      );
      return {
        'success': false,
        'message': l10n.toolWellbeingReminderInvalidTime,
      };
    }

    final result = await onAdjust(
      reminderType: reminderType,
      time: timeRaw,
      enabled: enabled,
      note: note,
    );

    if (result.isFailure) {
      _logger.w(
        'wellbeing_adjust_schedule persistence failed: ${result.error}',
      );
      return {
        'success': false,
        'message': l10n.toolWellbeingReminderFail,
      };
    }

    if (!enabled) {
      return {
        'success': true,
        'message': l10n.toolWellbeingReminderDisabled(reminderType),
      };
    }

    return {
      'success': true,
      'reminderType': reminderType,
      'time': timeRaw,
      'message': l10n.toolWellbeingReminderResult(reminderType, timeRaw),
    };
  }

  /// Validates that [value] is a well-formed HH:MM time string (e.g. `22:00`).
  static bool _isValidTime(String value) {
    if (value.isEmpty) return false;
    final match = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').firstMatch(value);
    return match != null;
  }
}
