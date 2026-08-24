import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/flashcards/providers/flashcard_providers.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A hand-written recording fake for [FlashcardRepository].
/// Beyond the construction-only behavior of the old fake, it tracks which
/// repository methods were actually invoked so tests can assert that the
/// downstream service truly uses the injected dependency.
class _RecordingFakeFlashcardRepository extends FlashcardRepository {
  final Map<String, Flashcard> _storage = {};

  int getAllCalls = 0;
  int getCalls = 0;
  int saveCalls = 0;
  int createCalls = 0;
  final List<String> savedKeys = [];

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Flashcard>>> getAll() async {
    getAllCalls++;
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<Flashcard?>> get(String id) async {
    getCalls++;
    return Result.success(_storage[id]);
  }

  @override
  Future<Result<void>> save(String key, Flashcard item) async {
    saveCalls++;
    savedKeys.add(key);
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Flashcard flashcard) async {
    createCalls++;
    _storage[flashcard.id] = flashcard;
    return Result.success(null);
  }

  @override
  bool get isOpen => true;
}

void main() {
  group('Flashcard Providers', () {
    test('flashcardRepoProvider returns a FlashcardRepository', () {
      final container = ProviderContainer(
        overrides: [
          flashcardRepoProvider.overrideWithValue(
            _RecordingFakeFlashcardRepository(),
          ),
        ],
      );
      final repo = container.read(flashcardRepoProvider);
      expect(repo, isA<FlashcardRepository>());
    });

    test(
        'flashcardReviewServiceProvider uses the injected repo when getting '
        'due flashcards', () async {
      final fakeRepo = _RecordingFakeFlashcardRepository();
      await fakeRepo.create(
        Flashcard(
          id: 'fc1',
          sourceId: 'src1',
          topicId: 't1',
          subjectId: 'sub1',
          front: 'Q',
          back: 'A',
          createdAt: DateTime(2020),
          updatedAt: DateTime(2020),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          flashcardRepoProvider.overrideWithValue(fakeRepo),
        ],
      );
      final service = container.read(flashcardReviewServiceProvider);

      expect(fakeRepo.getAllCalls, 0);
      final result = await service.getDueFlashcards();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(fakeRepo.getAllCalls, 1,
          reason: 'service must invoke the injected repo getAll');
    });

    test(
        'flashcardReviewServiceProvider records a review through the injected '
        'repo save', () async {
      final fakeRepo = _RecordingFakeFlashcardRepository();
      await fakeRepo.create(
        Flashcard(
          id: 'fc2',
          sourceId: 'src1',
          topicId: 't1',
          subjectId: 'sub1',
          front: 'Q',
          back: 'A',
          createdAt: DateTime(2020),
          updatedAt: DateTime(2020),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          flashcardRepoProvider.overrideWithValue(fakeRepo),
        ],
      );
      final service = container.read(flashcardReviewServiceProvider);

      expect(fakeRepo.saveCalls, 0);
      final result = await service.recordReview(
        flashcardId: 'fc2',
        grade: 5,
      );

      expect(result.isSuccess, isTrue);
      expect(fakeRepo.getCalls, 1);
      expect(fakeRepo.saveCalls, 1);
      expect(fakeRepo.savedKeys, contains('fc2'));
    });

    test('flashcardRepoProvider returns the same instance across reads '
        '(singleton identity)', () {
      final container = ProviderContainer();
      final first = container.read(flashcardRepoProvider);
      final second = container.read(flashcardRepoProvider);
      expect(identical(first, second), isTrue,
          reason: 'reads of the same provider must return the same instance');
    });

    test('studyGuideRepoProvider returns StudyGuideRepository', () {
      final container = ProviderContainer();
      final repo = container.read(studyGuideRepoProvider);
      expect(repo, isA<StudyGuideRepository>());
    });

    test('conceptMapRepoProvider returns ConceptMapRepository', () {
      final container = ProviderContainer();
      final repo = container.read(conceptMapRepoProvider);
      expect(repo, isA<ConceptMapRepository>());
    });
  });
}
