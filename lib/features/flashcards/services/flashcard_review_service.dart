import 'dart:convert';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/flashcards/data/models/flashcard_model.dart';
import 'package:studyking/features/flashcards/data/repositories/flashcard_repository.dart';
import 'package:studyking/features/practice/services/spaced_repetition_engine.dart';

class FlashcardReviewService {
  static final Logger _logger = const Logger('FlashcardReviewService');
  final FlashcardRepository _flashcardRepository;
  final SpacedRepetitionEngine _srEngine;

  FlashcardReviewService({
    required FlashcardRepository flashcardRepository,
    SpacedRepetitionEngine? srEngine,
  })  : _flashcardRepository = flashcardRepository,
        _srEngine = srEngine ?? SpacedRepetitionEngine();

  Future<Result<List<Flashcard>>> getDueFlashcards({
    String? subjectId,
    String? topicId,
    DateTime? asOf,
  }) async {
    try {
      final reviewDate = asOf ?? DateTime.now();
      final allResult = await _flashcardRepository.getAll();
      final all = allResult.data ?? [];

      final due = all.where((f) {
        final nextReview = f.nextReview;
        final isDue = nextReview == null || nextReview.isBefore(reviewDate);
        if (subjectId != null && f.subjectId != subjectId) return false;
        if (topicId != null && f.topicId != topicId) return false;
        return isDue;
      }).toList();

      due.sort((a, b) =>
          (a.nextReview ?? DateTime(0)).compareTo(b.nextReview ?? DateTime(0)));

      return Result.success(due);
    } catch (e) {
      _logger.w('Failed to get due flashcards', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> recordReview({
    required String flashcardId,
    required int grade,
  }) async {
    try {
      final getResult = await _flashcardRepository.get(flashcardId);
      final flashcard = getResult.data;
      if (flashcard == null) {
        return Result.failure('Flashcard not found');
      }

      final srData = _deserializeSrData(flashcard.srDataJson);
      final srResult = _srEngine.scheduleReview(
        questionId: flashcardId,
        grade: grade,
        currentData: srData,
      );

      final updated = flashcard.copyWith(
        nextReview: srResult.nextReview,
        srDataJson: _serializeSrData(srResult.updatedData),
        mastery: _gradeToMastery(grade),
        updatedAt: DateTime.now(),
      );

      await _flashcardRepository.save(flashcardId, updated);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to record flashcard review', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<int>> getDueCount({
    String? subjectId,
    String? topicId,
  }) async {
    final result = await getDueFlashcards(
      subjectId: subjectId,
      topicId: topicId,
    );
    return result.map((list) => list.length);
  }

  double _gradeToMastery(int grade) {
    if (grade >= 5) return 1.0;
    if (grade >= 4) return 0.85;
    if (grade >= 3) return 0.65;
    if (grade >= 2) return 0.4;
    if (grade >= 1) return 0.2;
    return 0.0;
  }

  QuestionSRData _deserializeSrData(String? json) {
    if (json == null || json.isEmpty) return const QuestionSRData();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return QuestionSRData(
        repetitions: map['r'] as int? ?? 0,
        easeFactor: (map['ef'] as num?)?.toDouble() ?? 2.5,
        previousInterval: map['pi'] != null
            ? Duration(milliseconds: map['pi'] as int)
            : null,
        lastReview: map['lr'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lr'] as int)
            : null,
      );
    } catch (e) {
      _logger.w('Error deserializing flashcard SR data', e);
      return const QuestionSRData();
    }
  }

  String _serializeSrData(QuestionSRData data) {
    return jsonEncode({
      'r': data.repetitions,
      'ef': data.easeFactor,
      if (data.previousInterval != null) 'pi': data.previousInterval!.inMilliseconds,
      if (data.lastReview != null) 'lr': data.lastReview!.millisecondsSinceEpoch,
    });
  }
}
