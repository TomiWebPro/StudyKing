import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/practice/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_service.dart';
import 'package:studyking/features/practice/services/practice_data_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';

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
        studentIdService: StudentIdService(),
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
  });
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
