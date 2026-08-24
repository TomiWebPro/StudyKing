import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';

final lessonFeedbackRepositoryProvider =
    Provider<LessonFeedbackRepository>((ref) {
  return LessonFeedbackRepository();
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
