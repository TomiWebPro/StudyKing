import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/teaching/services/feedback_analyzer.dart';

final lessonFeedbackRepositoryProvider =
    Provider<LessonFeedbackRepository>((ref) {
  return LessonFeedbackRepository();
});

final feedbackAnalyzerProvider = Provider<FeedbackAnalyzer>((ref) {
  return FeedbackAnalyzer(ref.watch(lessonFeedbackRepositoryProvider));
});

/// Feedback items the mentor/dashboard should treat as needing review:
/// anything reported as incorrect, or rated 2 stars or below.
final lessonFeedbackNeedsReviewProvider =
    FutureProvider.autoDispose<List<LessonFeedbackModel>>((ref) async {
  final repo = ref.watch(lessonFeedbackRepositoryProvider);
  final reportedResult = await repo.getReported();
  final reported = reportedResult.fold(
    (data) => data,
    (error) => <LessonFeedbackModel>[],
  );
  final allResult = await repo.getAll();
  final lowRated = allResult.fold(
    (data) => data.where((f) => f.starRating > 0 && f.starRating <= 2).toList(),
    (error) => <LessonFeedbackModel>[],
  );
  final seen = <String>{};
  final merged = <LessonFeedbackModel>[
    ...reported,
    ...lowRated,
  ].where((f) => seen.add(f.id)).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
});

final reportedLessonFeedbackProvider =
    FutureProvider.autoDispose<List<LessonFeedbackModel>>((ref) async {
  final repo = ref.watch(lessonFeedbackRepositoryProvider);
  final result = await repo.getReported();
  return result.fold(
    (data) => data,
    (error) {
      return <LessonFeedbackModel>[];
    },
  );
});
