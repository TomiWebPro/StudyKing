import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/flashcards/providers/flashcard_providers.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/study_guide_repository.dart';
import 'package:studyking/features/flashcards/data/repositories/concept_map_repository.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeFlashcardRepository extends FlashcardRepository {
  final Map<String, Flashcard> _storage = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Flashcard>>> getAll() async =>
      Result.success(_storage.values.toList());

  @override
  Future<Result<Flashcard?>> get(String id) async =>
      Result.success(_storage[id]);

  @override
  Future<Result<void>> save(String key, Flashcard item) async {
    _storage[key] = item;
    return Result.success(null);
  }

  @override
  Future<Result<void>> create(Flashcard flashcard) async {
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
          flashcardRepoProvider.overrideWithValue(_FakeFlashcardRepository()),
        ],
      );
      final repo = container.read(flashcardRepoProvider);
      expect(repo, isA<FlashcardRepository>());
    });

    test('flashcardReviewServiceProvider creates service with repo', () {
      final fakeRepo = _FakeFlashcardRepository();
      final container = ProviderContainer(
        overrides: [
          flashcardRepoProvider.overrideWithValue(fakeRepo),
        ],
      );
      final service = container.read(flashcardReviewServiceProvider);
      expect(service, isNotNull);
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
