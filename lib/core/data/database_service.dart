import 'repositories/topic_repository.dart';
import 'repositories/question_repository.dart';
import 'repositories/attempt_repository.dart';
import 'repositories/lesson_repository.dart';
import 'repositories/study_session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class DatabaseService {
  final TopicRepository topicRepository;
  final QuestionRepository questionRepository;
  final AttemptRepository attemptRepository;
  final LessonRepository lessonRepository;
  final StudySessionRepository sessionRepository;
  final SubjectRepository subjectRepository;

  DatabaseService({
    required this.topicRepository,
    required this.questionRepository,
    required this.attemptRepository,
    required this.lessonRepository,
    required this.sessionRepository,
    required this.subjectRepository,
  });
}
