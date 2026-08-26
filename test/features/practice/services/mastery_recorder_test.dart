import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/question_mastery_state_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';

class _FakeBox<T> implements Box<T> {
  final Map<dynamic, T> _storage = {};

  @override
  Iterable<T> get values => _storage.values;

  @override
  T? get(dynamic key, {T? defaultValue}) => _storage[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, T value) async {
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
  String get name => 'fakeBox';

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

class FakeQuestionRepository extends QuestionRepository {
  final Map<String, Question> _storage = {};

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.success(_storage[key]);

  @override
  Future<Result<void>> save(String key, Question item) async {
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Box<Question> get box => _FakeBox<Question>();
}

class FakeAttemptRepository extends AttemptRepository {
  final Map<String, StudentAttempt> _storage = {};

  @override
  Future<Result<void>> create(StudentAttempt attempt) async {
    _storage[attempt.id] = attempt;
    return Result.success(null);
  }

  @override
  Future<Result<StudentAttempt?>> get(String key) async =>
      Result.success(_storage[key]);
}

class FakeQuestionMasteryStateRepository
    extends QuestionMasteryStateRepository {
  final Map<String, QuestionMasteryState> _storage = {};
  final List<String> updatedKeys = [];

  @override
  Future<Result<QuestionMasteryState>> getQuestionMasteryState(
    String studentId,
    String questionId,
  ) async {
    final key = '${studentId}_$questionId';
    final existing = _storage[key];
    if (existing != null) return Result.success(existing);
    final created = QuestionMasteryState.initial(
        studentId: studentId, questionId: questionId, now: DateTime.now());
    _storage[key] = created;
    return Result.success(created);
  }

  @override
  Future<Result<void>> updateQuestionMasteryState(
      QuestionMasteryState state) async {
    final key = '${state.studentId}_${state.questionId}';
    _storage[key] = state;
    updatedKeys.add(key);
    return Result.success(null);
  }
}

class FakeMasteryGraphService extends MasteryGraphService {
  bool recordAttemptCalled = false;
  bool? lastIsCorrect;
  int? lastConfidence;

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
    recordAttemptCalled = true;
    lastIsCorrect = isCorrect;
    lastConfidence = confidence;
    return Result.success(null);
  }
}

Question _makeQuestion(String id) {
  final now = DateTime(2026, 1, 1);
  return Question(
    id: id,
    text: 'What is 2+2?',
    type: QuestionType.typedAnswer,
    subjectId: 'math',
    topicId: 'arithmetic',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MasteryRecorder.recordAttempt', () {
    late FakeQuestionRepository questionRepo;
    late FakeAttemptRepository attemptRepo;
    late FakeQuestionMasteryStateRepository masteryRepo;
    late FakeMasteryGraphService masteryGraphService;
    late SpacedRepetitionEngine engine;
    late MasteryRecorder recorder;
    final now = DateTime(2026, 1, 1, 12, 0);

    setUp(() {
      questionRepo = FakeQuestionRepository();
      attemptRepo = FakeAttemptRepository();
      masteryRepo = FakeQuestionMasteryStateRepository();
      masteryGraphService = FakeMasteryGraphService();
      engine = SpacedRepetitionEngine();
      recorder = MasteryRecorder(
        masteryGraphService: masteryGraphService,
        srEngine: engine,
        attemptRepo: attemptRepo,
        questionMasteryRepo: masteryRepo,
        questionRepo: questionRepo,
      );
      questionRepo._storage['q1'] = _makeQuestion('q1');
    });

    test('records an attempt, updates mastery state, and reschedules review',
        () async {
      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'math',
        topicId: 'arithmetic',
        isCorrect: true,
        timeSpentMs: 5000,
        confidence: 5,
        userAnswer: '4',
        timestamp: now,
      );

      expect(result.isSuccess, isTrue);
      expect(masteryGraphService.recordAttemptCalled, isTrue);
      expect(masteryGraphService.lastIsCorrect, isTrue);
      expect(masteryGraphService.lastConfidence, 5);

      // The attempt was persisted.
      expect(attemptRepo._storage.isNotEmpty, isTrue);

      // The question's review schedule was recomputed by the engine.
      final updatedQuestion = questionRepo._storage['q1']!;
      expect(updatedQuestion.nextReview, isNotNull);
      expect(updatedQuestion.nextReview!.isAfter(now), isTrue);
      expect(updatedQuestion.srDataJson, isNotNull);
      expect(updatedQuestion.srDataJson!.isNotEmpty, isTrue);

      // The mastery record for this question was mutated (correct count up).
      final state = masteryRepo._storage['s1_q1']!;
      expect(state.correctCount, 1);
      expect(state.incorrectCount, 0);
      expect(state.nextReview, isNotNull);
    });

    test('an incorrect attempt lowers the stored correctness', () async {
      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'q1',
        subjectId: 'math',
        topicId: 'arithmetic',
        isCorrect: false,
        timeSpentMs: 5000,
        confidence: 1,
        userAnswer: '5',
        timestamp: now,
      );

      expect(result.isSuccess, isTrue);
      final state = masteryRepo._storage['s1_q1']!;
      expect(state.incorrectCount, 1);
      expect(state.correctCount, 0);
      expect(state.currentStreak, 0);
    });

    test('returns a failure when the question is missing', () async {
      final result = await recorder.recordAttempt(
        studentId: 's1',
        questionId: 'missing',
        subjectId: 'math',
        topicId: 'arithmetic',
        isCorrect: true,
        timeSpentMs: 1000,
        confidence: 4,
        userAnswer: 'x',
        timestamp: now,
      );
      expect(result.isFailure, isTrue);
    });
  });
}
