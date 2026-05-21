import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class _FakeMasteryGraphService extends MasteryGraphService {
  int recordAttemptCallCount = 0;
  String? lastStudentId;
  String? lastTopicId;
  String? lastQuestionId;
  bool? lastIsCorrect;

  _FakeMasteryGraphService() : super();

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) async {
    recordAttemptCallCount++;
    lastStudentId = studentId;
    lastTopicId = topicId;
    lastQuestionId = questionId;
    lastIsCorrect = isCorrect;
    return Result.success(null);
  }
}

class _FakeSpacedRepetitionEngine extends SpacedRepetitionEngine {
  int scheduleReviewCallCount = 0;
  String? lastQuestionId;

  @override
  SM2Result scheduleReview({
    required String questionId,
    required int grade,
    QuestionSRData? currentData,
    DateTime? now,
  }) {
    scheduleReviewCallCount++;
    lastQuestionId = questionId;
    return SM2Result(
      nextReview: DateTime.now().add(const Duration(days: 1)),
      updatedData: QuestionSRData(
        repetitions: 1,
        easeFactor: 2.5,
        previousInterval: const Duration(days: 1),
        lastReview: now,
        reviewLog: [
          ReviewLogEntry(
            questionId: questionId,
            timestamp: now ?? DateTime.now(),
            grade: grade,
            easeFactor: 2.5,
            interval: const Duration(days: 1),
            nextReview: DateTime.now().add(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  @override
  int mapConfidenceToGrade({
    required bool isCorrect,
    required int confidence,
  }) {
    return isCorrect ? 4 : 1;
  }
}

class _FakeAttemptRepository extends AttemptRepository {
  final List<StudentAttempt> attempts = [];

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    attempts.add(attempt);
    return Result.success(null);
  }

  @override
  Future<void> init() async {}
}

class _FakeQuestionMasteryStateRepo extends QuestionMasteryStateRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    return Result.success(QuestionMasteryState(
      studentId: studentId,
      questionId: questionId,
      lastAttempt: DateTime.now(),
    ));
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(
    QuestionMasteryState state,
  ) async {
    return Result.success(null);
  }
}

class _FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    _questions[key] = item;
    return Result.success(null);
  }
}

void main() {
  group('MasteryRecorder', () {
    late _FakeMasteryGraphService fakeMasteryGraph;
    late _FakeSpacedRepetitionEngine fakeEngine;
    late _FakeAttemptRepository fakeAttemptRepo;
    late _FakeQuestionMasteryStateRepo fakeQuestionMasteryRepo;
    late _FakeQuestionRepository fakeQuestionRepo;
    late MasteryRecorder recorder;

    setUp(() {
      fakeMasteryGraph = _FakeMasteryGraphService();
      fakeEngine = _FakeSpacedRepetitionEngine();
      fakeAttemptRepo = _FakeAttemptRepository();
      fakeQuestionMasteryRepo = _FakeQuestionMasteryStateRepo();
      fakeQuestionRepo = _FakeQuestionRepository();

      recorder = MasteryRecorder(
        masteryGraphService: fakeMasteryGraph,
        srEngine: fakeEngine,
        attemptRepo: fakeAttemptRepo,
        questionMasteryRepo: fakeQuestionMasteryRepo,
        questionRepo: fakeQuestionRepo,
      );
    });

    test('recordAttempt returns failure when question not found', () async {
      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'nonexistent',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'test answer',
      );

      expect(result.isFailure, isTrue);
    });

    test('recordAttempt coordinates all three systems', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q1', question);

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'correct answer',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeMasteryGraph.recordAttemptCallCount, 1);
      expect(fakeMasteryGraph.lastQuestionId, 'q1');
      expect(fakeMasteryGraph.lastIsCorrect, isTrue);
      expect(fakeEngine.mapConfidenceToGrade(isCorrect: true, confidence: 4), 4);

      final savedAttempt = fakeAttemptRepo.attempts;
      expect(savedAttempt, hasLength(1));
      expect(savedAttempt.first.isCorrect, isTrue);
      expect(savedAttempt.first.confidence, 4);

      final updatedQuestion = await fakeQuestionRepo.get('q1');
      expect(updatedQuestion.data?.nextReview, isNotNull);
    });

    test('recordAttempt saves incorrect attempt correctly', () async {
      final question = Question(
        id: 'q2',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q2', question);

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q2',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: false,
        timeSpentMs: 3000,
        confidence: 2,
        userAnswer: 'wrong answer',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeMasteryGraph.lastIsCorrect, isFalse);

      final savedAttempt = fakeAttemptRepo.attempts.first;
      expect(savedAttempt.isCorrect, isFalse);
      expect(savedAttempt.confidence, 2);
      expect(savedAttempt.userAnswer, 'wrong answer');
    });
  });

  group('MasteryRecorder - coverage gaps', () {
    late _FakeMasteryGraphSvc fakeMasteryGraph;
    late _FakeSrEngine fakeEngine;
    late _FakeAttemptRepo2 fakeAttemptRepo;
    late _FakeQMasteryStateRepo fakeQMasteryRepo;
    late _FakeQuestionRepo2 fakeQuestionRepo;
    late MasteryRecorder recorder;

    setUp(() {
      fakeMasteryGraph = _FakeMasteryGraphSvc();
      fakeEngine = _FakeSrEngine();
      fakeAttemptRepo = _FakeAttemptRepo2();
      fakeQMasteryRepo = _FakeQMasteryStateRepo();
      fakeQuestionRepo = _FakeQuestionRepo2();
      recorder = MasteryRecorder(
        masteryGraphService: fakeMasteryGraph,
        srEngine: fakeEngine,
        attemptRepo: fakeAttemptRepo,
        questionMasteryRepo: fakeQMasteryRepo,
        questionRepo: fakeQuestionRepo,
      );
    });

    test('recordAttempt continues when mastery graph returns failure',
        () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q1', question);
      fakeMasteryGraph.shouldFail = true;

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'correct',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeAttemptRepo.attempts, hasLength(1));
    });

    test('recordAttempt works when questionMasteryState returns failure',
        () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q1', question);
      fakeQMasteryRepo.shouldFail = true;

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'correct',
      );

      expect(result.isSuccess, isTrue);
    });

    test('recordAttempt with custom timestamp and confidence values', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        srDataJson: '{"r":1,"ef":2.5,"pi":86400000,"lr":1700000000000}',
      );
      await fakeQuestionRepo.save('q1', question);

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: false,
        timeSpentMs: 3000,
        confidence: 1,
        userAnswer: 'wrong',
        timestamp: DateTime(2025, 1, 1),
      );

      expect(result.isSuccess, isTrue);
      expect(fakeAttemptRepo.attempts.first.isCorrect, isFalse);
      expect(fakeAttemptRepo.attempts.first.confidence, 1);
    });

    test('recordAttempt updates question mastery state when data exists',
        () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q1', question);

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'correct',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeQMasteryRepo.lastUpdatedState, isNotNull);
      expect(fakeQMasteryRepo.lastUpdatedState!.questionId, 'q1');
    });

    test('recordAttempt serializes srData correctly', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q1', question);

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'correct',
      );

      expect(result.isSuccess, isTrue);
      final updated = await fakeQuestionRepo.get('q1');
      expect(updated.data!.srDataJson, isNotNull);
      expect(updated.data!.srDataJson, contains('"r"'));
      expect(updated.data!.srDataJson, contains('"ef"'));
    });

    test('recordAttempt uses provided timestamp', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await fakeQuestionRepo.save('q1', question);
      final customTime = DateTime(2025, 6, 15);

      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        topicId: 't1',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 4,
        userAnswer: 'correct',
        timestamp: customTime,
      );

      expect(result.isSuccess, isTrue);
      expect(fakeAttemptRepo.attempts.first.timestamp, customTime);
    });
  });
}

class _FakeMasteryGraphSvc extends MasteryGraphService {
  bool shouldFail = false;

  _FakeMasteryGraphSvc() : super();

  @override
  Future<Result<void>> recordAttempt({
    required String studentId,
    required String topicId,
    required String questionId,
    required bool isCorrect,
    required int confidence,
    required int timeSpentMs,
    String? subtopicId,
  }) async {
    if (shouldFail) return Result.failure('Mastery graph failure');
    return Result.success(null);
  }
}

class _FakeSrEngine extends SpacedRepetitionEngine {
  @override
  SM2Result scheduleReview({
    required String questionId,
    required int grade,
    QuestionSRData? currentData,
    DateTime? now,
  }) {
    final reviewTime = now ?? DateTime.now();
    return SM2Result(
      nextReview: reviewTime.add(const Duration(days: 1)),
      updatedData: QuestionSRData(
        repetitions: 1,
        easeFactor: 2.5,
        previousInterval: const Duration(days: 1),
        lastReview: reviewTime,
        reviewLog: [
          ReviewLogEntry(
            questionId: questionId,
            timestamp: reviewTime,
            grade: grade,
            easeFactor: 2.5,
            interval: const Duration(days: 1),
            nextReview: reviewTime.add(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  @override
  int mapConfidenceToGrade({
    required bool isCorrect,
    required int confidence,
  }) {
    return isCorrect ? 4 : 1;
  }
}

class _FakeAttemptRepo2 extends AttemptRepository {
  final List<StudentAttempt> attempts = [];

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success([]);

  @override
  Future<Result<StudentAttempt?>> get(String key) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async =>
      Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    attempts.add(attempt);
    return Result.success(null);
  }
}

class _FakeQMasteryStateRepo extends QuestionMasteryStateRepository {
  bool shouldFail = false;
  QuestionMasteryState? lastUpdatedState;

  @override
  Future<void> init() async {}

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    if (shouldFail) return Result.failure('QM state failure');
    return Result.success(QuestionMasteryState(
      studentId: studentId,
      questionId: questionId,
      lastAttempt: DateTime.now(),
    ));
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(
    QuestionMasteryState state,
  ) async {
    lastUpdatedState = state;
    return Result.success(null);
  }
}

class _FakeQuestionRepo2 extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success([]);

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    _questions[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);
}
