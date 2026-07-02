import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

class _FakeTopicRepository extends TopicRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FakeQuestionRepository extends QuestionRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FakeLessonRepository extends LessonRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FakeSessionRepository extends SessionRepository {
}

class _FakeSubjectRepository extends SubjectRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FakeConversationRepository extends ConversationRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FakeTutorSessionRepository extends TutorSessionRepository {
  int initCallCount = 0;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    return Result.success(null);
  }
}

class _FailingRepo extends TopicRepository {
  @override
  Future<Result<void>> init() async {
    throw Exception('init failed');
  }
}

class _FailingQuestionRepo extends QuestionRepository {
  @override
  Future<Result<void>> init() async {
    throw Exception('question init failed');
  }
}

final _logger = Logger('DatabaseServiceTest');

void main() {
  group('DatabaseService', () {
    late _FakeTopicRepository topicRepo;
    late _FakeQuestionRepository questionRepo;
    late _FakeAttemptRepository attemptRepo;
    late _FakeLessonRepository lessonRepo;
    late _FakeSessionRepository sessionRepo;
    late _FakeSubjectRepository subjectRepo;
    late _FakeConversationRepository conversationRepo;
    late _FakeTutorSessionRepository tutorSessionRepo;

    setUp(() {
      topicRepo = _FakeTopicRepository();
      questionRepo = _FakeQuestionRepository();
      attemptRepo = _FakeAttemptRepository();
      lessonRepo = _FakeLessonRepository();
      sessionRepo = _FakeSessionRepository();
      subjectRepo = _FakeSubjectRepository();
      conversationRepo = _FakeConversationRepository();
      tutorSessionRepo = _FakeTutorSessionRepository();
    });

    test('constructor stores all repository references', () {
      final service = DatabaseService(
        topicRepository: topicRepo,
        questionRepository: questionRepo,
        attemptRepository: attemptRepo,
        lessonRepository: lessonRepo,
        sessionRepository: sessionRepo,
        subjectRepository: subjectRepo,
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      expect(service.topicRepository, topicRepo);
      expect(service.questionRepository, questionRepo);
      expect(service.attemptRepository, attemptRepo);
      expect(service.lessonRepository, lessonRepo);
      expect(service.sessionRepository, sessionRepo);
      expect(service.subjectRepository, subjectRepo);
      expect(service.conversationRepository, conversationRepo);
      expect(service.tutorSessionRepository, tutorSessionRepo);
    });

    test('init calls init on all repositories', () async {
      final service = DatabaseService(
        topicRepository: topicRepo,
        questionRepository: questionRepo,
        attemptRepository: attemptRepo,
        lessonRepository: lessonRepo,
        sessionRepository: sessionRepo,
        subjectRepository: subjectRepo,
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      await service.init();
      expect(topicRepo.initCallCount, 1);
      expect(questionRepo.initCallCount, 1);
      expect(attemptRepo.initCallCount, 1);
      expect(lessonRepo.initCallCount, 1);
      expect(subjectRepo.initCallCount, 1);
      expect(conversationRepo.initCallCount, 1);
      expect(tutorSessionRepo.initCallCount, 1);
    });

    test('init propagates repository error', () async {
      final service = DatabaseService(
        topicRepository: _FailingRepo(),
        questionRepository: questionRepo,
        attemptRepository: attemptRepo,
        lessonRepository: lessonRepo,
        sessionRepository: sessionRepo,
        subjectRepository: subjectRepo,
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      expect(service.init(), throwsA(isA<Exception>()));
    });

    test('init stops at first failure and does not init remaining repos', () async {
      final service = DatabaseService(
        topicRepository: topicRepo,
        questionRepository: _FailingQuestionRepo(),
        attemptRepository: attemptRepo,
        lessonRepository: lessonRepo,
        sessionRepository: sessionRepo,
        subjectRepository: subjectRepo,
        conversationRepository: conversationRepo,
        tutorSessionRepository: tutorSessionRepo,
      );
      try {
        await service.init();
      } catch (e, st) {
        _logger.w('Expected init failure for partial init test: $e', e, st);
      }
      expect(topicRepo.initCallCount, 1);
      expect(attemptRepo.initCallCount, 0);
      expect(lessonRepo.initCallCount, 0);
      expect(subjectRepo.initCallCount, 0);
      expect(conversationRepo.initCallCount, 0);
      expect(tutorSessionRepo.initCallCount, 0);
    });
  });
}
