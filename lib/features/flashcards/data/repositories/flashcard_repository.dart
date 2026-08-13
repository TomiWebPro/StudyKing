import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';

class FlashcardRepository extends Repository<Flashcard> {
  FlashcardRepository() : super(boxName: HiveBoxNames.flashcards);

  Future<Result<void>> init() async {
    try {
      await openBox(HiveBoxNames.flashcards);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> create(Flashcard flashcard) async {
    return super.put(flashcard.id, flashcard);
  }

  Future<Result<List<Flashcard>>> getBySource(String sourceId) async {
    return Result.captureSync(
      () => filterBy((f) => f.sourceId, sourceId),
      context: 'getBySource',
    );
  }

  Future<Result<List<Flashcard>>> getByTopic(String topicId) async {
    return Result.captureSync(
      () => filterBy((f) => f.topicId, topicId),
      context: 'getByTopic',
    );
  }

  Future<Result<List<Flashcard>>> getBySubject(String subjectId) async {
    return Result.captureSync(
      () => filterBy((f) => f.subjectId, subjectId),
      context: 'getBySubject',
    );
  }

  Future<Result<List<Flashcard>>> getDueForReview({DateTime? asOf}) async {
    return Result.capture(() async {
      final reviewDate = asOf ?? DateTime.now();
      final allResult = await getAll();
      final all = allResult.data ?? [];
      return all.where((f) {
        final nextReview = f.nextReview;
        return nextReview == null || nextReview.isBefore(reviewDate);
      }).toList();
    }, context: 'getDueForReview');
  }

  Future<Result<int>> getDueCount(String subjectId, {DateTime? asOf}) async {
    return Result.capture(() async {
      final reviewDate = asOf ?? DateTime.now();
      final all = box.values.toList();
      return all.where((f) =>
          f.subjectId == subjectId &&
          (f.nextReview == null || f.nextReview!.isBefore(reviewDate))
      ).length;
    }, context: 'getDueCount');
  }
}
