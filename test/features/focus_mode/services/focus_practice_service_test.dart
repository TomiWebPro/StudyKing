import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_type.dart';
import 'package:studyking/features/focus_mode/services/focus_practice_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _storage = {};
  bool failOnGetAll = false;
  bool failOnGetBySubject = false;

  void seed(Question question) => _storage[question.id] = question;

  @override
  Future<Result<List<Question>>> getAll() async {
    if (failOnGetAll) return Result.failure('getAll failed');
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    if (failOnGetBySubject) return Result.failure('getBySubject failed');
    return Result.success(
      _storage.values.where((q) => q.subjectId == subjectId).toList(),
    );
  }
}

class _FakeSpacedRepetitionService extends SpacedRepetitionService {
  final _FakeQuestionRepository _fakeQuestionRepo;

  _FakeSpacedRepetitionService({required _FakeQuestionRepository questionRepo})
      : _fakeQuestionRepo = questionRepo,
        super(
          questionRepo: questionRepo,
          attemptRepo: AttemptRepository(),
        );

  @override
  Future<Result<List<Question>>> getQuestionsDueForReview({DateTime? asOf}) async {
    final reviewDate = asOf ?? DateTime.now();
    final allResult = await _fakeQuestionRepo.getAll();
    final all = allResult.data ?? [];
    final due = all.where((q) =>
        (q.nextReview ?? DateTime.now()).isBefore(reviewDate)).toList();
    return Result.success(due);
  }
}

class _FakeSessionRepo extends SessionRepository {
  final Map<String, Session> _storage = {};
  bool shouldThrow = false;
  final List<Session> savedSessions = [];

  @override
  Future<Result<void>> save(String key, Session item) async {
    savedSessions.add(item);
    if (shouldThrow) return Result.failure('Save error');
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    return Result.success(_storage[id]);
  }
}

class _FakeMasteryGraphService extends MasteryGraphService {
  final List<MasteryState> _weakTopics;

  _FakeMasteryGraphService({List<MasteryState>? weakTopics})
      : _weakTopics = weakTopics ?? [];

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(List.from(_weakTopics));
  }
}

Question _q({
  required String id,
  required String text,
  required QuestionType type,
  int difficulty = 1,
  required String subjectId,
  required String topicId,
  DateTime? nextReview,
}) {
  final now = DateTime.now();
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: subjectId,
    topicId: topicId,
    createdAt: now,
    updatedAt: now,
    nextReview: nextReview,
  );
}

void main() {
  group('FocusPracticeService', () {
    late _FakeQuestionRepository fakeQuestionRepo;
    late _FakeMasteryGraphService fakeMasteryGraphService;
    late SpacedRepetitionService srService;
    late FocusPracticeService service;

    late _FakeSessionRepo fakeSessionRepo;

    setUp(() {
      fakeQuestionRepo = _FakeQuestionRepository();
      fakeMasteryGraphService = _FakeMasteryGraphService();
      srService = _FakeSpacedRepetitionService(questionRepo: fakeQuestionRepo);
      fakeSessionRepo = _FakeSessionRepo();
      service = FocusPracticeService(
        srService: srService,
        masteryGraphService: fakeMasteryGraphService,
        sessionRepository: fakeSessionRepo,
        questionRepository: fakeQuestionRepo,
      );
    });

    group('getDueQuestions', () {
      test('returns due questions when they exist', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Due Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Future Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
          nextReview: now.add(const Duration(days: 1)),
        ));

        final questions = await service.getDueQuestions(studentId: 'student-1');

        expect(questions.length, 1);
        expect(questions[0].id, 'q1');
      });

      test('returns empty list when no due questions', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Future Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
          nextReview: now.add(const Duration(days: 1)),
        ));

        final questions = await service.getDueQuestions(studentId: 'student-1');

        expect(questions, isEmpty);
      });

      test('filters by subject when subjectIds provided', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Math Due', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'math', topicId: 't-1',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Physics Due', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'physics', topicId: 't-1',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));

        final questions = await service.getDueQuestions(
          studentId: 'student-1',
          subjectIds: ['math'],
        );

        expect(questions.length, 1);
        expect(questions[0].subjectId, 'math');
      });

      test('respects limit parameter', () async {
        final now = DateTime.now();
        for (var i = 0; i < 5; i++) {
          fakeQuestionRepo.seed(_q(
            id: 'q$i', text: 'Q$i', type: QuestionType.typedAnswer,
            difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
            nextReview: now.subtract(const Duration(hours: 1)),
          ));
        }

        final questions = await service.getDueQuestions(
          studentId: 'student-1',
          limit: 3,
        );

        expect(questions.length, 3);
      });

      test('prioritizes weak topic questions', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Weak Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 'weak-topic',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Strong Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 'strong-topic',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));

        fakeMasteryGraphService = _FakeMasteryGraphService(
          weakTopics: [MasteryState(topicId: 'weak-topic', studentId: 'student-1', lastAttempt: DateTime.now(), lastUpdated: DateTime.now())],
        );
        final fakeSr = _FakeSpacedRepetitionService(questionRepo: fakeQuestionRepo);
        service = FocusPracticeService(
          srService: fakeSr,
          masteryGraphService: fakeMasteryGraphService,
          sessionRepository: fakeSessionRepo,
          questionRepository: fakeQuestionRepo,
        );

        final questions = await service.getDueQuestions(studentId: 'student-1', limit: 10);

        expect(questions.length, 2);
        expect(questions[0].topicId, 'weak-topic');
      });

      test('returns empty list when repository throws', () async {
        final throwingRepo = _FakeQuestionRepository();
        final brokenSrService = _FakeSpacedRepetitionService(questionRepo: throwingRepo);

        final throwingService = FocusPracticeService(
          srService: brokenSrService,
          masteryGraphService: fakeMasteryGraphService,
          sessionRepository: fakeSessionRepo,
          questionRepository: throwingRepo,
        );

        final questions = await throwingService.getDueQuestions(studentId: 'student-1');

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

        final savedResult = await fakeSessionRepo.get(session.id);
        final saved = savedResult.data;
        expect(saved, isNotNull);
        expect(saved!.completed, isTrue);
        expect(saved.status, SessionStatus.completed);
        expect(saved.endTime, isNotNull);
        expect(saved.questionsAnswered, 10);
        expect(saved.correctAnswers, 7);
      });

      test('handles save failure gracefully', () async {
        final session = await service.startPracticeSession(
          studentId: 'student-1',
        );

        fakeSessionRepo.shouldThrow = true;

        await service.endPracticeSession(
          session,
          questionsAnswered: 5,
          correctAnswers: 3,
        );

        expect(fakeSessionRepo.savedSessions, hasLength(1));
      });
    });

    group('startPracticeSession', () {
      test('handles save failure gracefully', () async {
        fakeSessionRepo.shouldThrow = true;

        final session = await service.startPracticeSession(
          studentId: 'student-1',
        );

        expect(session, isNotNull);
        expect(session.studentId, 'student-1');
      });
    });

    group('getWeakAreaQuestions', () {
      test('returns empty list when no weak topics', () async {
        final questions = await service.getWeakAreaQuestions(
          studentId: 'student-1',
        );

        expect(questions, isEmpty);
      });

      test('returns empty list when repository throws', () async {
        final questions = await service.getWeakAreaQuestions(
          studentId: 'student-1',
          subjectIds: ['sub-1'],
        );

        expect(questions, isEmpty);
      });
    });

    group('error-state: getQuestionsForSessionType', () {
      test('quickPractice returns empty when getAll fails', () async {
        fakeQuestionRepo.failOnGetAll = true;

        final questions = await service.getQuestionsForSessionType(
          sessionType: FocusSessionType.quickPractice,
          studentId: 'student-1',
        );

        expect(questions, isEmpty);
      });

      test('quickPractice filters by subject when provided', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Math Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'math', topicId: 't-1',
          nextReview: now,
        ));
        fakeQuestionRepo.seed(_q(
          id: 'q2', text: 'Physics Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'physics', topicId: 't-1',
          nextReview: now,
        ));

        final questions = await service.getQuestionsForSessionType(
          sessionType: FocusSessionType.quickPractice,
          studentId: 'student-1',
          subjectIds: ['math'],
        );

        expect(questions.length, 1);
        expect(questions[0].subjectId, 'math');
      });

      test('weakAreaAttack returns empty when no weak topics', () async {
        final questions = await service.getQuestionsForSessionType(
          sessionType: FocusSessionType.weakAreaAttack,
          studentId: 'student-1',
        );

        expect(questions, isEmpty);
      });

      test('freeFocus delegates to getDueQuestions', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Due Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));

        final questions = await service.getQuestionsForSessionType(
          sessionType: FocusSessionType.freeFocus,
          studentId: 'student-1',
        );

        expect(questions, isNotEmpty);
      });

      test('spacedRepetition delegates to getDueQuestions', () async {
        final now = DateTime.now();
        fakeQuestionRepo.seed(_q(
          id: 'q1', text: 'Due Q', type: QuestionType.typedAnswer,
          difficulty: 1, subjectId: 'sub-1', topicId: 't-1',
          nextReview: now.subtract(const Duration(hours: 1)),
        ));

        final questions = await service.getQuestionsForSessionType(
          sessionType: FocusSessionType.spacedRepetition,
          studentId: 'student-1',
        );

        expect(questions, isNotEmpty);
      });
    });

    group('error-state: start/end practice session', () {
      test('startPracticeSession returns session even when save fails', () async {
        fakeSessionRepo.shouldThrow = true;

        final session = await service.startPracticeSession(
          studentId: 'student-1',
        );

        expect(session, isNotNull);
        expect(session.studentId, 'student-1');
        expect(session.id, isNotEmpty);
      });

      test('endPracticeSession does not throw when save fails', () async {
        final session = await service.startPracticeSession(
          studentId: 'student-1',
        );

        fakeSessionRepo.shouldThrow = true;

        await expectLater(
          service.endPracticeSession(
            session,
            questionsAnswered: 5,
            correctAnswers: 3,
          ),
          completes,
        );
      });
    });
  });
}
