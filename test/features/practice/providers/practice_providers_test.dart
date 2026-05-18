import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/cross_feature_integrator.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/features/practice/data/models/student_attempt_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student';
  @override
  Future<void> init() async {}
}

void main() {
  group('PracticeProviders', () {
    test('spacedRepetitionServiceProvider can be overridden', () {
      final fakeService = SpacedRepetitionService(
        questionRepo: QuestionRepository(),
        attemptRepo: FakeAttemptRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          spacedRepetitionServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionServiceProvider);
      expect(result, same(fakeService));
    });

    test('questionRepositoryProvider can be overridden', () {
      final fakeRepo = QuestionRepository();
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(questionRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('masteryGraphServiceProvider can be overridden', () {
      final fakeService = FakeMasteryGraphService();
      final container = ProviderContainer(
        overrides: [
          masteryGraphServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryGraphServiceProvider);
      expect(result, same(fakeService));
    });

    test('sessionRepositoryProvider can be overridden', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(sessionRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('subjectRepositoryProvider can be overridden', () {
      final fakeRepo = SubjectRepository();
      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('attemptRepositoryProvider can be overridden', () {
      final fakeRepo = FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(attemptRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('masteryStateRepositoryProvider can be overridden', () {
      final fakeRepo = FakeMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryStateRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('questionMasteryStateRepositoryProvider can be overridden', () {
      final fakeRepo = FakeQuestionMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          questionMasteryStateRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(questionMasteryStateRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('topicDependencyRepositoryProvider can be overridden', () {
      final fakeRepo = FakeTopicDependencyRepository();
      final container = ProviderContainer(
        overrides: [
          topicDependencyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(topicDependencyRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('questionEvaluationRepositoryProvider can be overridden', () {
      final fakeRepo = FakeQuestionEvaluationRepository();
      final container = ProviderContainer(
        overrides: [
          questionEvaluationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(questionEvaluationRepositoryProvider);
      expect(result, same(fakeRepo));
    });

    test('masteryGraphServiceProvider is wired to masteryStateRepositoryProvider', () {
      final fakeMasteryState = FakeMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(fakeMasteryState),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(masteryGraphServiceProvider);
      expect(service, isA<MasteryGraphService>());
    });

    test('masteryRecorderProvider uses overridden attemptRepositoryProvider for recording', () {
      final seededAttemptRepo = FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededAttemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final recorder = container.read(masteryRecorderProvider);
      expect(recorder, isA<MasteryRecorder>());
    });

    test('spacedRepetitionEngineProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(spacedRepetitionEngineProvider);
      final b = container.read(spacedRepetitionEngineProvider);
      expect(a, same(b));
    });

    test('readinessScorerProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(readinessScorerProvider);
      final b = container.read(readinessScorerProvider);
      expect(a, same(b));
    });

  });

  group('PracticeProviders behavioral assertions', () {
    test('attemptRepositoryProvider with seeded data returns attempts', () async {
      final attempts = [
        StudentAttempt(
          id: 'a1',
          studentId: 'student-1',
          questionId: 'q1',
          subjectId: 'sub-1',
          isCorrect: true,
          timestamp: DateTime(2026, 5, 1),
        ),
        StudentAttempt(
          id: 'a2',
          studentId: 'student-1',
          questionId: 'q2',
          subjectId: 'sub-1',
          isCorrect: false,
          timestamp: DateTime(2026, 5, 1),
        ),
      ];
      final seededRepo = FakeAttemptRepositoryWithSeed(attempts);

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(attemptRepositoryProvider);
      final allResult = await repo.getAll();
      expect(allResult.isSuccess, isTrue);
      expect(allResult.data!.length, 2);
    });

    test('mistakeReviewServiceProvider uses overridden attemptRepo to find mistakes', () async {
      final attempts = [
        StudentAttempt(
          id: 'a1',
          studentId: 'student-1',
          questionId: 'q1',
          subjectId: 'sub-1',
          isCorrect: false,
          timestamp: DateTime(2026, 5, 1, 10, 0),
        ),
      ];
      final seededRepo = FakeAttemptRepositoryWithSeed(attempts);
      final fakeQuestionRepo = _FakeQuestionRepo([]);

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(seededRepo),
          questionRepositoryProvider.overrideWithValue(fakeQuestionRepo),
        ],
      );
      addTearDown(container.dispose);

      final mistakeService = container.read(mistakeReviewServiceProvider);
      final mistakes = await mistakeService.getMistakesFromSession(
        studentId: 'student-1',
        subjectId: 'sub-1',
        after: DateTime(2026, 5, 1, 9, 0),
      );
      expect(mistakes, isA<List>());
    });

    test('masteryGraphServiceProvider handles error-state when repo fails', () async {
      final throwingRepo = _FailingMasteryStateRepo();

      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(throwingRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(masteryGraphServiceProvider);
      final result = await service.getAllTopicMastery('student-1');
      expect(result.isFailure, isTrue);
    });

    test('spacedRepetitionServiceProvider updateNextReviewDate uses overridden repos', () async {
      final now = DateTime(2026, 5, 1);
      final question = Question(
        id: 'q-behave',
        subjectId: 'sub-1',
        topicId: 't-1',
        text: 'Behavioral test question?',
        type: QuestionType.typedAnswer,
        difficulty: 2,
        markscheme: Markscheme(correctAnswer: 'yes'),
        createdAt: now,
        updatedAt: now,
      );
      final questionRepo = _FakeQuestionRepo([question]);
      final attemptRepo = FakeAttemptRepository();

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final srService = container.read(spacedRepetitionServiceProvider);
      final result = await srService.updateNextReviewDate('q-behave', 0.9);
      expect(result.isSuccess, isTrue);
    });

    test('spacedRepetitionServiceProvider handles error-state when questionRepo fails', () async {
      final failingQuestionRepo = _FailingQuestionRepo();
      final attemptRepo = FakeAttemptRepository();

      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(failingQuestionRepo),
          attemptRepositoryProvider.overrideWithValue(attemptRepo),
        ],
      );
      addTearDown(container.dispose);

      final srService = container.read(spacedRepetitionServiceProvider);
      final result = await srService.updateNextReviewDate('q-nonexistent', 0.5);
      expect(result.isFailure, isTrue);
    });

    test('mistakeReviewServiceProvider handles error-state when attemptRepo fails', () async {
      final failingAttemptRepo = _FailingAttemptRepository();
      final questionRepo = _FakeQuestionRepo([]);

      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(failingAttemptRepo),
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
      );
      addTearDown(container.dispose);

      final mistakeService = container.read(mistakeReviewServiceProvider);
      final mistakes = await mistakeService.getMistakesFromSession(
        studentId: 'student-1',
        subjectId: 'sub-1',
      );
      expect(mistakes, isEmpty);
    });
  });
}

class _FakeQuestionRepo extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepo([this._questions = const []]);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async => Result.success(_questions);

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.success(_questions.where((q) => q.id == key).firstOrNull);
}

class _FailingQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<Question?>> get(String key) async =>
      Result.failure('Question repo failure');

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.failure('Question repo failure');
}

class _FailingMasteryStateRepo extends MasteryStateRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAll() async => Result.failure('Repo failure');

  Future<Result<List<MasteryState>>> getBySubject(String subjectId) async =>
      Result.failure('Repo failure');
}

class FakeMasteryStateRepository extends MasteryStateRepository {
  FakeMasteryStateRepository();
}

class FakeQuestionMasteryStateRepository extends QuestionMasteryStateRepository {
  FakeQuestionMasteryStateRepository();
}

class FakeTopicDependencyRepository extends TopicDependencyRepository {
  FakeTopicDependencyRepository();
}

class FakeQuestionEvaluationRepository extends QuestionEvaluationRepository {
  FakeQuestionEvaluationRepository();
}

class FakeAttemptRepository extends AttemptRepository {
  FakeAttemptRepository();
}

class FakeMasteryGraphService extends MasteryGraphService {
  FakeMasteryGraphService();
}

class FakeMasteryRecorder extends MasteryRecorder {
  FakeMasteryRecorder()
      : super(
          masteryGraphService: MasteryGraphService(),
          srEngine: SpacedRepetitionEngine(),
          attemptRepo: AttemptRepository(),
          questionMasteryRepo: QuestionMasteryStateRepository(),
          questionRepo: QuestionRepository(),
        );
}

class FakeExamSessionService extends ExamSessionService {
  FakeExamSessionService()
      : super(
          sessionRepo: SessionRepository(),
          studentIdService: _FakeStudentIdService(),
        );
}

class FakeMistakeReviewService extends MistakeReviewService {
  FakeMistakeReviewService()
      : super(
          attemptRepo: AttemptRepository(),
          questionRepo: QuestionRepository(),
        );
}

class FakeCrossFeatureIntegrator extends CrossFeatureIntegrator {
  FakeCrossFeatureIntegrator()
      : super(
          sessionRepo: SessionRepository(),
          studentIdService: _FakeStudentIdService(),
        );
}

class _FailingAttemptRepository extends AttemptRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getAll() async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<StudentAttempt?>> get(String key) async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<void>> delete(String key) async =>
      Result.failure('Attempt repo failure');

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    return Result.failure('Attempt repo failure');
  }
}

class FakeAttemptRepositoryWithSeed extends AttemptRepository {
  final List<StudentAttempt> _attempts;
  FakeAttemptRepositoryWithSeed(this._attempts);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<StudentAttempt>>> getAll() async => Result.success(_attempts);

  @override
  Future<Result<StudentAttempt?>> get(String key) async =>
      Result.success(_attempts.where((a) => a.id == key).firstOrNull);

  @override
  Future<Result<void>> save(String key, StudentAttempt item) async => Result.success(null);

  @override
  Future<Result<void>> delete(String key) async => Result.success(null);

  @override
  Future<Result<List<StudentAttempt>>> getByStudentAndSubject(
      String studentId, String subjectId) async {
    return Result.success(_attempts);
  }
}
