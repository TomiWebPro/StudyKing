import '../utils/logger.dart';
import 'package:studyking/core/data/data.dart';

class DatabaseService {
  final Logger _logger = const Logger('DatabaseService');
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

  Future<void> init() async {
    try {
      await topicRepository.init();
      await questionRepository.init();
      await attemptRepository.init();
      await lessonRepository.init();
      await sessionRepository.init();
      await subjectRepository.init();
      await conversationRepository.init();
      await tutorSessionRepository.init();
      _logger.i('All repositories initialized successfully');
    } catch (e) {
      _logger.e('Error initializing database service', e);
      rethrow;
    }
  }
}
