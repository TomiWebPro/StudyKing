import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/focus_mode/services/focus_practice_service.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _storage = {};
  bool throwOnGetAll = false;

  void seed(Question question) => _storage[question.id] = question;

  @override
  Future<Result<List<Question>>> getAll() async {
    if (throwOnGetAll) return Result.failure('Failed to get questions');
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    return Result.success(
      _storage.values.where((q) => q.subjectId == subjectId).toList(),
    );
  }
}

class _FakeSessionRepository extends SessionRepository {
  final Map<String, Session> _storage = {};

  _FakeSessionRepository() : super();

  @override
  Future<Result<void>> save(String key, Session item) async {
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<Session?>> get(String key) async {
    return Result.success(_storage[key]);
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  final Map<String, StudentAttempt> _storage = {};
  bool throwOnGetByStudent = false;

  void seed(StudentAttempt attempt) => _storage[attempt.id] = attempt;

  @override
  Future<Result<List<StudentAttempt>>> getByStudent(String studentId) async {
    if (throwOnGetByStudent) throw Exception('Failed to get attempts');
    return Result.success(
      _storage.values.where((a) => a.studentId == studentId).toList(),
    );
  }
}

DatabaseService _databaseWith(
    {required _FakeQuestionRepository questionRepository}) {
  return DatabaseService(
    topicRepository: TopicRepository(),
    questionRepository: questionRepository,
    attemptRepository: AttemptRepository(),
    lessonRepository: LessonRepository(),
    sessionRepository: SessionRepository(),
    subjectRepository: SubjectRepository(),
    conversationRepository: ConversationRepository(),
    tutorSessionRepository: TutorSessionRepository(),
  );
}

final _now = DateTime(2026, 5, 18);

Question _q({
  required String id,
  required String text,
  required QuestionType type,
  int difficulty = 1,
  required String subjectId,
  required String topicId,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('FocusPracticeService', () {
    late _FakeQuestionRepository fakeQuestionRepo;
    late _FakeSessionRepository fakeSessionRepo;
    late _FakeAttemptRepository fakeAttemptRepo;
    late FocusPracticeService service;

    setUp(() {
      fakeQuestionRepo = _FakeQuestionRepository();
      fakeSessionRepo = _FakeSessionRepository();
      fakeAttemptRepo = _FakeAttemptRepository();
      service = FocusPracticeService(
        database: _databaseWith(questionRepository: fakeQuestionRepo),
        sessionRepository: fakeSessionRepo,
        attemptRepository: fakeAttemptRepo,
      );
    });

    group('getDueQuestions', () {
      test('returns unattempted questions when no attempts exist', () async {
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Question 1', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Question 2', type: QuestionType.typedAnswer,
          difficulty: 2, subjectId: 'sub-1', topicId: 't-1',
        ));

        final questions = await service.getDueQuestions(studentId: 'student-1');

        expect(questions.length, 2);
        expect(questions[0].id, 'q1');
        expect(questions[1].id, 'q2');
      });

      test('prioritizes unattempted questions over attempted ones', () async {
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Unattempted', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Attempted', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
        ));
        fakeAttemptRepo.seed(StudentAttempt(
          id: 'a1', studentId: 'student-1', questionId: 'q2',
          subjectId: 'sub-1', timestamp: DateTime.now(),
        ));

        final questions = await service.getDueQuestions(studentId: 'student-1');

        expect(questions[0].id, 'q1');
      });

      test('filters by subject when subjectIds provided', () async {
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Math Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'math', topicId: 't-1',
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Physics Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'physics', topicId: 't-1',
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q3', text: 'Math Q2', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'math', topicId: 't-2',
        ));

        final questions = await service.getDueQuestions(
          studentId: 'student-1',
          subjectIds: ['math'],
        );

        expect(questions.length, 2);
        expect(questions.every((q) => q.subjectId == 'math'), isTrue);
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          fakeQuestionRepo.seed(_q(
            id: 'q$i', text: 'Q$i', type: QuestionType.typedAnswer,
            difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
          ));
        }

        final questions = await service.getDueQuestions(
          studentId: 'student-1',
          limit: 3,
        );

        expect(questions.length, 3);
      });

      test('returns empty list when repository throws', () async {
        fakeQuestionRepo.throwOnGetAll = true;

        final questions = await service.getDueQuestions(studentId: 'student-1');

        expect(questions, isEmpty);
      });

      test('returns empty list when attempt repo throws', () async {
        fakeAttemptRepo.throwOnGetByStudent = true;
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Q1', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
        ));

        final questions = await service.getDueQuestions(studentId: 'student-1');

        expect(questions, isEmpty);
      });
    });

    group('startPracticeSession', () {
      test('creates a focus session', () async {
        final session = await service.startPracticeSession(
          studentId: 'student-1',
          durationMinutes: 25,
        );

        expect(session.id, isNotEmpty);
        expect(session.studentId, 'student-1');
        expect(session.type, SessionType.focus);
        expect(session.plannedDurationMinutes, 25);
      });

      test('persists the session in repository', () async {
        final session = await service.startPracticeSession(
          studentId: 'student-1',
          subjectIds: ['sub-1'],
          durationMinutes: 30,
        );

        final saved = await fakeSessionRepo.get(session.id);
        expect(saved.isSuccess, isTrue);
        expect(saved.data, isNotNull);
        expect(saved.data!.subjectId, 'sub-1');
      });

      test('creates session with default duration when not specified', () async {
        final session = await service.startPracticeSession(
          studentId: 'student-1',
        );

        expect(session.plannedDurationMinutes, 25);
      });
    });

    group('endPracticeSession', () {
      test('updates session with completion status', () async {
        final session = await service.startPracticeSession(
          studentId: 'student-1',
        );

        await service.endPracticeSession(
          session,
          questionsAnswered: 10,
          correctAnswers: 7,
        );

        final saved = await fakeSessionRepo.get(session.id);
        expect(saved.isSuccess, isTrue);
        expect(saved.data!.completed, isTrue);
        expect(saved.data!.status, SessionStatus.completed);
        expect(saved.data!.endTime, isNotNull);
        expect(saved.data!.questionsAnswered, 10);
        expect(saved.data!.correctAnswers, 7);
      });
    });
  });
}
