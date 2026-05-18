import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';

class GetWeakTopicsTool extends AgentTool {
  final MasteryGraphService _masteryService;
  final StudentIdService _studentIdService;

  GetWeakTopicsTool({
    required MasteryGraphService masteryService,
    required StudentIdService studentIdService,
  })  : _masteryService = masteryService,
        _studentIdService = studentIdService;

  @override
  String get name => 'get_weak_topics';

  @override
  String get description =>
      'Get weak or at-risk topics that need student attention.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {},
    'required': [],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final studentId = _studentIdService.getStudentId();
    final weakResult = await _masteryService.getWeakTopics(studentId);
    final atRiskResult = await _masteryService.getAtRiskQuestions(studentId);

    final weakTopics = weakResult.data ?? [];
    final atRiskQuestions = atRiskResult.data ?? [];

    return {
      'weakTopicCount': weakTopics.length,
      'weakTopics': weakTopics
          .map((t) => {
        'topicId': t.topicId,
        'accuracy': t.accuracy,
        'reviewUrgency': t.reviewUrgency,
        'readinessScore': t.readinessScore,
      })
          .toList(),
      'atRiskQuestionCount': atRiskQuestions.length,
    };
  }
}
