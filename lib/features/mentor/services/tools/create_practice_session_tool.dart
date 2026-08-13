import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class CreatePracticeSessionTool extends AgentTool {
  static final Logger _logger = const Logger('CreatePracticeSessionTool');
  final QuestionRepository _questionRepo;
  final SpacedRepetitionService _srService;
  final MasteryGraphService _masteryService;
  final ReadinessScorer _scorer;
  final ExamSessionService _examSessionService;
  final StudentIdService _studentIdService;

  CreatePracticeSessionTool({
    required QuestionRepository questionRepo,
    required SpacedRepetitionService srService,
    required MasteryGraphService masteryService,
    required ReadinessScorer scorer,
    required ExamSessionService examSessionService,
    required StudentIdService studentIdService,
  })  : _questionRepo = questionRepo,
        _srService = srService,
        _masteryService = masteryService,
        _scorer = scorer,
        _examSessionService = examSessionService,
        _studentIdService = studentIdService;

  @override
  String get name => 'create_practice_session';

  @override
  String get description =>
      'Create and prepare a practice session for the student. '
      'Supports modes: spaced_repetition (due reviews), weak_areas (target weak topics), '
      'topic_focus (practice a specific topic), at_risk (questions about to lose mastery), '
      'and exam (timed exam with difficulty quotas). '
      'Returns question IDs and session details that can be used to launch the session.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'mode': {
        'type': 'string',
        'enum': [
          'spaced_repetition',
          'weak_areas',
          'topic_focus',
          'at_risk',
          'exam',
        ],
        'description':
            'Type of practice session. spaced_repetition: review due questions. '
            'weak_areas: target the student\'s weakest topics. '
            'topic_focus: practice questions on a specific topic. '
            'at_risk: questions about to lose mastery. '
            'exam: timed exam with configurable difficulty.',
      },
      'subjectId': {
        'type': 'string',
        'description': 'Subject ID. Required for all modes except at_risk.',
      },
      'topicId': {
        'type': 'string',
        'description': 'Topic ID. Used by topic_focus mode to filter to a specific topic.',
      },
      'questionCount': {
        'type': 'integer',
        'description': 'Maximum number of questions to include. Default: 10.',
      },
      'durationMinutes': {
        'type': 'integer',
        'description': 'Duration in minutes for exam mode.',
      },
      'easyCount': {
        'type': 'integer',
        'description': 'Number of easy questions for exam mode.',
      },
      'mediumCount': {
        'type': 'integer',
        'description': 'Number of medium questions for exam mode.',
      },
      'hardCount': {
        'type': 'integer',
        'description': 'Number of hard questions for exam mode.',
      },
    },
    'required': ['mode'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final mode = args['mode'] as String?;
    if (mode == null) {
      return {'success': false, 'error': 'mode parameter is required'};
    }

    final subjectId = args['subjectId'] as String?;
    final topicId = args['topicId'] as String?;
    final questionCount = (args['questionCount'] as num?)?.toInt() ?? 10;
    final durationMinutes = (args['durationMinutes'] as num?)?.toInt();
    final easyCount = (args['easyCount'] as num?)?.toInt();
    final mediumCount = (args['mediumCount'] as num?)?.toInt();
    final hardCount = (args['hardCount'] as num?)?.toInt();

    try {
      switch (mode) {
        case 'spaced_repetition':
          return await _createSpacedRepetitionSession(
            subjectId: subjectId,
            questionCount: questionCount,
          );
        case 'weak_areas':
          return await _createWeakAreasSession(
            subjectId: subjectId,
            questionCount: questionCount,
          );
        case 'topic_focus':
          return await _createTopicFocusSession(
            subjectId: subjectId,
            topicId: topicId,
            questionCount: questionCount,
          );
        case 'at_risk':
          return await _createAtRiskSession(
            questionCount: questionCount,
          );
        case 'exam':
          return await _createExamSession(
            subjectId: subjectId,
            topicId: topicId,
            questionCount: questionCount,
            durationMinutes: durationMinutes ?? 30,
            easyCount: easyCount,
            mediumCount: mediumCount,
            hardCount: hardCount,
          );
        default:
          return {
            'success': false,
            'error': 'Unknown mode: $mode. Valid modes: spaced_repetition, weak_areas, topic_focus, at_risk, exam',
          };
      }
    } catch (e) {
      _logger.w('Error creating practice session', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _createSpacedRepetitionSession({
    String? subjectId,
    required int questionCount,
  }) async {
    if (subjectId == null || subjectId.isEmpty) {
      return {'success': false, 'error': 'subjectId is required for spaced_repetition mode'};
    }

    final dueResult = await _srService.getPracticeQuestions(subjectId);
    final dueQuestions = dueResult.data ?? [];

    if (dueQuestions.isEmpty) {
      return {
        'success': true,
        'mode': 'spaced_repetition',
        'sessionId': 'sr_${DateTime.now().millisecondsSinceEpoch}',
        'questionCount': 0,
        'message': 'No questions are due for review in this subject. Great job staying on top of your reviews!',
        'isSpacedRepetition': true,
        'questionIds': <String>[],
      };
    }

    dueQuestions.sort((a, b) =>
        (a.nextReview ?? DateTime.now()).compareTo(b.nextReview ?? DateTime.now()));
    final selected = dueQuestions.take(questionCount).toList();
    final questionIds = selected.map((q) => q.id).toList();
    final topics = selected.map((q) => q.topicId).toSet().toList();

    return {
      'success': true,
      'mode': 'spaced_repetition',
      'sessionId': 'sr_${DateTime.now().millisecondsSinceEpoch}',
      'questionCount': questionIds.length,
      'topicsCovered': topics,
      'isSpacedRepetition': true,
      'questionIds': questionIds,
    };
  }

  Future<Map<String, dynamic>> _createWeakAreasSession({
    String? subjectId,
    required int questionCount,
  }) async {
    if (subjectId == null || subjectId.isEmpty) {
      return {'success': false, 'error': 'subjectId is required for weak_areas mode'};
    }

    final studentId = _studentIdService.getStudentId();
    await _masteryService.init();

    final weakResult = await _masteryService.getWeakTopics(studentId);
    final weakTopics = weakResult.data ?? [];

    if (weakTopics.isEmpty) {
      return {
        'success': true,
        'mode': 'weak_areas',
        'questionCount': 0,
        'message': 'No weak areas detected. Keep up the great work!',
        'questionIds': <String>[],
      };
    }

    final weakTopicIds = weakTopics.map((t) => t.topicId).toSet();
    final allQuestionsResult = await _questionRepo.getAll();
    final allQuestions = allQuestionsResult.data ?? [];
    final weakQuestions = allQuestions
        .where((q) => weakTopicIds.contains(q.topicId) && q.subjectId == subjectId)
        .toList();

    if (weakQuestions.isEmpty) {
      return {
        'success': true,
        'mode': 'weak_areas',
        'questionCount': 0,
        'message': 'No questions found for weak topics in this subject.',
        'questionIds': <String>[],
      };
    }

    final scored = await _scorer.scoreQuestions(weakQuestions);
    final selected = scored.take(questionCount).toList();
    final questionIds = selected.map((s) => s.question.id).toList();
    final topics = selected.map((s) => s.question.topicId).toSet().toList();

    final topicsCovered = weakTopics
        .where((t) => topics.contains(t.topicId))
        .map((t) => t.topicId)
        .toList();

    return {
      'success': true,
      'mode': 'weak_areas',
      'sessionId': 'wa_${DateTime.now().millisecondsSinceEpoch}',
      'questionCount': questionIds.length,
      'topicsCovered': topicsCovered.isNotEmpty ? topicsCovered : topics,
      'questionIds': questionIds,
    };
  }

  Future<Map<String, dynamic>> _createTopicFocusSession({
    String? subjectId,
    String? topicId,
    required int questionCount,
  }) async {
    if (subjectId == null || subjectId.isEmpty) {
      return {'success': false, 'error': 'subjectId is required for topic_focus mode'};
    }
    if (topicId == null || topicId.isEmpty) {
      return {'success': false, 'error': 'topicId is required for topic_focus mode'};
    }

    final allQuestionsResult = await _questionRepo.getAll();
    final allQuestions = allQuestionsResult.data ?? [];
    final topicQuestions = allQuestions
        .where((q) => q.topicId == topicId && q.subjectId == subjectId)
        .toList();

    if (topicQuestions.isEmpty) {
      return {
        'success': true,
        'mode': 'topic_focus',
        'questionCount': 0,
        'message': 'No questions found for this topic.',
        'questionIds': <String>[],
      };
    }

    final scored = await _scorer.scoreQuestions(topicQuestions);
    final selected = scored.take(questionCount).toList();
    final questionIds = selected.map((s) => s.question.id).toList();

    return {
      'success': true,
      'mode': 'topic_focus',
      'sessionId': 'tf_${DateTime.now().millisecondsSinceEpoch}',
      'questionCount': questionIds.length,
      'topicsCovered': [topicId],
      'questionIds': questionIds,
    };
  }

  Future<Map<String, dynamic>> _createAtRiskSession({
    required int questionCount,
  }) async {
    final studentId = _studentIdService.getStudentId();
    await _masteryService.init();

    final atRiskResult = await _masteryService.getAtRiskQuestions(studentId);
    final atRiskData = atRiskResult.data ?? [];

    if (atRiskData.isEmpty) {
      return {
        'success': true,
        'mode': 'at_risk',
        'questionCount': 0,
        'message': 'No at-risk questions detected. Your mastery is looking solid!',
        'questionIds': <String>[],
      };
    }

    final atRiskIds = atRiskData.map((a) => a.questionId).toSet();
    final allQuestionsResult = await _questionRepo.getAll();
    final allQuestions = allQuestionsResult.data ?? [];
    final atRiskQuestions = allQuestions
        .where((q) => atRiskIds.contains(q.id))
        .toList();

    if (atRiskQuestions.isEmpty) {
      return {
        'success': true,
        'mode': 'at_risk',
        'questionCount': 0,
        'message': 'At-risk questions detected but matching questions not found in the question bank.',
        'questionIds': <String>[],
      };
    }

    final scored = await _scorer.scoreQuestions(atRiskQuestions);
    final selected = scored.take(questionCount).toList();
    final questionIds = selected.map((s) => s.question.id).toList();
    final topics = selected.map((s) => s.question.topicId).toSet().toList();

    return {
      'success': true,
      'mode': 'at_risk',
      'sessionId': 'ar_${DateTime.now().millisecondsSinceEpoch}',
      'questionCount': questionIds.length,
      'topicsCovered': topics,
      'questionIds': questionIds,
    };
  }

  Future<Map<String, dynamic>> _createExamSession({
    String? subjectId,
    String? topicId,
    required int questionCount,
    required int durationMinutes,
    int? easyCount,
    int? mediumCount,
    int? hardCount,
  }) async {
    if (subjectId == null || subjectId.isEmpty) {
      return {'success': false, 'error': 'subjectId is required for exam mode'};
    }

    final allQuestionsResult = await _questionRepo.getAll();
    final allQuestions = allQuestionsResult.data ?? [];

    final config = ExamConfig(
      durationMinutes: durationMinutes,
      questionCount: questionCount,
      easyCount: easyCount,
      mediumCount: mediumCount,
      hardCount: hardCount,
      topicIds: topicId != null && topicId.isNotEmpty ? [topicId] : null,
      subjectId: subjectId,
    );

    final selected = _examSessionService.selectQuestions(
      pool: allQuestions,
      config: config,
    );

    if (selected.isEmpty) {
      return {
        'success': true,
        'mode': 'exam',
        'questionCount': 0,
        'message': 'No questions available for the specified exam criteria.',
        'questionIds': <String>[],
      };
    }

    final questionIds = selected.map((q) => q.id).toList();
    final topics = selected.map((q) => q.topicId).toSet().toList();

    final easySelected = selected.where((q) => q.difficulty <= 2).length;
    final mediumSelected = selected.where((q) => q.difficulty == 3).length;
    final hardSelected = selected.where((q) => q.difficulty >= 4).length;

    return {
      'success': true,
      'mode': 'exam',
      'sessionId': 'exam_${DateTime.now().millisecondsSinceEpoch}',
      'questionCount': questionIds.length,
      'durationMinutes': durationMinutes,
      'topicsCovered': topics,
      'difficultyBreakdown': {
        'easy': easySelected,
        'medium': mediumSelected,
        'hard': hardSelected,
      },
      'questionIds': questionIds,
    };
  }
}
