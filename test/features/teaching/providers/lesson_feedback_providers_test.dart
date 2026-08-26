import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/teaching/data/models/lesson_feedback_model.dart';
import 'package:studyking/features/teaching/data/repositories/lesson_feedback_repository.dart';
import 'package:studyking/features/teaching/providers/lesson_feedback_providers.dart';

class _FakeRepo extends LessonFeedbackRepository {
  final List<LessonFeedbackModel> _store = [];

  @override
  Future<Result<List<LessonFeedbackModel>>> getReported() async {
    return Result.success(
        _store.where((f) => f.reportedIncorrect).toList());
  }

  void add(LessonFeedbackModel f) => _store.add(f);
}

class _FailingRepo extends LessonFeedbackRepository {
  @override
  Future<Result<List<LessonFeedbackModel>>> getReported() async {
    return Result.failure('boom');
  }
}

void main() {
  group('lesson feedback providers', () {
    test('lessonFeedbackRepositoryProvider returns a repository instance', () {
      final container = ProviderContainer();
      final repo = container.read(lessonFeedbackRepositoryProvider);
      expect(repo, isA<LessonFeedbackRepository>());
      container.dispose();
    });

    test('reportedLessonFeedbackProvider surfaces reported feedback '
        '(dependency wiring via override)', () async {
      final fake = _FakeRepo();
      fake.add(LessonFeedbackModel(
        id: 'r1',
        studentId: 's1',
        targetType: 'explanation',
        reportedIncorrect: true,
      ));
      fake.add(LessonFeedbackModel(
        id: 'r2',
        studentId: 's1',
        targetType: 'explanation',
        reportedIncorrect: false,
      ));

      final container = ProviderContainer(
        overrides: [
          lessonFeedbackRepositoryProvider.overrideWithValue(fake),
        ],
      );

      final reported =
          await container.read(reportedLessonFeedbackProvider.future);
      expect(reported, hasLength(1));
      expect(reported.first.id, 'r1');
      container.dispose();
    });

    test('reportedLessonFeedbackProvider degrades gracefully on failure',
        () async {
      final failing = _FailingRepo();
      final container = ProviderContainer(
        overrides: [
          lessonFeedbackRepositoryProvider.overrideWithValue(failing),
        ],
      );
      final reported =
          await container.read(reportedLessonFeedbackProvider.future);
      expect(reported, isEmpty);
      container.dispose();
    });
  });
}
