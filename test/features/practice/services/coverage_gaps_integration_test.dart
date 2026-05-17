import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';

import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/services/difficulty_adapter.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/practice/services/practice_session_service.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/questions/data/models/markscheme_model.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/utils/clock.dart';

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student';
  @override
  void setStudentId(String id) {}
  @override
  Future<void> init() async {}
}

// ============================================================================
// FAKES
// ============================================================================

class _ThrowingBox<T> implements Box<T> {
  @override
  Iterable<T> get values => throw Exception('Box values error');

  @override
  bool get isOpen => true;

  @override
  String get name => 'throwing';

  @override
  bool get isNotEmpty => false;

  @override
  bool get isEmpty => true;

  @override
  int get length => 0;

  @override
  T? get(dynamic key, {T? defaultValue}) => null;

  @override
  bool containsKey(dynamic key) => false;

  @override
  Future<void> put(dynamic key, T value) async =>
      throw Exception('Box put error');

  @override
  Future<void> delete(dynamic key) async =>
      throw Exception('Box delete error');

  @override
  Future<int> clear() async => 0;

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuestionBox implements Box<Question> {
  final Map<String, Question> _storage = {};

  @override
  Iterable<Question> get values => _storage.values;

  @override
  Question? get(dynamic key, {Question? defaultValue}) =>
      _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, Question value) async {
    _storage[key.toString()] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key.toString());
  }

  @override
  Future<int> clear() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }

  @override
  int get length => _storage.length;

  @override
  bool get isOpen => true;

  @override
  String get name => 'questions';

  @override
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  bool get isEmpty => _storage.isEmpty;

  @override
  bool containsKey(dynamic key) => _storage.containsKey(key.toString());

  @override
  Stream<BoxEvent> watch({dynamic key}) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingQuestionRepository extends QuestionRepository {
  final _FakeQuestionBox fakeBox;

  _ThrowingQuestionRepository(this.fakeBox);

  @override
  Future<void> init() async {}

  @override
  Box<Question> get box => fakeBox;

  @override
  Future<Result<Question?>> get(String id) async {
    throw Exception('Repo get error');
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    throw Exception('Repo save error');
  }

  @override
  Future<Result<void>> delete(String key) async {
    throw Exception('Repo delete error');
  }

  @override
  Future<Result<void>> create(Question question) async {
    return Result.failure('create error');
  }
}

class _FakeAttemptRepo extends AttemptRepository {
  final Map<String, StudentAttempt> _storage = {};
  bool _throwOnGet = false;

  void setThrowOnGet() {
    _throwOnGet = true;
  }

  @override
  Future<void> init() async {}

  @override
  Future<Result<StudentAttempt?>> get(String id) async {
    if (_throwOnGet) throw Exception('Attempt get error');
    return Result.success(_storage[id]);
  }
}

class _FakeClock extends Clock {
  final DateTime fixedNow;

  _FakeClock(this.fixedNow);

  @override
  DateTime now() => fixedNow;
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  // ==========================================================================
  // 1. SPACED_REPETITION_SERVICE additional coverage
  // ==========================================================================
  group('SpacedRepetitionService - coverage gaps', () {
    late _FakeQuestionBox questionBox;
    late _FakeAttemptRepo attemptRepo;

    setUp(() {
      questionBox = _FakeQuestionBox();
      attemptRepo = _FakeAttemptRepo();
    });

    // _masteryLevelToGrade: 0.95 -> grade 5 (already tested indirectly via existing test)
    // Additional mastery levels:

    test('updateNextReviewDate mastery 0.8 maps to grade 4', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.updateNextReviewDate('q1', 0.8);
      expect(result.isSuccess, isTrue);
      final updated = questionBox.get('q1')!;
      expect(updated.nextReview, isNotNull);
      // grade 4: EF = 2.5 + (0.1 - (5-4)*(0.08 + (5-4)*0.02)) = 2.5 + (0.1 - 0.1) = 2.5
      final srData = jsonDecode(updated.srDataJson!);
      expect((srData['ef'] as num).toDouble(), closeTo(2.5, 0.01));
    });

    test('updateNextReviewDate mastery 0.6 maps to grade 3', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.updateNextReviewDate('q1', 0.6);
      expect(result.isSuccess, isTrue);
      // grade 3: EF = 2.5 + (0.1 - (5-3)*(0.08 + (5-3)*0.02)) = 2.5 + (0.1 - 2*0.12) = 2.5 - 0.14 = 2.36
      final updated = questionBox.get('q1')!;
      final srData = jsonDecode(updated.srDataJson!);
      expect((srData['ef'] as num).toDouble(), closeTo(2.36, 0.01));
    });

    test('updateNextReviewDate mastery 0.4 maps to grade 2 (failing)', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.updateNextReviewDate('q1', 0.4);
      expect(result.isSuccess, isTrue);
      final updated = questionBox.get('q1')!;
      // grade 2 resets repetitions to 0, interval = 1 day
      expect(updated.nextReview, isNotNull);
      // grade 2: EF decrease -> EF = 2.5 + (0.1 - (5-2)*(0.08 + (5-2)*0.02))
      // = 2.5 + (0.1 - 3*0.14) = 2.5 - 0.32 = 2.18
      final srData = jsonDecode(updated.srDataJson!);
      expect((srData['r'] as int), 0);
    });

    test('updateNextReviewDate mastery 0.2 maps to grade 1 (failing)', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.updateNextReviewDate('q1', 0.2);
      expect(result.isSuccess, isTrue);
      final updated = questionBox.get('q1')!;
      final srData = jsonDecode(updated.srDataJson!);
      expect((srData['r'] as int), 0);
    });

    test('updateNextReviewDate handles malformed srDataJson gracefully',
        () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1', srDataJson: 'invalid{json'));

      final result = await service.updateNextReviewDate('q1', 0.9);
      expect(result.isSuccess, isTrue);
      final updated = questionBox.get('q1')!;
      expect(updated.srDataJson, isNotNull);
      // Should have fallen back to default SR data
      expect(updated.srDataJson, contains('"ef":'));
    });

    test('updateNextReviewDate handles null srDataJson gracefully', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1', srDataJson: null));

      final result = await service.updateNextReviewDate('q1', 0.9);
      expect(result.isSuccess, isTrue);
    });

    test('updateNextReviewDate handles empty srDataJson gracefully', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1', srDataJson: ''));

      final result = await service.updateNextReviewDate('q1', 0.9);
      expect(result.isSuccess, isTrue);
    });

    test('updateNextReviewDate throws exception during save returns failure',
        () async {
      final throwingRepo = _ThrowingQuestionRepository(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.updateNextReviewDate('q1', 0.9);
      expect(result.isFailure, isTrue);
    });

    test('getQuestionsDue exception path returns failure', () async {
      final throwingBox = _ThrowingBox<Question>();
      final throwingRepo = _FakeThrowingBoxRepo(throwingBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );

      final result = await service.getQuestionsDue();
      expect(result.isFailure, isTrue);
    });

    test('getQuestionDueTimes exception returns failure', () async {
      attemptRepo.setThrowOnGet();
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );

      final result = await service.getQuestionDueTimes('q1');
      expect(result.isFailure, isTrue);
    });

    test('getPracticeQuestions exception returns failure', () async {
      final throwingBox = _ThrowingBox<Question>();
      final throwingRepo = _FakeThrowingBoxRepo(throwingBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );

      final result = await service.getPracticeQuestions('sub1');
      expect(result.isFailure, isTrue);
    });

    test('getTopicTimeDue exception returns failure', () async {
      final throwingBox = _ThrowingBox<Question>();
      final throwingRepo = _FakeThrowingBoxRepo(throwingBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );

      final result = await service.getTopicTimeDue('t1');
      expect(result.isFailure, isTrue);
    });

    test('removeDueQuestions exception returns failure', () async {
      final throwingRepo = _ThrowingQuestionRepository(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.removeDueQuestions('q1');
      expect(result.isFailure, isTrue);
    });

    test('getSubjectDueCount exception returns failure', () async {
      final throwingBox = _ThrowingBox<Question>();
      final throwingRepo = _FakeThrowingBoxRepo(throwingBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );

      final result = await service.getSubjectDueCount('sub1');
      expect(result.isFailure, isTrue);
    });
  });

  // ==========================================================================
  // 2. SPACED_REPETITION_ENGINE additional coverage
  // ==========================================================================
  group('SpacedRepetitionEngine - coverage gaps', () {
    late SpacedRepetitionEngine engine;

    setUp(() {
      engine = SpacedRepetitionEngine();
    });

    group('mapConfidenceToGrade complete coverage', () {
      test('correct confidence 2 maps to grade 3', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 2), 3);
      });

      test('correct confidence 4 maps to grade 5', () {
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 4), 5);
      });

      test('incorrect confidence 2 maps to grade 0', () {
        expect(
            engine.mapConfidenceToGrade(isCorrect: false, confidence: 2), 0);
      });

      test('incorrect confidence 4 maps to grade 2', () {
        expect(
            engine.mapConfidenceToGrade(isCorrect: false, confidence: 4), 2);
      });

      test('default confidence returns fallback grade', () {
        // For correct with out-of-range confidence, default is 4
        expect(engine.mapConfidenceToGrade(isCorrect: true, confidence: 99), 4);
        // For incorrect with confidence <= 2, grade is 0 (not the default branch)
        expect(
            engine.mapConfidenceToGrade(isCorrect: false, confidence: 0), 0);
      });
    });

    group('QuestionSRData copyWith', () {
      test('copyWith with clearPreviousInterval clears the field', () {
        const data = QuestionSRData(
          previousInterval: Duration(days: 6),
          lastReview: null,
        );
        final updated = data.copyWith(clearPreviousInterval: true);
        expect(updated.previousInterval, isNull);
      });

      test('copyWith with explicit previousInterval overrides', () {
        const data = QuestionSRData(previousInterval: Duration(days: 6));
        final updated =
            data.copyWith(previousInterval: const Duration(days: 10));
        expect(updated.previousInterval, const Duration(days: 10));
      });

      test('copyWith with null previousInterval keeps original', () {
        const data = QuestionSRData(previousInterval: Duration(days: 6));
        final updated = data.copyWith();
        expect(updated.previousInterval, const Duration(days: 6));
      });

      test('copyWith reviewLog replacement', () {
        const data = QuestionSRData(reviewLog: []);
        final entry = ReviewLogEntry(
          questionId: 'q1',
          timestamp: DateTime(2026, 1, 1),
          grade: 4,
          easeFactor: 2.5,
          interval: const Duration(days: 1),
          nextReview: DateTime(2026, 1, 2),
        );
        final updated = data.copyWith(reviewLog: [entry]);
        expect(updated.reviewLog, hasLength(1));
        expect(updated.reviewLog.first.grade, 4);
      });
    });

    group('computeRecallProbability edges', () {
      test('returns 1.0 when interval is zero', () {
        final data = QuestionSRData(
          lastReview: DateTime.now().subtract(const Duration(days: 30)),
          previousInterval: Duration.zero,
        );
        expect(engine.computeRecallProbability(data: data), 1.0);
      });

      test('returns 1.0 when lastReview is null', () {
        const data = QuestionSRData(previousInterval: Duration(days: 7));
        expect(engine.computeRecallProbability(data: data), 1.0);
      });

      test('returns 1.0 when previousInterval is null', () {
        final data = QuestionSRData(lastReview: DateTime.now());
        expect(engine.computeRecallProbability(data: data), 1.0);
      });
    });

    group('scheduleReview edge cases', () {
      test('handles null currentData by using defaults', () {
        final result = engine.scheduleReview(questionId: 'q1', grade: 4);
        expect(result.updatedData.repetitions, 1);
        expect(result.updatedData.easeFactor, closeTo(2.5, 0.01));
      });

      test('review log accumulates across calls', () {
        final data = QuestionSRData(
          repetitions: 1,
          easeFactor: 2.5,
          previousInterval: const Duration(days: 1),
          reviewLog: [
            ReviewLogEntry(
              questionId: 'q1',
              timestamp: DateTime(2026, 1, 1),
              grade: 4,
              easeFactor: 2.5,
              interval: const Duration(days: 1),
              nextReview: DateTime(2026, 1, 2),
            ),
          ],
        );
        final result = engine.scheduleReview(
          questionId: 'q1',
          grade: 4,
          currentData: data,
        );
        expect(result.updatedData.reviewLog, hasLength(2));
      });
    });

    group('migrateFromLegacy branch coverage', () {
      test('legacy interval 3-7 days sets repetitions to max(2, ~attempts/2)',
          () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 4));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.9,
          now: now,
        );
        expect(result.updatedData.repetitions,
            greaterThanOrEqualTo(2));
        expect(result.updatedData.easeFactor, 2.2);
      });

      test('legacy interval 1-3 days sets repetitions to max(1, ~attempts/3)',
          () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 2));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 6,
          accuracy: 0.9,
          now: now,
        );
        expect(result.updatedData.repetitions,
            greaterThanOrEqualTo(1));
        expect(result.updatedData.easeFactor, 2.0);
      });

      test('legacy interval < 1 day resets to 0', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(hours: 12));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 10,
          accuracy: 0.9,
          now: now,
        );
        expect(result.updatedData.repetitions, 0);
      });
    });
  });

  // ==========================================================================
  // 3. MASTERY_RECORDER additional coverage
  // ==========================================================================
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

  // ==========================================================================
  // 4. EXAM_SESSION_SERVICE additional coverage
  // ==========================================================================
  group('ExamSessionService - coverage gaps', () {
    late ExamSessionService service;
    late _FakeSessionRepo sessionRepo;

    setUp(() {
      sessionRepo = _FakeSessionRepo();
      service = ExamSessionService(
        sessionRepo: sessionRepo,
        studentIdService: _FakeStudentIdService(),
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('isTimeUp', () {
      test('returns true when remaining is zero', () {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
        );
        service.startExam(config);
        service.cancelExam(); // sets remaining to zero
        expect(service.isTimeUp(), isTrue);
      });

      test('returns false when time remains', () {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
        );
        service.startExam(config);
        expect(service.isTimeUp(), isFalse);
        service.cancelExam();
      });
    });

    group('ExamResult edge cases', () {
      test('accuracy returns 0 for all skipped questions', () {
        final result = ExamResult(
          config: const ExamConfig(
              durationMinutes: 30, questionCount: 3, subjectId: 'sub1'),
          questionResults: [
            ExamQuestionResult(
              question: _createQ(id: 'q1'),
              isCorrect: false,
              timeSpentMs: 0,
              wasSkipped: true,
            ),
            ExamQuestionResult(
              question: _createQ(id: 'q2'),
              isCorrect: false,
              timeSpentMs: 0,
              wasSkipped: true,
            ),
          ],
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 1),
        );
        expect(result.accuracy, 0.0);
        expect(result.totalSkipped, 2);
      });

      test('accuracy returns 0 for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(
              durationMinutes: 30, questionCount: 0, subjectId: 'sub1'),
          questionResults: [],
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 1),
        );
        expect(result.accuracy, 0.0);
      });

      test('averageTimePerQuestionMs returns 0 for empty results', () {
        final result = ExamResult(
          config: const ExamConfig(
              durationMinutes: 30, questionCount: 0, subjectId: 'sub1'),
          questionResults: [],
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 1),
        );
        expect(result.averageTimePerQuestionMs, 0.0);
      });

      test('totalIncorrect excludes skipped questions', () {
        final result = ExamResult(
          config: const ExamConfig(
              durationMinutes: 30, questionCount: 3, subjectId: 'sub1'),
          questionResults: [
            ExamQuestionResult(
              question: _createQ(id: 'q1'),
              isCorrect: true,
              timeSpentMs: 1000,
            ),
            ExamQuestionResult(
              question: _createQ(id: 'q2'),
              isCorrect: false,
              timeSpentMs: 0,
              wasSkipped: true,
            ),
            ExamQuestionResult(
              question: _createQ(id: 'q3'),
              isCorrect: false,
              timeSpentMs: 1000,
            ),
          ],
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 1),
        );
        expect(result.totalIncorrect, 1);
        expect(result.totalSkipped, 1);
      });

      test('topicBreakdown skips questions that were skipped', () {
        final result = ExamResult(
          config: const ExamConfig(
              durationMinutes: 30, questionCount: 2, subjectId: 'sub1'),
          questionResults: [
            ExamQuestionResult(
              question: _createQ(id: 'q1', topicId: 't1'),
              isCorrect: true,
              timeSpentMs: 1000,
            ),
            ExamQuestionResult(
              question: _createQ(id: 'q2', topicId: 't1'),
              isCorrect: false,
              timeSpentMs: 0,
              wasSkipped: true,
            ),
          ],
          startTime: DateTime(2026, 1, 1),
          endTime: DateTime(2026, 1, 1),
        );
        expect(result.topicBreakdown['t1'], 1.0);
      });
    });

    group('ExamSessionService lifecycle', () {
      test('finishExam with autoSubmitted sets correct tags', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 1,
          subjectId: 'sub1',
        );
        service.startExam(config);

        await service.finishExam(
          config: config,
          questionResults: [
            ExamQuestionResult(
                question: _createQ(id: 'q1'),
                isCorrect: true,
                timeSpentMs: 1000),
          ],
          autoSubmitted: true,
        );

        expect(sessionRepo.sessions.first.tags.contains('auto_submit:true'),
            isTrue);
      });

      test('finishExam without autoSubmitted sets correct tags', () async {
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 1,
          subjectId: 'sub1',
        );
        service.startExam(config);

        await service.finishExam(
          config: config,
          questionResults: [
            ExamQuestionResult(
                question: _createQ(id: 'q1'),
                isCorrect: true,
                timeSpentMs: 1000),
          ],
        );

        expect(sessionRepo.sessions.first.tags.contains('auto_submit:false'),
            isTrue);
      });

      test('dispose cancels timer and disposes notifiers', () {
        final localService = ExamSessionService(
          sessionRepo: sessionRepo,
          studentIdService: _FakeStudentIdService(),
        );
        final config = const ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
        );
        localService.startExam(config);

        localService.cancelExam();
        localService.dispose();
        // Verify no crash on dispose
      });

      test('ExamSessionService.dispose is safe to call once', () {
        final localService = ExamSessionService(
          sessionRepo: sessionRepo,
          studentIdService: _FakeStudentIdService(),
        );
        localService.dispose();
        // should not throw
      });
    });

    group('ExamConfig', () {
      test('ExamConfig stores all fields correctly', () {
        final config = const ExamConfig(
          durationMinutes: 60,
          questionCount: 10,
          easyCount: 3,
          mediumCount: 4,
          hardCount: 3,
          topicIds: ['t1', 't2'],
          subjectId: 'sub1',
        );
        expect(config.durationMinutes, 60);
        expect(config.questionCount, 10);
        expect(config.easyCount, 3);
        expect(config.mediumCount, 4);
        expect(config.hardCount, 3);
        expect(config.topicIds, ['t1', 't2']);
        expect(config.subjectId, 'sub1');
      });

      test('ExamConfig allows optional fields to be null', () {
        const config = ExamConfig(
          durationMinutes: 30,
          questionCount: 5,
          subjectId: 'sub1',
        );
        expect(config.easyCount, isNull);
        expect(config.topicIds, isNull);
      });
    });

    group('ExamQuestionResult', () {
      test('ExamQuestionResult stores skipped flag', () {
        final result = ExamQuestionResult(
          question: _createQ(id: 'q1'),
          isCorrect: false,
          timeSpentMs: 0,
          wasSkipped: true,
          userAnswer: null,
        );
        expect(result.wasSkipped, isTrue);
        expect(result.userAnswer, isNull);
      });
    });
  });

  // ==========================================================================
  // 5. MISTAKE_REVIEW_SERVICE additional coverage
  // ==========================================================================
  group('MistakeReviewService - coverage gaps', () {
    late _FakeAttemptRepo3 attemptRepo;
    late _FakeQuestionRepo3 questionRepo;
    late MistakeReviewService service;

    setUp(() {
      attemptRepo = _FakeAttemptRepo3();
      questionRepo = _FakeQuestionRepo3();
      service = MistakeReviewService(
        attemptRepo: attemptRepo,
        questionRepo: questionRepo,
      );
    });

    test('getMistakesFromSession skips when question not found', () async {
      attemptRepo.addAttempt(StudentAttempt(
        id: 'a1',
        studentId: 's1',
        questionId: 'nonexistent',
        subjectId: 'sub1',
        isCorrect: false,
        timestamp: DateTime(2026, 1, 1),
        userAnswer: 'wrong',
      ));

      final mistakes = await service.getMistakesFromSession(
        studentId: 's1',
        subjectId: 'sub1',
      );

      expect(mistakes, isEmpty);
    });

    test('getMistakesFromSession handles exception gracefully', () async {
      attemptRepo.shouldThrow = true;

      final mistakes = await service.getMistakesFromSession(
        studentId: 's1',
        subjectId: 'sub1',
      );

      expect(mistakes, isEmpty);
    });

    test('getPendingMistakes handles exception gracefully', () async {
      attemptRepo.shouldThrow = true;

      final pending = await service.getPendingMistakes(
        studentId: 's1',
        subjectId: 'sub1',
      );

      expect(pending, isEmpty);
    });

    test('isQuestionCorrected handles exception gracefully', () async {
      attemptRepo.shouldThrow = true;

      final corrected = await service.isQuestionCorrected('q1');
      expect(corrected, isFalse);
    });

    test('extractRedoQuestions returns empty for empty input', () {
      final result = service.extractRedoQuestions([]);
      expect(result, isEmpty);
    });

    test('extractRedoQuestions extracts all questions', () {
      final mistakes = [
        MistakeEntry(
          question: _createQ(id: 'q1'),
          correctAnswer: 'A',
        ),
        MistakeEntry(
          question: _createQ(id: 'q2'),
          correctAnswer: 'B',
        ),
      ];
      final result = service.extractRedoQuestions(mistakes);
      expect(result, hasLength(2));
      expect(result[0].id, 'q1');
      expect(result[1].id, 'q2');
    });

    test('getMistakesFromSession uses markscheme for correct answer', () async {
      questionRepo.addQuestion(Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        markscheme: Markscheme(
          questionId: 'q1',
          correctAnswer: 'Correct Answer',
          explanation: 'Exp',
        ),
      ));

      attemptRepo.addAttempt(StudentAttempt(
        id: 'a1',
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'sub1',
        isCorrect: false,
        timestamp: DateTime(2026, 1, 1),
        userAnswer: 'wrong',
      ));

      final mistakes = await service.getMistakesFromSession(
        studentId: 's1',
        subjectId: 'sub1',
      );

      expect(mistakes, hasLength(1));
      expect(mistakes.first.correctAnswer, 'Correct Answer');
      expect(mistakes.first.explanation, 'Exp');
    });
  });

  // ==========================================================================
  // 6. DIFFICULTY_ADAPTER additional coverage
  // ==========================================================================
  group('DifficultyAdapter - coverage gaps', () {
    test('reset with value above max clamps to max', () {
      final adapter = DifficultyAdapter(
        maxDifficulty: 5,
        initialDifficulty: 3,
      );
      adapter.reset(initialDifficulty: 10);
      expect(adapter.currentDifficulty, 5);
    });

    test('reset with value below min clamps to min', () {
      final adapter = DifficultyAdapter(
        minDifficulty: 1,
        initialDifficulty: 3,
      );
      adapter.reset(initialDifficulty: -5);
      expect(adapter.currentDifficulty, 1);
    });

    test('custom min and max boundaries', () {
      final adapter = DifficultyAdapter(
        minDifficulty: 2,
        maxDifficulty: 4,
        initialDifficulty: 3,
        correctStreakThreshold: 1,
        incorrectStreakThreshold: 1,
      );

      adapter.recordResult(true);
      expect(adapter.suggestNextDifficulty(), 4);

      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 3);
    });

    test('consecutive correct after incorrect resets streak', () {
      final adapter = DifficultyAdapter(
        initialDifficulty: 3,
        correctStreakThreshold: 2,
        incorrectStreakThreshold: 2,
      );

      adapter.recordResult(false);
      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 2);

      adapter.recordResult(true);
      adapter.recordResult(true);
      expect(adapter.suggestNextDifficulty(), 3);
    });

    test('suggestNextDifficulty does not change when streaks below thresholds',
        () {
      final adapter = DifficultyAdapter(
        initialDifficulty: 3,
        correctStreakThreshold: 3,
        incorrectStreakThreshold: 3,
      );

      adapter.recordResult(true);
      adapter.recordResult(true);
      expect(adapter.suggestNextDifficulty(), 3);

      adapter.recordResult(false);
      adapter.recordResult(false);
      expect(adapter.suggestNextDifficulty(), 3);
    });
  });

  // ==========================================================================
  // 7. READINESS_SCORER additional coverage
  // ==========================================================================
  group('ReadinessScorer - coverage gaps', () {
    group('_computeScore edge cases', () {
      test('empty confidenceHistory uses default confidence gap', () {
        final now = DateTime.now();
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now,
          confidenceHistory: [],
        );
        final scorer = ReadinessScorer(
          questionMasteryMap: {'q1': qMastery},
        );
        final result = scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('no topic mastery uses default urgency', () {
        final questions = [_createQ(id: 'q1', topicId: 'unknown')];
        final scorer = ReadinessScorer();
        final result = scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('no question mastery uses default days score', () {
        final questions = [_createQ(id: 'q1')];
        final scorer = ReadinessScorer();
        final result = scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0));
      });

      test('difficulty contributes to score', () {
        final easyQ = _createQ(id: 'q1', difficulty: 1);
        final hardQ = _createQ(id: 'q2', difficulty: 5);
        final questions = [easyQ, hardQ];
        final scorer = ReadinessScorer();
        final result = scorer.scoreQuestions(questions);
        // Harder question should have higher score due to difficultyNorm
        expect(result[0].question.id, 'q2');
        expect(result[0].score, greaterThan(result[1].score));
      });

      test('extreme confidence gap gives high boost', () {
        final now = DateTime.now();
        final questions = [_createQ(id: 'q1')];
        final qMastery = QuestionMasteryState(
          studentId: 's1',
          questionId: 'q1',
          lastAttempt: now.subtract(const Duration(days: 30)),
          confidenceHistory: [1],
        );
        final scorer = ReadinessScorer(
          questionMasteryMap: {'q1': qMastery},
        );
        final result = scorer.scoreQuestions(questions);
        expect(result.first.score, greaterThan(0.5));
      });

      test('high readiness reduces priority', () {
        final now = DateTime.now();
        final questions = [
          _createQ(id: 'q1', topicId: 't1'),
          _createQ(id: 'q2', topicId: 't2'),
        ];
        final topicMasteryMap = <String, MasteryState>{
          't1': MasteryState(
            studentId: 's1',
            topicId: 't1',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.9,
            reviewUrgency: 0.5,
            accuracy: 0.8,
          ),
          't2': MasteryState(
            studentId: 's1',
            topicId: 't2',
            lastAttempt: now,
            lastUpdated: now,
            readinessScore: 0.1,
            reviewUrgency: 0.5,
            accuracy: 0.2,
          ),
        };
        final scorer = ReadinessScorer(topicMasteryMap: topicMasteryMap);
        final result = scorer.scoreQuestions(questions);
        // Low readiness (t2) should score higher due to readinessInverseWeight
        expect(result.first.question.id, 'q2');
      });
    });
  });

  // ==========================================================================
  // 8. PRACTICE_DATA_SERVICE additional coverage
  // ==========================================================================
  group('PracticeDataService - coverage gaps', () {
    test('loadTopics returns empty when questions empty', () async {
      final questionRepo = _FakeQuestionRepo4([]);
      final service = PracticeDataService(
        srService: _FakeSrService2({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepo2([]),
        studentIdService: _FakeStudentIdService(),
      );
      final topics = await service.loadTopics(questionRepo);
      expect(topics, isEmpty);
    });

    test('loadTopics filters out null topics but keeps non-null ones', () async {
      final questionRepo = _FakeQuestionRepo4([
        Question(
          id: 'q1',
          text: 'Q',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't1',
          topic: null,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        Question(
          id: 'q2',
          text: 'Q2',
          type: QuestionType.singleChoice,
          subjectId: 's1',
          topicId: 't2',
          topic: 'Algebra',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ]);
      final service = PracticeDataService(
        srService: _FakeSrService2({}),
        questionRepo: questionRepo,
        subjectRepo: _FakeSubjectRepo2([]),
        studentIdService: _FakeStudentIdService(),
      );
      final topics = await service.loadTopics(questionRepo);
      expect(topics, hasLength(1));
      expect(topics.first, 'Algebra');
    });

    test('loadDueCounts handles empty subjects list', () async {
      final srService = _FakeSrService2({});
      final service = PracticeDataService(
        srService: srService,
        questionRepo: _FakeQuestionRepo4([]),
        subjectRepo: _FakeSubjectRepo2([]),
        studentIdService: _FakeStudentIdService(),
      );
      final dueCounts = await service.loadDueCounts([]);
      expect(dueCounts, isEmpty);
    });

    test('loadWeakAreaQuestions returns empty when getWeakTopics returns empty list',
        () async {
      _FakeStudentIdService().setStudentId('test-student');
      final masteryService = _FakeMasteryGraphSvc2();
      final service = PracticeDataService(
        srService: _FakeSrService2({}),
        questionRepo: _FakeQuestionRepo4([]),
        subjectRepo: _FakeSubjectRepo2([]),
        studentIdService: _FakeStudentIdService(),
      );
      final result = await service.loadWeakAreaQuestions(masteryService);
      expect(result, isEmpty);
    });
  });

  // ==========================================================================
  // 9. PRACTICE_SESSION_SERVICE additional coverage
  // ==========================================================================
  group('PracticeSessionService - coverage gaps', () {
    test('updateNextReview handles exception gracefully', () async {
      final sessionRepo = _FakeSessionRepo();
      final srRepo = _FakeSrRepo();
      final clock = _FakeClock(DateTime(2026, 5, 16));
      srRepo.shouldThrow = true;

      final service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srRepo: srRepo,
        studentIdService: _FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );

      // Should not throw
      await service.updateNextReview('q1', true);
      service.dispose();
    });

    test('dispose with active timer and no timer is safe', () async {
      final sessionRepo = _FakeSessionRepo();
      final srRepo = _FakeSrRepo();
      final clock = _FakeClock(DateTime(2026, 5, 16));

      final service1 = PracticeSessionService(
        sessionRepo: sessionRepo,
        srRepo: srRepo,
        studentIdService: _FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );
      service1.startTimer();
      service1.dispose();

      final service2 = PracticeSessionService(
        sessionRepo: sessionRepo,
        srRepo: srRepo,
        studentIdService: _FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );
      service2.dispose();
    });

    test('autoSaveSession handles exception gracefully', () async {
      final sessionRepo = _FakeSessionRepo();
      final srRepo = _FakeSrRepo();
      final clock = _FakeClock(DateTime(2026, 5, 16));

      sessionRepo.shouldThrow = true;

      final service = PracticeSessionService(
        sessionRepo: sessionRepo,
        srRepo: srRepo,
        studentIdService: _FakeStudentIdService(),
        clock: clock,
        subjectId: 'sub1',
      );

      await service.autoSaveSession(
        questionsAnswered: 5,
        correctAnswers: 3,
      );
      service.dispose();
    });
  });
}

// ============================================================================
// FAKE CLASSES (not shared to avoid circular deps / conflicts)
// ============================================================================

// -- Question helpers --
Question _createQ({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
  String? srDataJson,
}) {
  return Question(
    id: id,
    text: 'Sample question?',
    type: QuestionType.singleChoice,
    subjectId: subjectId,
    topicId: topicId,
    difficulty: difficulty,
    createdAt: DateTime(2026, 5, 12),
    updatedAt: DateTime(2026, 5, 12),
    srDataJson: srDataJson,
  );
}

// -- Fake QuestionRepo for spaced_repetition_service tests --
class _FakeQuestionRepo extends QuestionRepository {
  final _FakeQuestionBox fakeBox;

  _FakeQuestionRepo(this.fakeBox);

  @override
  Future<void> init() async {}

  @override
  Box<Question> get box => fakeBox;

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(fakeBox.get(id));
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    await fakeBox.put(key, item);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    await fakeBox.delete(key);
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Question question) async {
    await fakeBox.put(question.id, question);
    return Result.success(null);
  }
}

// -- Throwing box repo --
class _FakeThrowingBoxRepo extends QuestionRepository {
  final Box<Question> _box;

  _FakeThrowingBoxRepo(this._box);

  @override
  Future<void> init() async {}

  @override
  Box<Question> get box => _box;

  @override
  Future<Result<Question?>> get(String id) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Question item) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<Result<void>> create(Question question) async {
    return Result.success(null);
  }
}

// -- MasteryRecorder fakes --
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
  Future<void> create(StudentAttempt attempt) async {
    attempts.add(attempt);
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
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }

  @override
  Future<Result<void>> save(String key, Question item) async {
    _questions[key] = item;
    return Result.success(null);
  }
}

// -- Exam session service fakes --
class _FakeSessionRepo extends SessionRepository {
  final List<Session> sessions = [];
  bool shouldThrow = false;

  @override
  Future<Result<void>> save(Session session) async {
    if (shouldThrow) return Result.failure('Save error');
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return Result.success(null);
    return Result.success(sessions[idx]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(sessions);
  }
}

// -- Mistake review service fakes --
class _FakeAttemptRepo3 extends AttemptRepository {
  final List<StudentAttempt> _attempts = [];
  bool shouldThrow = false;

  @override
  Future<void> init() async {}

  void addAttempt(StudentAttempt attempt) {
    _attempts.add(attempt);
  }

  @override
  Future<List<StudentAttempt>> getByStudent(String studentId) async {
    if (shouldThrow) throw Exception('Error');
    return _attempts.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<StudentAttempt>> getByStudentAndSubject(
    String studentId,
    String subjectId,
  ) async {
    if (shouldThrow) throw Exception('Error');
    return _attempts
        .where((a) => a.studentId == studentId && a.subjectId == subjectId)
        .toList();
  }

  @override
  Future<List<StudentAttempt>> getByQuestion(String questionId) async {
    if (shouldThrow) throw Exception('Error');
    return _attempts.where((a) => a.questionId == questionId).toList();
  }
}

class _FakeQuestionRepo3 extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<void> init() async {}

  void addQuestion(Question q) {
    _questions[q.id] = q;
  }

  @override
  Future<Result<Question?>> get(String id) async {
    return Result.success(_questions[id]);
  }
}

// -- Practice data service fakes --
class _FakeQuestionRepo4 extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepo4(this._questions);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);
}

class _FakeSrService2 extends SpacedRepetitionService {
  final Map<String, int> _dueCounts;

  _FakeSrService2(this._dueCounts)
      : super(
          questionRepo: QuestionRepository(),
          attemptRepo: AttemptRepository(),
        );

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }
}

class _FakeSubjectRepo2 extends SubjectRepository {
  final List<Subject> _subjects;
  _FakeSubjectRepo2(this._subjects);

  @override
  Future<Result<List<Subject>>> getAll() async => Result.success(_subjects);
}

class _FakeMasteryGraphSvc2 extends MasteryGraphService {
  _FakeMasteryGraphSvc2();

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    return Result.success(<MasteryState>[]);
  }
}

// -- PracticeSessionService fakes --
class _FakeSrRepo extends SpacedRepetitionRepository {
  bool shouldThrow = false;

  _FakeSrRepo();

  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> updateNextReviewDate(
      String questionId, double masteryLevel) async {
    if (shouldThrow) return Result.failure('SR error');
    return Result.success(null);
  }
}
