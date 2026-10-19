import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';

/// Agent tool that recommends a focused practice session on a weak or
/// prerequisite topic when a student is struggling.
///
/// Vision Next-Term §3.1 (`scenario_confused_student_fractions` Step 3-4):
/// > "After the 3rd attempt, the tutor should suggest a practice session on
/// > basic fractions, or redirect to a simpler prerequisite topic."
///
/// This is a callback-based tool (like [SwitchSyllabusFocusTool] /
/// [SwitchProviderTool]): it validates the LLM-supplied arguments and
/// delegates the actual practice recommendation to [onSuggestPractice], a
/// callback that, in production, queries [MasteryGraphService] for weak
/// topics and [QuestionRepository] for relevant question IDs. In tests,
/// this callback is a recording stub that returns a canned
/// [PracticeRecommendation].
///
/// Returns a result map that the LLM can surface to the student as a
/// confirmation message ("I've prepared 10 practice questions on fractions").
class SuggestPracticeTool extends AgentTool {
  static final Logger _logger = const Logger('SuggestPracticeTool');

  /// Callback that produces a practice recommendation. Returns
  /// [Result.success] with a [PracticeRecommendation] when practice
  /// material is available, or [Result.failure] with a
  /// human-readable error when it cannot be generated.
  final Future<Result<PracticeRecommendation>> Function({
    required String subjectId,
    String? topicId,
  }) onSuggestPractice;

  SuggestPracticeTool({
    required this.onSuggestPractice,
  });

  @override
  String get name => 'suggest_practice';

  @override
  String get description =>
      'Recommend and prepare a focused practice session on a weak or '
      'prerequisite topic when a student is struggling. Use this when a '
      'student says "I still do not get it" after one or more alternative '
      'explanations, or after "explain differently" has been tried. '
      'The tool identifies weak areas via mastery data and returns question '
      'IDs the student can immediately start practicing. Provide a subjectId '
      'to scope the recommendation, and optionally a topicId to target a '
      'specific area.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {
            'type': 'string',
            'description':
                'Subject ID to scope the practice recommendation '
                '(e.g. "math-hl"). Must match a SyllabusGoal subjectId from '
                'get_syllabus_structure. Required.',
          },
          'topicId': {
            'type': 'string',
            'description':
                'Optional specific topic to focus practice on. If omitted, '
                'the tool selects the student\'s weakest topic in the subject.',
          },
        },
        'required': ['subjectId'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final subjectIdRaw = args['subjectId']?.toString() ?? '';
    final subjectId = subjectIdRaw.normalized;

    if (subjectId.isEmpty) {
      _logger.w('suggest_practice received empty subjectId');
      return {
        'success': false,
        'error': 'subjectId is required and must not be empty',
      };
    }

    final topicIdRaw = args['topicId']?.toString();
    final topicId = topicIdRaw?.normalized;
    final topicIdClean =
        (topicId != null && topicId.isNotEmpty) ? topicId : null;

    final result = await onSuggestPractice(
      subjectId: subjectId,
      topicId: topicIdClean,
    );

    if (result.isFailure) {
      _logger.w('suggest_practice failed: ${result.error}');
      return {
        'success': false,
        'error': result.error ?? 'Unknown error suggesting practice',
        'subjectId': subjectId,
        if (topicIdClean != null) 'topicId': topicIdClean,
      };
    }

    final rec = result.data!;
    return {
      'success': true,
      'subjectId': subjectId,
      if (topicIdClean != null) 'topicId': topicIdClean,
      if (rec.topicId.isNotEmpty) 'recommendedTopicId': rec.topicId,
      if (rec.questionIds.isNotEmpty) 'questionIds': rec.questionIds,
      'message': rec.message,
    };
  }
}

/// Practice recommendation produced by [SuggestPracticeTool]'s callback.
///
/// In production this is assembled from [MasteryState] weak topics and
/// question repository results; in tests it is a canned value.
class PracticeRecommendation {
  /// The topicId the practice session targets.
  final String topicId;

  /// Human-readable confirmation message to surface to the student.
  final String message;

  /// Question IDs ready to be queued into a practice session.
  final List<String> questionIds;

  PracticeRecommendation({
    required this.topicId,
    required this.message,
    this.questionIds = const [],
  });
}
