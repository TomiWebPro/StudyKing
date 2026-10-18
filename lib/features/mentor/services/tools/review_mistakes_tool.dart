import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/features/mentor/services/syllabus_focus_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';

/// Agent tool that retrieves the student's recent wrong answers so the mentor
/// can conduct a conversational mistake review with markscheme explanations and
/// linked concepts.
///
/// Vision Next-Term §3.1 (`scenario_practice_mistake_review`,
/// `scenario_practice_review_adaptive`): the mentor must be able to answer
/// "Show me my mistakes and explain what concept each tested" with the actual
/// wrong answers, the correct answer + explanation, and the underlying topic —
/// not redirect the student to a separate UI.
///
/// The `MistakeReviewService` already materialises `MistakeEntry` records
/// (question, attempt, correctAnswer, explanation); this tool simply exposes
/// them to the agent as a structured, LLM-facing result map. Per AGENTS.md,
/// LLM-facing maps may remain in invariant English.
class ReviewMistakesTool extends AgentTool {
  static final Logger _logger = const Logger('ReviewMistakesTool');

  final MistakeReviewService _mistakeReviewService;
  final StudentIdService _studentIdService;

  /// Optional active-syllabus focus. When the student omits [subjectId] the
  /// tool falls back to the focused subject (set by [SwitchSyllabusFocusTool]),
  /// so "show me my mistakes" works against the active syllabus without the
  /// LLM having to restate it.
  final SyllabusFocusService? _focusService;

  ReviewMistakesTool({
    required MistakeReviewService mistakeReviewService,
    required StudentIdService studentIdService,
    SyllabusFocusService? focusService,
  })  : _mistakeReviewService = mistakeReviewService,
        _studentIdService = studentIdService,
        _focusService = focusService;

  @override
  String get name => 'review_mistakes';

  @override
  String get description =>
      'Retrieve the student\'s recent wrong answers from a practice session, '
      'each with its markscheme explanation and the concept (topic) it tested, '
      'so the mentor can review mistakes conversationally. Use this when the '
      'student asks "show me my mistakes", "what did I get wrong", or '
      '"explain my mistakes".';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {
            'type': 'string',
            'description': 'Subject to review mistakes for. If omitted, the '
                'currently focused syllabus (set via switch_syllabus_focus) is used.',
          },
          'daysBack': {
            'type': 'integer',
            'default': 7,
            'description': 'Look back this many days for incorrect attempts '
                '(default 7, 0 = all time).',
          },
          'limit': {
            'type': 'integer',
            'default': 10,
            'description': 'Maximum number of mistakes to return (default 10).',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final studentId = _studentIdService.getStudentId().data ?? '';
    if (studentId.isEmpty) {
      _logger.w('review_mistakes called with no studentId');
      return {
        'success': false,
        'error': 'no_student_id',
        'message': 'No student is currently active. Cannot review mistakes.',
      };
    }

    final subjectId =
        (args['subjectId']?.toString() ?? '').normalized.ifEmpty(
              () => _focusService?.hasFocus == true
                  ? (_focusService?.subjectId ?? '').normalized
                  : '',
            );

    if (subjectId.isEmpty) {
      _logger.w('review_mistakes called with no subjectId and no active focus');
      return {
        'success': false,
        'error': 'no_subject',
        'message': 'Please specify a subjectId to review, or set a syllabus '
            'focus first via switch_syllabus_focus.',
      };
    }

    final daysBack = AgentTool.intArg(args, 'daysBack') ?? 7;
    final limit = AgentTool.intArg(args, 'limit') ?? 10;
    final after =
        daysBack > 0 ? DateTime.now().subtract(Duration(days: daysBack)) : null;

    final result = await _mistakeReviewService.getMistakesFromSession(
      studentId: studentId,
      subjectId: subjectId,
      after: after,
    );

    if (result.isFailure) {
      _logger.w('review_mistakes failed: ${result.error}');
      return {
        'success': false,
        'error': result.error ?? 'Unknown error retrieving mistakes',
        'subjectId': subjectId,
      };
    }

    final mistakes = (result.data ?? []).take(limit).toList();

    return {
      'success': true,
      'subjectId': subjectId,
      'totalFound': mistakes.length,
      'mistakes': mistakes
          .map((m) => _mistakeEntryToJson(m, studentId))
          .toList(),
      'message': mistakes.isNotEmpty
          ? 'Found ${mistakes.length} mistakes with explanations for $subjectId.'
          : 'No recent mistakes found for $subjectId.',
    };
  }

  Map<String, dynamic> _mistakeEntryToJson(
    MistakeEntry mistake,
    String studentId,
  ) {
    final question = mistake.question;
    return {
      'questionId': question.id,
      'questionText': question.text,
      'concept': question.topicId,
      if (question.topic != null && question.topic!.isNotEmpty)
        'topic': question.topic,
      'subjectId': question.subjectId,
      'userAnswer': mistake.attempt?.userAnswer ?? '',
      'correctAnswer': mistake.correctAnswer,
      'explanation': mistake.explanation,
      'markschemeExplanation': mistake.explanation,
      'difficulty': question.difficulty,
      if (question.markscheme?.markschemePoints != null)
        'points': question.markscheme!.markschemePoints,
    };
  }
}

/// Extension used to fall back to a secondary value when a normalised string
/// is empty. Kept local to avoid touching the shared string-extensions module.
extension on String {
  String ifEmpty(String? Function() fallback) =>
      isEmpty ? (fallback() ?? '') : this;
}
