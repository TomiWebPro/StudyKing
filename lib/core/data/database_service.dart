import '../errors/result.dart';
import '../utils/logger.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

/// Kept as an initialization coordinator only.
/// Repositories should be injected individually where needed going forward.
class DatabaseService {
  static final Logger _logger = const Logger('DatabaseService');
  final TopicRepository topicRepository;
  final QuestionRepository questionRepository;
  final AttemptRepository attemptRepository;
  final LessonRepository lessonRepository;
  final SessionRepository sessionRepository;
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

  Future<Result<void>> init() async {
    return Result.capture(() async {
      await topicRepository.init();
      await questionRepository.init();
      await attemptRepository.init();
      await lessonRepository.init();
      await sessionRepository.init();
      await subjectRepository.init();
      await conversationRepository.init();
      await tutorSessionRepository.init();
      _logger.i('All repositories initialized successfully');
    }, context: 'DatabaseService.init');
  }
}
