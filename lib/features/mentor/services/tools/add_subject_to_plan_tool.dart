import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';

/// Agent tool that adds a new subject ([SyllabusGoal]) to the student's existing
/// learning plan by delegating to [PlannerService.addSubjectToPlan].
///
/// Vision Next-Term §3.1 / scenario_longterm_user_accelerates Step 2:
/// > "Student says 'Actually, I want to study Biology instead of Physics.' The
/// > mentor should propose a new subject, preserving mastered topics and
/// > carrying forward relevant plan fragments."
///
/// `addSubjectToPlan` (planner_service.dart:320) merges the new goal into the
/// existing plan: it combines [SyllabusGoal] lists, regenerates via
/// `generatePlanFromSyllabus`, and preserves the plan id and prior date ranges.
/// This tool wraps that method for conversation — the missing link that left the
/// longterm-user scenario Step 2 PARTIAL (no agent tool wrapped
/// addSubjectToPlan, so the mentor could not add a subject from dialogue).
///
/// The tool validates LLM-supplied arguments, builds a [SyllabusGoal], and
/// delegates the merge to [onAddSubject]. In production [onAddSubject] is wired
/// (by the provider) to load the active plan and call
/// `PlannerService.addSubjectToPlan`; in tests it is a recording stub or a fake
/// service. The returned map is LLM-facing (invariant English per AGENTS.md).
class AddSubjectToPlanTool extends AgentTool {
  static final Logger _logger = const Logger('AddSubjectToPlanTool');

  /// Callback that merges [newGoal] into the active plan. In production this
  /// loads the existing plan via `PlannerService.loadExistingPlan` and calls
  /// `PlannerService.addSubjectToPlan`; in tests it is a recording stub or a
  /// fake service. Returns the merged [PersonalLearningPlan] on success.
  final Future<Result<PersonalLearningPlan?>> Function({
    required SyllabusGoal newGoal,
  }) onAddSubject;

  AddSubjectToPlanTool({
    required this.onAddSubject,
  });

  @override
  String get name => 'add_subject_to_plan';

  @override
  String get description =>
      'Add a new subject to the student\'s existing learning plan, merging it '
      'with currently-planned subjects while preserving mastered topics and '
      'prior plan fragments. The plan must already exist (use create_plan '
      'first if no plan has been made). Use this when the student says they '
      'want to study a new subject, e.g. "I want to study Biology instead '
      'of Physics".';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {
            'type': 'string',
            'description':
                'The subjectId of the syllabus to add (e.g. "biology"). Must '
                'match a SyllabusGoal subjectId resolvable by '
                'get_syllabus_structure, or a new subject id.',
          },
          'subjectTitle': {
            'type': 'string',
            'description':
                'Human-readable title of the subject (e.g. "Biology"). '
                'Optional but recommended for confirmation messages.',
          },
          'targetDays': {
            'type': 'integer',
            'description':
                'Number of days the new subject should run (e.g. 90). '
                'Defaults to 30 when omitted.',
            'default': 30,
          },
          'targetHoursPerDay': {
            'type': 'integer',
            'description':
                'Study hours per day for the new subject. '
                'Defaults to 1 when omitted.',
            'default': 1,
          },
          'syllabusCode': {
            'type': 'string',
            'description':
                'Optional syllabus code or exam-board identifier '
                '(e.g. "IB-0610").',
          },
        },
        'required': ['subjectId'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final subjectIdRaw = args['subjectId']?.toString() ?? '';
    final subjectId = subjectIdRaw.normalized;

    if (subjectId.isEmpty) {
      _logger.w('add_subject_to_plan received empty subjectId');
      return {
        'success': false,
        'error': 'subjectId is required and must not be empty',
      };
    }

    final subjectTitle = args['subjectTitle']?.toString();
    final targetDays = AgentTool.intArg(args, 'targetDays') ?? 30;
    final targetHoursPerDay = AgentTool.intArg(args, 'targetHoursPerDay') ?? 1;
    final syllabusCode = args['syllabusCode']?.toString();

    if (targetDays <= 0) {
      _logger.w('add_subject_to_plan received non-positive targetDays: $targetDays');
      return {
        'success': false,
        'error': 'targetDays must be a positive integer when provided',
        'subjectId': subjectId,
      };
    }
    if (targetHoursPerDay <= 0) {
      _logger.w(
        'add_subject_to_plan received non-positive targetHoursPerDay: $targetHoursPerDay',
      );
      return {
        'success': false,
        'error':
            'targetHoursPerDay must be a positive integer when provided',
        'subjectId': subjectId,
      };
    }

    final newGoal = SyllabusGoal(
      subjectId: subjectId,
      subjectTitle: subjectTitle ?? subjectId,
      syllabusCode: syllabusCode ?? '',
      targetDays: targetDays,
      targetHoursPerDay: targetHoursPerDay,
    );

    final result = await onAddSubject(newGoal: newGoal);

    if (result.isFailure) {
      _logger.w('add_subject_to_plan failed: ${result.error}');
      return {
        'success': false,
        'error':
            result.error ?? 'Unknown error adding subject to plan',
        'subjectId': subjectId,
      };
    }

    final plan = result.data;
    final title = subjectTitle ?? subjectId;
    return {
      'success': true,
      'subjectId': subjectId,
      'subjectTitle': title,
      'planId': plan?.planId ?? '',
      'totalDays': plan?.dailyPlans.length ?? 0,
      'message': 'I\'ll add "$title" to your existing plan, preserving your '
          'prior schedule and mastered topics.',
    };
  }
}
