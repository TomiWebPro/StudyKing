import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Agent tool that sets the student's active syllabus focus so that
/// subsequent mentor tool calls (scheduling, question selection, lesson
/// generation) can default to the focused syllabus.
///
/// Vision Next-Term §3.1 (`scenario_multisubject_juggling` Step 3):
/// > "Student says 'Switch my focus to Math for the next 2 weeks' — the
/// > mentor should adjust the plan's pacing for Math."
///
/// The tool validates the LLM-supplied arguments and delegates the focus
/// change to [onFocusChanged], a callback that, in production, writes to
/// [SyllabusFocusService]; in tests this callback is a recording stub.
///
/// The returned map is LLM-facing (invariant English per AGENTS.md i18n
/// convention — prompts/tutor notes may stay invariant).
class SwitchSyllabusFocusTool extends AgentTool {
  static final Logger _logger = const Logger('SwitchSyllabusFocusTool');

  /// Callback that persists the new focus. In production this is wired
  /// (via the provider) to [SyllabusFocusService.setFocus]; in tests it is
  /// a recording stub. Returns [Result.success] when the focus was stored.
  final Future<Result<void>> Function({
    required String subjectId,
    String? subjectTitle,
    int? days,
  }) onFocusChanged;

  SwitchSyllabusFocusTool({
    required this.onFocusChanged,
  });

  @override
  String get name => 'switch_syllabus_focus';

  @override
  String get description =>
      'Set the active syllabus focus so that subsequent mentor tool calls '
      '(scheduling, question selection, lesson generation) default to this '
      'subject. Use this when the student says things like: focus on Math '
      'for the next 2 weeks, or switch to Chemistry. Only call this tool '
      'after the student explicitly requests the focus change.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {
            'type': 'string',
            'description':
                'The subjectId of the syllabus to focus on (e.g. "math-hl"). '
                'Must match a SyllabusGoal subjectId from get_syllabus_structure.',
          },
          'subjectTitle': {
            'type': 'string',
            'description':
                'Human-readable title of the subject (e.g. "Math AA HL"). '
                'Optional but recommended for confirmation messages.',
          },
          'days': {
            'type': 'integer',
            'description': 'Optional focus duration in days (e.g. 14 for '
                '"next 2 weeks"). If omitted, the focus is indefinite '
                'until changed.',
          },
        },
        'required': ['subjectId'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final subjectIdRaw = args['subjectId']?.toString() ?? '';
    final subjectId = subjectIdRaw.normalized;

    if (subjectId.isEmpty) {
      _logger.w('switch_syllabus_focus received empty subjectId');
      return {
        'success': false,
        'error': 'subjectId is required and must not be empty',
      };
    }

    final subjectTitle = args['subjectTitle']?.toString();
    final days = AgentTool.intArg(args, 'days');

    if (days != null && days <= 0) {
      _logger.w('switch_syllabus_focus received non-positive days: $days');
      return {
        'success': false,
        'error': 'days must be a positive integer when provided',
        'subjectId': subjectId,
      };
    }

    final result = await onFocusChanged(
      subjectId: subjectId,
      subjectTitle: subjectTitle,
      days: days,
    );

    if (result.isFailure) {
      _logger.w('switch_syllabus_focus failed: ${result.error}');
      return {
        'success': false,
        'error': result.error ?? 'Unknown error setting syllabus focus',
        'subjectId': subjectId,
      };
    }

    final durationNote = days != null ? ' for $days days' : '';
    return {
      'success': true,
      'subjectId': subjectId,
      if (subjectTitle != null) 'subjectTitle': subjectTitle,
      if (days != null) 'days': days,
      'message': subjectTitle != null
          ? 'Active syllabus focus set to "$subjectTitle"$durationNote.'
          : 'Active syllabus focus set to "$subjectId"$durationNote.',
    };
  }
}
