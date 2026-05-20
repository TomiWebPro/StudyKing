import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class SearchQuestionsTool extends AgentTool {
  final QuestionRepository _questionRepo;

  SearchQuestionsTool({required QuestionRepository questionRepo})
      : _questionRepo = questionRepo;

  @override
  String get name => 'search_questions';

  @override
  String get description =>
      'Search for questions by subject, topic, or keyword.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'subjectId': {'type': 'string', 'description': 'Filter by subject ID'},
      'topicId': {'type': 'string', 'description': 'Filter by topic ID'},
      'keyword': {'type': 'string', 'description': 'Search keyword'},
      'limit': {
        'type': 'integer',
        'description': 'Max results',
        'default': 10,
      },
    },
    'required': [],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final subjectId = args['subjectId'] as String?;
    final topicId = args['topicId'] as String?;
    final keyword = args['keyword'] as String?;
    final limit = (args['limit'] as num?)?.toInt() ?? 10;

    List<dynamic> questions = [];
    if (subjectId != null && subjectId.isNotEmpty) {
      final result = await _questionRepo.getBySubject(subjectId);
      questions = result.data ?? [];
    } else {
      final result = await _questionRepo.getAll();
      questions = result.data ?? [];
    }

    if (topicId != null && topicId.isNotEmpty) {
      questions = questions.where((q) => q.topicId == topicId).toList();
    }
    if (keyword != null && keyword.isNotEmpty) {
      final lower = keyword.normalized;
      questions = questions
          .where((q) =>
              q.text.normalized.contains(lower) ||
              (q.topic ?? '').normalized.contains(lower))
          .toList();
    }

    questions = questions.take(limit).toList();
    return {
      'count': questions.length,
      'questions': questions.map((q) => {
        'id': q.id,
        'text': q.text,
        'type': q.type.name,
        'difficulty': q.difficulty,
        'topicId': q.topicId,
        'subjectId': q.subjectId,
      }).toList(),
    };
  }
}
