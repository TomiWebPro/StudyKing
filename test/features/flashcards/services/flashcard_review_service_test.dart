import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/flashcards/services/flashcard_review_service.dart';

class _FakeFlashcardRepository extends FlashcardRepository {
  final Map<String, Flashcard> _storage = {};

  @override
  Future<Result<void>> init() async => Result.success(null);

  @override
  Future<Result<List<Flashcard>>> getAll() async {
    return Result.success(_storage.values.toList());
  }

  @override
  Future<Result<Flashcard?>> get(String id) async {
    return Result.success(_storage[id]);
  }

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
  Future<Result<List<Flashcard>>> getBySource(String sourceId) async {
    return Result.success(
      _storage.values.where((f) => f.sourceId == sourceId).toList(),
    );
  }

  @override
  Future<Result<List<Flashcard>>> getByTopic(String topicId) async {
    return Result.success(
      _storage.values.where((f) => f.topicId == topicId).toList(),
    );
  }

  @override
  Future<Result<List<Flashcard>>> getBySubject(String subjectId) async {
    return Result.success(
      _storage.values.where((f) => f.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<Result<List<Flashcard>>> getDueForReview({DateTime? asOf}) async {
    final reviewDate = asOf ?? DateTime.now();
    return Result.success(
      _storage.values.where((f) {
        final nextReview = f.nextReview;
        return nextReview == null || nextReview.isBefore(reviewDate);
      }).toList(),
    );
  }
}

Flashcard _createFlashcard({
  String id = 'fc_1',
  String sourceId = 'src_1',
  String topicId = 'topic_1',
  String subjectId = 'sub_1',
  DateTime? nextReview,
}) {
  final now = DateTime(2026, 7, 23);
  return Flashcard(
    id: id,
    sourceId: sourceId,
    topicId: topicId,
    subjectId: subjectId,
    front: 'What is $id?',
    back: 'Answer for $id',
    createdAt: now,
    updatedAt: now,
    nextReview: nextReview,
  );
}

void main() {
  group('FlashcardReviewService', () {
    late _FakeFlashcardRepository repo;
    late FlashcardReviewService service;

    setUp(() {
      repo = _FakeFlashcardRepository();
      service = FlashcardReviewService(flashcardRepository: repo);
    });

    group('getDueFlashcards', () {
      test('returns all flashcards when none have nextReview', () async {
        await repo.create(_createFlashcard(id: 'fc_1'));
        await repo.create(_createFlashcard(id: 'fc_2'));

        final result = await service.getDueFlashcards();
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 2);
      });

      test('returns only due flashcards', () async {
        await repo.create(_createFlashcard(
          id: 'fc_1',
          nextReview: DateTime(2020, 1, 1),
        ));
        await repo.create(_createFlashcard(
          id: 'fc_2',
          nextReview: DateTime(2099, 1, 1),
        ));

        final result = await service.getDueFlashcards(
          asOf: DateTime(2026, 7, 23),
        );
        expect(result.isSuccess, isTrue);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'fc_1');
      });

      test('filters by subjectId', () async {
        await repo.create(_createFlashcard(id: 'fc_1', subjectId: 'sub_1'));
        await repo.create(_createFlashcard(id: 'fc_2', subjectId: 'sub_2'));

        final result = await service.getDueFlashcards(subjectId: 'sub_1');
        expect(result.data?.length, 1);
        expect(result.data?.first.subjectId, 'sub_1');
      });

      test('filters by topicId', () async {
        await repo.create(_createFlashcard(id: 'fc_1', topicId: 't_1'));
        await repo.create(_createFlashcard(id: 'fc_2', topicId: 't_2'));

        final result = await service.getDueFlashcards(topicId: 't_1');
        expect(result.data?.length, 1);
        expect(result.data?.first.topicId, 't_1');
      });

      test('sorts by nextReview ascending', () async {
        await repo.create(_createFlashcard(
          id: 'fc_1',
          nextReview: DateTime(2026, 8, 1),
        ));
        await repo.create(_createFlashcard(
          id: 'fc_2',
          nextReview: DateTime(2026, 7, 1),
        ));

        final result = await service.getDueFlashcards(
          asOf: DateTime(2026, 9, 1),
        );
        expect(result.data?.first.id, 'fc_2');
        expect(result.data?.last.id, 'fc_1');
      });
    });

    group('recordReview', () {
      test('updates SR data and nextReview on flashcard', () async {
        await repo.create(_createFlashcard(id: 'fc_1'));

        final result = await service.recordReview(
          flashcardId: 'fc_1',
          grade: 4,
        );
        expect(result.isSuccess, isTrue);

        final updated = (await repo.get('fc_1')).data!;
        expect(updated.nextReview, isNotNull);
        expect(updated.nextReview!.isAfter(DateTime.now()), isTrue);
        expect(updated.srDataJson, isNotNull);
        expect(updated.mastery, 0.85);
      });

      test('returns failure for non-existent flashcard', () async {
        final result = await service.recordReview(
          flashcardId: 'none',
          grade: 3,
        );
        expect(result.isFailure, isTrue);
      });

      test('maps grade 5 to mastery 1.0', () async {
        await repo.create(_createFlashcard(id: 'fc_1'));
        await service.recordReview(flashcardId: 'fc_1', grade: 5);

        final updated = (await repo.get('fc_1')).data!;
        expect(updated.mastery, 1.0);
      });

      test('maps grade 3 to mastery 0.65', () async {
        await repo.create(_createFlashcard(id: 'fc_1'));
        await service.recordReview(flashcardId: 'fc_1', grade: 3);

        final updated = (await repo.get('fc_1')).data!;
        expect(updated.mastery, 0.65);
      });

      test('maps grade 0 to mastery 0.0', () async {
        await repo.create(_createFlashcard(id: 'fc_1'));
        await service.recordReview(flashcardId: 'fc_1', grade: 0);

        final updated = (await repo.get('fc_1')).data!;
        expect(updated.mastery, 0.0);
      });
    });

    group('getDueCount', () {
      test('returns correct count', () async {
        await repo.create(_createFlashcard(
          id: 'fc_1',
          subjectId: 'sub_1',
          nextReview: DateTime(2020, 1, 1),
        ));
        await repo.create(_createFlashcard(
          id: 'fc_2',
          subjectId: 'sub_1',
          nextReview: DateTime(2099, 1, 1),
        ));

        final result = await service.getDueCount(subjectId: 'sub_1');
        expect(result.isSuccess, isTrue);
        expect(result.data, 1);
      });

      test('returns zero when no due flashcards', () async {
        final result = await service.getDueCount(subjectId: 'empty');
        expect(result.data, 0);
      });
    });
  });
}
