import 'package:studyking/core/data/data.dart';

class DatabaseService {
  final TopicRepository topicRepository;
  final QuestionRepository questionRepository;
  final AttemptRepository attemptRepository;
  final LessonRepository lessonRepository;
  final StudySessionRepository sessionRepository;
  final SubjectRepository subjectRepository;
  final ConversationRepository conversationRepository;
  final TutorSessionRepository tutorSessionRepository;

  DatabaseService({
    required this.topicRepository,
    required this.questionRepository,
    required this.attemptRepository,
    required this.lessonRepository,
    required this.sessionRepository,
    required this.subjectRepository,
    required this.conversationRepository,
    required this.tutorSessionRepository,
  });
}
