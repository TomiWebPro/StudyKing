import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
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
}
