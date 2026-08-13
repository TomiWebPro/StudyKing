import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

class GetLessonHistoryTool extends AgentTool {
  final LessonRepository _lessonRepository;
  final TutorSessionRepository _tutorSessionRepository;
  final StudentIdService _studentIdService;

  GetLessonHistoryTool({
    required LessonRepository lessonRepository,
    required TutorSessionRepository tutorSessionRepository,
    required StudentIdService studentIdService,
  })  : _lessonRepository = lessonRepository,
        _tutorSessionRepository = tutorSessionRepository,
        _studentIdService = studentIdService;

  @override
  String get name => 'get_lesson_history';

  @override
  String get description =>
      'Query past lesson records, content, and performance. '
      'Use this to answer questions like "What did we cover in the last lesson?", '
      '"Remind me about integration", or "Show me my calculus lessons".';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {
            'type': 'string',
            'description': 'Filter lessons by subject ID',
          },
          'topicId': {
            'type': 'string',
            'description': 'Filter lessons by topic ID',
          },
          'daysBack': {
            'type': 'integer',
            'default': 30,
            'description': 'How far back to look in days (default 30)',
          },
          'limit': {
            'type': 'integer',
            'default': 5,
            'description': 'Maximum number of lessons to return (default 5)',
          },
          'includeContent': {
            'type': 'boolean',
            'default': false,
            'description': 'Include full lesson block content (default false)',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final studentId = _studentIdService.getStudentId();
    final subjectId = args['subjectId'] as String?;
    final topicId = args['topicId'] as String?;
    final daysBack = (args['daysBack'] as num?)?.toInt() ?? 30;
    final limit = (args['limit'] as num?)?.toInt() ?? 5;
    final includeContent = args['includeContent'] as bool? ?? false;

    final cutoff = DateTime.now().subtract(Duration(days: daysBack));

    List<Lesson> lessons;
    if (subjectId != null && topicId != null) {
      final result = await _lessonRepository.getBySubjectAndTopic(subjectId, topicId);
      lessons = result.data ?? [];
    } else if (subjectId != null) {
      final result = await _lessonRepository.getBySubject(subjectId);
      lessons = result.data ?? [];
    } else if (topicId != null) {
      final result = await _lessonRepository.getByTopic(topicId);
      lessons = result.data ?? [];
    } else {
      final result = await _lessonRepository.getAll();
      lessons = result.data ?? [];
    }

    lessons = lessons.where((l) => l.createdAt.isAfter(cutoff)).toList();
    lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    lessons = lessons.take(limit).toList();

    if (lessons.isEmpty) {
      return {
        'lessons': <Map<String, dynamic>>[],
        'totalFound': 0,
        'message': 'No lessons found matching the criteria.',
      };
    }

    final sessionsResult = await _tutorSessionRepository.getStudentSessions(studentId);
    final allSessions = sessionsResult.data ?? [];
    final sessionMap = <String, dynamic>{};
    for (final session in allSessions) {
      if (session.lessonId != null) {
        sessionMap[session.lessonId!] = session;
      }
    }

    final lessonData = lessons.map((lesson) {
      final session = sessionMap[lesson.id];
      final blockTypes =
          lesson.blocks.map((b) => b.type.name).toSet().toList();

      final data = <String, dynamic>{
        'id': lesson.id,
        'title': lesson.title,
        'subjectId': lesson.subjectId,
        'topicId': lesson.topicId,
        'date': lesson.createdAt.toIso8601String(),
        'blocksCount': lesson.blocks.length,
        'blockTypes': blockTypes,
        'difficulty': lesson.difficulty,
      };

      if (session != null) {
        data['performance'] = {
          'questionsAsked': session.questionsAsked,
          'questionsCorrect': session.questionsCorrect,
          'accuracy': session.accuracy,
          'elapsedMinutes': session.elapsedMinutes,
        };
        if (session.tutorNotes != null && session.tutorNotes!.isNotEmpty) {
          data['summary'] = session.tutorNotes;
        }
      }

      if (includeContent) {
        data['blocks'] = lesson.blocks.map((b) => {
              'id': b.id,
              'type': b.type.name,
              'content': b.content,
              'order': b.order,
            }).toList();
      }

      return data;
    }).toList();

    return {
      'lessons': lessonData,
      'totalFound': lessonData.length,
    };
  }
}
