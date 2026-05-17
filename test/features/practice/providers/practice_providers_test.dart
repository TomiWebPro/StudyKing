import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/cross_feature_integrator.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_mastery_state_repository.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/practice/data/repositories/question_evaluation_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';
import 'package:studyking/features/practice/services/mastery_recorder.dart';
import 'package:studyking/features/practice/services/readiness_scorer.dart';
import 'package:studyking/features/practice/services/difficulty_adapter.dart';
import 'package:studyking/features/practice/services/exam_session_service.dart';
import 'package:studyking/features/practice/services/mistake_review_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student';
  @override
  Future<void> init() async {}
}

void main() {
  group('PracticeProviders', () {
    test('spacedRepetitionRepositoryProvider can be overridden', () {
      final fakeRepo = FakeSpacedRepetitionRepository();
      final container = ProviderContainer(
        overrides: [
          spacedRepetitionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionRepositoryProvider);
      expect(result, same(fakeRepo));
    });

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

    test('practiceDataServiceProvider can be overridden', () {
      final fakeService = PracticeDataService(
        srService: SpacedRepetitionService(
          questionRepo: QuestionRepository(),
          attemptRepo: FakeAttemptRepository(),
        ),
        questionRepo: QuestionRepository(),
        subjectRepo: SubjectRepository(),
        studentIdService: _FakeStudentIdService(),
      );
      final container = ProviderContainer(
        overrides: [
          practiceDataServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(practiceDataServiceProvider);
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

    test('practiceDataServiceProvider depends on spacedRepetitionServiceProvider', () {
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

      final dataService = container.read(practiceDataServiceProvider);
      expect(dataService, isA<PracticeDataService>());
    });

    test('practiceDataServiceProvider depends on sessionRepositoryProvider', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final dataService = container.read(practiceDataServiceProvider);
      expect(dataService, isA<PracticeDataService>());
    });

    test('practiceDataServiceProvider depends on subjectRepositoryProvider', () {
      final fakeRepo = SubjectRepository();
      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final dataService = container.read(practiceDataServiceProvider);
      expect(dataService, isA<PracticeDataService>());
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

    test('spacedRepetitionRepositoryProvider depends on questionRepositoryProvider', () {
      final fakeRepo = QuestionRepository();
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionRepositoryProvider);
      expect(result, isA<SpacedRepetitionRepository>());
    });

    test('spacedRepetitionRepositoryProvider depends on attemptRepositoryProvider', () {
      final fakeRepo = FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionRepositoryProvider);
      expect(result, isA<SpacedRepetitionRepository>());
    });

    test('spacedRepetitionServiceProvider depends on questionRepositoryProvider', () {
      final fakeRepo = QuestionRepository();
      final container = ProviderContainer(
        overrides: [
          questionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionServiceProvider);
      expect(result, isA<SpacedRepetitionService>());
    });

    test('spacedRepetitionServiceProvider depends on attemptRepositoryProvider', () {
      final fakeRepo = FakeAttemptRepository();
      final container = ProviderContainer(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionServiceProvider);
      expect(result, isA<SpacedRepetitionService>());
    });

    test('masteryGraphServiceProvider depends on masteryStateRepositoryProvider', () {
      final fakeRepo = FakeMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          masteryStateRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryGraphServiceProvider);
      expect(result, isA<MasteryGraphService>());
    });

    test('masteryGraphServiceProvider depends on questionMasteryStateRepositoryProvider', () {
      final fakeRepo = FakeQuestionMasteryStateRepository();
      final container = ProviderContainer(
        overrides: [
          questionMasteryStateRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryGraphServiceProvider);
      expect(result, isA<MasteryGraphService>());
    });

    test('masteryGraphServiceProvider depends on topicDependencyRepositoryProvider', () {
      final fakeRepo = FakeTopicDependencyRepository();
      final container = ProviderContainer(
        overrides: [
          topicDependencyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryGraphServiceProvider);
      expect(result, isA<MasteryGraphService>());
    });

    test('masteryGraphServiceProvider depends on questionEvaluationRepositoryProvider', () {
      final fakeRepo = FakeQuestionEvaluationRepository();
      final container = ProviderContainer(
        overrides: [
          questionEvaluationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryGraphServiceProvider);
      expect(result, isA<MasteryGraphService>());
    });

    test('spacedRepetitionEngineProvider creates default engine', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionEngineProvider);
      expect(result, isA<SpacedRepetitionEngine>());
    });

    test('spacedRepetitionEngineProvider can be overridden', () {
      final fakeEngine = SpacedRepetitionEngine();
      final container = ProviderContainer(
        overrides: [
          spacedRepetitionEngineProvider.overrideWithValue(fakeEngine),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spacedRepetitionEngineProvider);
      expect(result, same(fakeEngine));
    });

    test('masteryRecorderProvider creates recorder with dependencies', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(masteryRecorderProvider);
      expect(result, isA<MasteryRecorder>());
    });

    test('masteryRecorderProvider can be overridden', () {
      final fakeRecorder = FakeMasteryRecorder();
      final container = ProviderContainer(
        overrides: [
          masteryRecorderProvider.overrideWithValue(fakeRecorder),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(masteryRecorderProvider);
      expect(result, same(fakeRecorder));
    });

    test('readinessScorerProvider creates default scorer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(readinessScorerProvider);
      expect(result, isA<ReadinessScorer>());
    });

    test('readinessScorerProvider can be overridden', () {
      final fakeScorer = ReadinessScorer();
      final container = ProviderContainer(
        overrides: [
          readinessScorerProvider.overrideWithValue(fakeScorer),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(readinessScorerProvider);
      expect(result, same(fakeScorer));
    });

    test('difficultyAdapterProvider creates default adapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(difficultyAdapterProvider);
      expect(result, isA<DifficultyAdapter>());
    });

    test('difficultyAdapterProvider can be overridden', () {
      final fakeAdapter = DifficultyAdapter();
      final container = ProviderContainer(
        overrides: [
          difficultyAdapterProvider.overrideWithValue(fakeAdapter),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(difficultyAdapterProvider);
      expect(result, same(fakeAdapter));
    });

    test('examSessionServiceProvider creates service with dependencies', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(examSessionServiceProvider);
      expect(result, isA<ExamSessionService>());
    });

    test('examSessionServiceProvider can be overridden', () {
      final fakeService = FakeExamSessionService();
      final container = ProviderContainer(
        overrides: [
          examSessionServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(examSessionServiceProvider);
      expect(result, same(fakeService));
    });

    test('mistakeReviewServiceProvider creates service with dependencies', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(mistakeReviewServiceProvider);
      expect(result, isA<MistakeReviewService>());
    });

    test('mistakeReviewServiceProvider can be overridden', () {
      final fakeService = FakeMistakeReviewService();
      final container = ProviderContainer(
        overrides: [
          mistakeReviewServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(mistakeReviewServiceProvider);
      expect(result, same(fakeService));
    });

    test('crossFeatureIntegratorProvider creates integrator with dependencies', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(crossFeatureIntegratorProvider);
      expect(result, isA<CrossFeatureIntegrator>());
    });

    test('crossFeatureIntegratorProvider can be overridden', () {
      final fakeIntegrator = FakeCrossFeatureIntegrator();
      final container = ProviderContainer(
        overrides: [
          crossFeatureIntegratorProvider.overrideWithValue(fakeIntegrator),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(crossFeatureIntegratorProvider);
      expect(result, same(fakeIntegrator));
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

    test('difficultyAdapterProvider is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = container.read(difficultyAdapterProvider);
      final b = container.read(difficultyAdapterProvider);
      expect(a, same(b));
    });
  });
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

class FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  FakeSpacedRepetitionRepository();
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
