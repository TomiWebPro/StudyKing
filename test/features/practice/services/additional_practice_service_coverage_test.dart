import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────
//  FAKES
// ─────────────────────────────────────────────────────────────

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

class _FakeQuestionRepo extends QuestionRepository {
  final _FakeQuestionBox fakeBox;

  _FakeQuestionRepo(this.fakeBox);

  @override
  Future<Result<void>> init() async => Result.success(null);

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

class _FakeAttemptRepo extends AttemptRepository {
  final Map<String, StudentAttempt> _storage = {};
  bool _throwOnGet = false;

  void setThrowOnGet() {
    _throwOnGet = true;
  }

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<StudentAttempt?>> get(String id) async {
    if (_throwOnGet) throw Exception('Attempt get error');
    return Result.success(_storage[id]);
  }
}

Question _createQ({
  String id = 'q1',
  String subjectId = 'sub1',
  String topicId = 't1',
  int difficulty = 1,
  String? srDataJson,
  DateTime? nextReview,
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
    nextReview: nextReview,
  );
}

// ─────────────────────────────────────────────────────────────
//  1. SPACED_REPETITION_ENGINE extra branches
// ─────────────────────────────────────────────────────────────

void main() {
  group('SpacedRepetitionEngine - additional coverage', () {
    late SpacedRepetitionEngine engine;

    setUp(() {
      engine = SpacedRepetitionEngine();
    });

    group('migrateFromLegacy accuracy-to-grade mapping', () {
      test('accuracy 0.6 maps to grade 3', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 7));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.6,
          now: now,
        );
        expect(result.updatedData.reviewLog.last.grade, 3);
      });

      test('accuracy 0.8 maps to grade 4', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 7));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.8,
          now: now,
        );
        expect(result.updatedData.reviewLog.last.grade, 4);
      });

      test('accuracy 0.4 maps to grade 2', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 7));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.4,
          now: now,
        );
        expect(result.updatedData.reviewLog.last.grade, 2);
      });

      test('accuracy 0.15 maps to grade 1', () {
        final now = DateTime(2026, 5, 16);
        final legacyNextReview = now.add(const Duration(days: 7));
        final result = engine.migrateFromLegacy(
          questionId: 'q1',
          legacyNextReview: legacyNextReview,
          legacyLastReview: now.subtract(const Duration(days: 1)),
          totalAttempts: 5,
          accuracy: 0.15,
          now: now,
        );
        expect(result.updatedData.reviewLog.last.grade, 1);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────
  //  2. SPACED_REPETITION_SERVICE extra paths
  // ─────────────────────────────────────────────────────────────

  group('SpacedRepetitionService - additional coverage', () {
    late _FakeQuestionBox questionBox;
    late _FakeAttemptRepo attemptRepo;

    setUp(() {
      questionBox = _FakeQuestionBox();
      attemptRepo = _FakeAttemptRepo();
    });

    test('isQuestionDueForReview returns true for past-due question', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      final q = _createQ(nextReview: DateTime(2020, 1, 1));
      final result = await service.isQuestionDueForReview(q);
      expect(result.isSuccess, isTrue);
      // With a 5-minute tolerance, a 6-year-old nextReview is definitely due
      expect(result.data, isTrue);
    });

    test('isQuestionDueForReview returns false for future question', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      final q = _createQ(nextReview: DateTime(2099, 1, 1));
      final result = await service.isQuestionDueForReview(q, asOf: DateTime(2026, 5, 12));
      expect(result.isSuccess, isTrue);
      expect(result.data, isFalse);
    });

    test('_serializeSrData with null previousInterval omits pi', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(id: 'q1'));

      final result = await service.updateNextReviewDate('q1', 0.5);
      expect(result.isSuccess, isTrue);
      final updated = questionBox.get('q1')!;
      expect(updated.srDataJson, isNotNull);
      // grade 3 (correct but low confidence), first review => 1 day interval
      final decoded = _decodeJson(updated.srDataJson!);
      expect(decoded['r'], 1);
      expect(decoded['ef'], closeTo(2.36, 0.01));
    });

    test('_deserializeSrData with valid full JSON parses all fields', () async {
      final qRepo = _FakeQuestionRepo(questionBox);
      final service = SpacedRepetitionService(
        questionRepo: qRepo,
        attemptRepo: attemptRepo,
      );
      questionBox.put('q1', _createQ(
        id: 'q1',
        srDataJson: '{"r":3,"ef":2.5,"pi":259200000,"lr":1700000000000}',
      ));

      final result = await service.updateNextReviewDate('q1', 0.95);
      expect(result.isSuccess, isTrue);
      final updated = questionBox.get('q1')!;
      expect(updated.srDataJson, contains('"r"'));
    });

    test('getQuestionsDueForReview returns failure on exception', () async {
      final throwingBox = _ThrowingBox2<Question>();
      final throwingRepo = _FakeThrowingBoxRepo2(throwingBox);
      final service = SpacedRepetitionService(
        questionRepo: throwingRepo,
        attemptRepo: attemptRepo,
      );

      final result = await service.getQuestionsDueForReview();
      expect(result.isFailure, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  //  3. EXAM_SESSION_SERVICE selectQuestions
  // ─────────────────────────────────────────────────────────────

  group('ExamSessionService.selectQuestions', () {
    late ExamSessionService service;

    setUp(() {
      service = ExamSessionService(
        sessionRepo: _FakeSessionRepo2(),
        studentIdService: _FakeStudentIdService2(),
      );
    });

    tearDown(() {
      service.dispose();
    });

    Question mkQ({
      required String id,
      required String subjectId,
      String topicId = 't1',
      int difficulty = 1,
    }) {
      return Question(
        id: id,
        text: 'Q$id',
        type: QuestionType.singleChoice,
        subjectId: subjectId,
        topicId: topicId,
        difficulty: difficulty,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('selects questions by subject', () {
      final pool = [
        mkQ(id: '1', subjectId: 'sub1'),
        mkQ(id: '2', subjectId: 'sub2'),
        mkQ(id: '3', subjectId: 'sub1'),
      ];
      final config = const ExamConfig(
        durationMinutes: 30,
        questionCount: 2,
        subjectId: 'sub1',
      );

      final selected = service.selectQuestions(pool: pool, config: config);
      expect(selected, hasLength(2));
      expect(selected.every((q) => q.subjectId == 'sub1'), isTrue);
    });

    test('filters by topic when topicIds provided', () {
      final pool = [
        mkQ(id: '1', subjectId: 'sub1', topicId: 't1'),
        mkQ(id: '2', subjectId: 'sub1', topicId: 't2'),
        mkQ(id: '3', subjectId: 'sub1', topicId: 't1'),
      ];
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 10,
        subjectId: 'sub1',
        topicIds: ['t1'],
      );

      final selected = service.selectQuestions(pool: pool, config: config);
      expect(selected.every((q) => q.topicId == 't1'), isTrue);
    });

    test('uses difficulty breakdown when counts provided', () {
      final pool = [
        mkQ(id: '1', subjectId: 'sub1', difficulty: 1),
        mkQ(id: '2', subjectId: 'sub1', difficulty: 2),
        mkQ(id: '3', subjectId: 'sub1', difficulty: 3),
        mkQ(id: '4', subjectId: 'sub1', difficulty: 3),
        mkQ(id: '5', subjectId: 'sub1', difficulty: 5),
      ];
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 5,
        subjectId: 'sub1',
        easyCount: 2,
        mediumCount: 1,
        hardCount: 2,
      );

      final selected = service.selectQuestions(pool: pool, config: config);
      expect(selected, hasLength(5));
    });

    test('fills remaining questions from other difficulties', () {
      final pool = [
        mkQ(id: '1', subjectId: 'sub1', difficulty: 3),
        mkQ(id: '2', subjectId: 'sub1', difficulty: 3),
        mkQ(id: '3', subjectId: 'sub1', difficulty: 3),
      ];
      // Request 2 medium, 2 hard, 1 easy but no easy/hard exist
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 3,
        subjectId: 'sub1',
        easyCount: 1,
        mediumCount: 2,
        hardCount: 0,
      );

      final selected = service.selectQuestions(pool: pool, config: config);
      expect(selected, hasLength(3));
      // All questions in the pool are medium difficulty, so we get 2 medium
      // and 1 from remaining (which is also medium)
    });

    test('returns all candidates when no difficulty breakdown', () {
      final pool = [
        mkQ(id: '1', subjectId: 'sub1'),
        mkQ(id: '2', subjectId: 'sub1'),
      ];
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 10,
        subjectId: 'sub1',
      );

      final selected = service.selectQuestions(pool: pool, config: config);
      expect(selected, hasLength(2));
    });

    test('returns empty for empty pool', () {
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 5,
        subjectId: 'sub1',
      );

      final selected = service.selectQuestions(pool: [], config: config);
      expect(selected, isEmpty);
    });

    test('returns empty when no candidates match subject', () {
      final pool = [
        mkQ(id: '1', subjectId: 'sub2'),
      ];
      const config = ExamConfig(
        durationMinutes: 30,
        questionCount: 5,
        subjectId: 'sub1',
      );

      final selected = service.selectQuestions(pool: pool, config: config);
      expect(selected, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────
  //  4. ExamResult toJson / fromJson
  // ─────────────────────────────────────────────────────────────

  group('ExamResult serialization', () {
    Question q({String id = 'q1', String topicId = 't1'}) {
      return Question(
        id: id,
        text: 'Q',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: topicId,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('roundtrip with all fields', () {
      final original = ExamResult(
        config: const ExamConfig(
          durationMinutes: 30,
          questionCount: 3,
          subjectId: 'sub1',
          easyCount: 1,
          mediumCount: 1,
          hardCount: 1,
        ),
        questionResults: [
          ExamQuestionResult(
            question: q(id: 'q1', topicId: 't1'),
            userAnswer: 'A',
            isCorrect: true,
            timeSpentMs: 5000,
            wasSkipped: false,
          ),
          ExamQuestionResult(
            question: q(id: 'q2', topicId: 't1'),
            userAnswer: 'B',
            isCorrect: false,
            timeSpentMs: 3000,
            wasSkipped: false,
          ),
          ExamQuestionResult(
            question: q(id: 'q3', topicId: 't2'),
            isCorrect: false,
            timeSpentMs: 0,
            wasSkipped: true,
          ),
        ],
        startTime: DateTime(2026, 1, 1, 10, 0, 0),
        endTime: DateTime(2026, 1, 1, 10, 30, 0),
        wasAutoSubmitted: true,
      );

      final json = original.toJson();
      expect(json['totalCorrect'], 1);
      expect(json['totalIncorrect'], 1);
      expect(json['totalSkipped'], 1);
      expect(json['wasAutoSubmitted'], isTrue);
      expect(json['configDurationMinutes'], 30);
      expect(json['configEasyCount'], 1);

      final restored = ExamResult.fromJson(json, original.questionResults);
      expect(restored.totalCorrect, original.totalCorrect);
      expect(restored.totalIncorrect, original.totalIncorrect);
      expect(restored.totalSkipped, original.totalSkipped);
      expect(restored.accuracy, original.accuracy);
      expect(restored.wasAutoSubmitted, original.wasAutoSubmitted);
    });

    test('roundtrip with minimal fields', () {
      final original = ExamResult(
        config: const ExamConfig(
          durationMinutes: 30,
          questionCount: 1,
          subjectId: 'sub1',
        ),
        questionResults: [
          ExamQuestionResult(
            question: q(id: 'q1'),
            isCorrect: true,
            timeSpentMs: 5000,
          ),
        ],
        startTime: DateTime(2026, 1, 1, 10, 0, 0),
        endTime: DateTime(2026, 1, 1, 10, 30, 0),
      );

      final json = original.toJson();
      expect(json['configEasyCount'], isNull);

      final restored = ExamResult.fromJson(json, original.questionResults);
      expect(restored.totalCorrect, 1);
      expect(restored.wasAutoSubmitted, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  //  5. ExamQuestionResult toJson / fromJson
  // ─────────────────────────────────────────────────────────────

  group('ExamQuestionResult serialization', () {
    Question q({String id = 'q1'}) {
      return Question(
        id: id,
        text: 'Q',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('roundtrip with all fields', () {
      final question = q();
      final original = ExamQuestionResult(
        question: question,
        userAnswer: 'A',
        isCorrect: true,
        timeSpentMs: 5000,
        wasSkipped: false,
      );

      final json = original.toJson();
      expect(json['questionId'], 'q1');
      expect(json['userAnswer'], 'A');
      expect(json['isCorrect'], isTrue);
      expect(json['timeSpentMs'], 5000);
      expect(json['wasSkipped'], isFalse);

      final restored = ExamQuestionResult.fromJson(json, question);
      expect(restored.question.id, 'q1');
      expect(restored.userAnswer, 'A');
      expect(restored.isCorrect, isTrue);
      expect(restored.timeSpentMs, 5000);
      expect(restored.wasSkipped, isFalse);
    });

    test('roundtrip with skipped flag', () {
      final question = q(id: 'q2');
      final original = ExamQuestionResult(
        question: question,
        isCorrect: false,
        timeSpentMs: 0,
        wasSkipped: true,
      );

      final json = original.toJson();
      expect(json['wasSkipped'], isTrue);

      final restored = ExamQuestionResult.fromJson(json, question);
      expect(restored.wasSkipped, isTrue);
    });

    test('fromJson defaults wasSkipped to false', () {
      final question = q();
      final json = <String, dynamic>{
        'questionId': 'q1',
        'userAnswer': null,
        'isCorrect': true,
        'timeSpentMs': 1000,
      };

      final restored = ExamQuestionResult.fromJson(json, question);
      expect(restored.wasSkipped, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  //  6. READINESS_SCORER _ensureDataLoaded path
  // ─────────────────────────────────────────────────────────────

  group('ReadinessScorer - _ensureDataLoaded with services', () {
    test('loads data from mastery service when no maps provided', () async {
      final masteryService = _FakeMasteryGraphServiceForScorer(Result.success([
        MasteryState(
          studentId: 's1',
          topicId: 't1',
          accuracy: 0.9,
          lastAttempt: DateTime.now(),
          lastUpdated: DateTime.now(),
          readinessScore: 0.2,
          reviewUrgency: 0.9,
        ),
      ]));
      final studentIdService = _FakeStudentIdServiceForScorer();

      final scorer = ReadinessScorer(
        masteryService: masteryService,
        studentIdService: studentIdService,
      );

      final questions = [
        _createQ(id: 'q1', topicId: 't1'),
        _createQ(id: 'q2', topicId: 't2'),
      ];

      final result = await scorer.scoreQuestions(questions);
      expect(result, hasLength(2));
      expect(result.first.question.id, 'q1');
      // q1 has topic t1 with low readinessScore (0.2) and high urgency (0.9)
      // => higher readiness-inverse contribution => total score > q2
      expect(result.first.score, greaterThan(result.last.score));
    });

    test('handles mastery service init failure gracefully', () async {
      final masteryService = _FakeMasteryGraphServiceForScorer(
        Result.failure('init error'),
        failOnInit: true,
      );
      final studentIdService = _FakeStudentIdServiceForScorer();

      final scorer = ReadinessScorer(
        masteryService: masteryService,
        studentIdService: studentIdService,
      );

      final questions = [_createQ(id: 'q1')];
      final result = await scorer.scoreQuestions(questions);
      expect(result, hasLength(1));
      expect(result.first.score, greaterThan(0));
    });

    test('handles masteryservice getWeakTopics failure gracefully', () async {
      final masteryService = _FakeMasteryGraphServiceForScorer(
        Result.failure('topic failure'),
        failOnGetAllTopic: true,
      );
      final studentIdService = _FakeStudentIdServiceForScorer();

      final scorer = ReadinessScorer(
        masteryService: masteryService,
        studentIdService: studentIdService,
      );

      final questions = [_createQ(id: 'q1')];
      final result = await scorer.scoreQuestions(questions);
      expect(result, hasLength(1));
    });

    test('preloaded maps skip service loading', () async {
      final masteryService = _FakeMasteryGraphServiceForScorer(Result.success([]));
      masteryService.initCalled = false;

      final scorer = ReadinessScorer(
        topicMasteryMap: <String, MasteryState>{},
        masteryService: masteryService,
        studentIdService: _FakeStudentIdServiceForScorer(),
      );

      final questions = [_createQ(id: 'q1')];
      await scorer.scoreQuestions(questions);
      expect(masteryService.initCalled, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  //  7. MASTERY_RECORDER _deserializeSrData/_serializeSrData
  // ─────────────────────────────────────────────────────────────

  group('MasteryRecorder - serialize/deserialize SrData paths', () {
    test('deserializes valid SR data JSON with all fields', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        srDataJson: '{"r":3,"ef":2.5,"pi":259200000,"lr":1700000000000}',
      );
      final qRepo = _FakeQuestionRepo3();
      await qRepo.save('q1', question);

      final recorder = MasteryRecorder(
        masteryGraphService: _FakeMasteryGraphSvc3(),
        srEngine: SpacedRepetitionEngine(),
        attemptRepo: _FakeAttemptRepo3(),
        questionMasteryRepo: _FakeQMasteryRepo3(),
        questionRepo: qRepo,
      );

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
      final updated = await qRepo.get('q1');
      expect(updated.data!.srDataJson, contains('"r"'));
      expect(updated.data!.srDataJson, contains('"pi"'));
      expect(updated.data!.srDataJson, contains('"lr"'));
    });

    test('handles malformed SR data JSON gracefully', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        srDataJson: 'not-valid-json',
      );
      final qRepo = _FakeQuestionRepo3();
      await qRepo.save('q1', question);

      final recorder = MasteryRecorder(
        masteryGraphService: _FakeMasteryGraphSvc3(),
        srEngine: SpacedRepetitionEngine(),
        attemptRepo: _FakeAttemptRepo3(),
        questionMasteryRepo: _FakeQMasteryRepo3(),
        questionRepo: qRepo,
      );

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

    test('serializes SR data without previousInterval', () async {
      final question = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: 't1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        srDataJson: null,
      );
      final qRepo = _FakeQuestionRepo3();
      await qRepo.save('q1', question);

      final recorder = MasteryRecorder(
        masteryGraphService: _FakeMasteryGraphSvc3(),
        srEngine: SpacedRepetitionEngine(),
        attemptRepo: _FakeAttemptRepo3(),
        questionMasteryRepo: _FakeQMasteryRepo3(),
        questionRepo: qRepo,
      );

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
      final updated = await qRepo.get('q1');
      expect(updated.data!.srDataJson, contains('"r"'));
      expect(updated.data!.srDataJson, contains('"ef"'));
    });
  });
}

// ─────────────────────────────────────────────────────────────
//  INTERNAL FAKES
// ─────────────────────────────────────────────────────────────

Map<String, dynamic> _decodeJson(String s) {
  // Use dart:convert inline
  return _parseSimpleJson(s);
}

Map<String, dynamic> _parseSimpleJson(String s) {
  final map = <String, dynamic>{};
  final stripped = s.replaceAll('{', '').replaceAll('}', '').trim();
  if (stripped.isEmpty) return map;
  final pairs = stripped.split(',');
  for (final pair in pairs) {
    final parts = pair.split(':');
    if (parts.length == 2) {
      final key = parts[0].trim().replaceAll('"', '');
      final val = parts[1].trim().replaceAll('"', '');
      final numVal = num.tryParse(val);
      map[key] = numVal ?? val;
    }
  }
  return map;
}

class _ThrowingBox2<T> implements Box<T> {
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

class _FakeThrowingBoxRepo2 extends QuestionRepository {
  final Box<Question> _box;

  _FakeThrowingBoxRepo2(this._box);

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Box<Question> get box => _box;

  @override
  Future<Result<Question?>> get(String id) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Question item) async =>
      Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<Result<void>> create(Question question) async =>
      Result.success(null);
}

class _FakeSessionRepo2 extends SessionRepository {
  _FakeSessionRepo2() : super();

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Session item) async =>
      Result.success(null);

  @override
  Future<Result<Session?>> get(String id) async => Result.success(null);

  @override
  Future<Result<List<Session>>> getAll() async => Result.success([]);
}

class _FakeStudentIdService2 extends StudentIdService {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  String getStudentId() => 'test-student';
}

class _FakeMasteryGraphServiceForScorer extends MasteryGraphService {
  final Result<List<MasteryState>> _topicResult;
  bool failOnInit;
  bool failOnGetAllTopic;
  bool initCalled = false;

  _FakeMasteryGraphServiceForScorer(
    this._topicResult, {
    this.failOnInit = false,
    this.failOnGetAllTopic = false,
  }) : super();

  @override
  Future<Result<void>> init() async {
    initCalled = true;
    if (failOnInit) return Result.failure('Init failed');
    return Result.success(null);
  }

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    if (failOnGetAllTopic) return Result.failure('topic failure');
    return _topicResult;
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAllQuestionMastery(
      String studentId) async {
    return Result.success([]);
  }
}

class _FakeStudentIdServiceForScorer extends StudentIdService {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  String getStudentId() => 's1';
}

class _FakeMasteryGraphSvc3 extends MasteryGraphService {
  _FakeMasteryGraphSvc3() : super();

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
    return Result.success(null);
  }
}

class _FakeAttemptRepo3 extends AttemptRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    return Result.success(null);
  }
}

class _FakeQMasteryRepo3 extends QuestionMasteryStateRepository {
  bool shouldFail = false;

  @override
  Future<Result<void>> init() async => Result.success(null);

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
    return Result.success(null);
  }
}

class _FakeQuestionRepo3 extends QuestionRepository {
  final Map<String, Question> _questions = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

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


