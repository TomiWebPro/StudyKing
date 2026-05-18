import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
class _FakeLessonRepo extends LessonRepository {
  final List<Lesson> _lessons = [];
  bool shouldThrow = false;

  @override
  Future<Result<List<Lesson>>> getAll() async =>
      shouldThrow ? Result.failure('error') : Result.success(_lessons);

  @override
  Future<Result<Lesson?>> get(String id) async =>
      Result.success(_lessons.where((l) => l.id == id).firstOrNull);

  @override
  Future<void> init() async {}
}

void main() {
  group('Ingestion → Lessons integration', () {
    test('lesson repo stores and retrieves lessons after generation', () async {
      final lessonRepo = _FakeLessonRepo();

      final lesson = Lesson(
        id: 'lesson-1',
        subjectId: 's1',
        topicId: 't1',
        title: 'Algebra Basics',
        createdAt: DateTime.now(),
      );

      final saveResult = await lessonRepo.save(lesson.id, lesson);
      expect(saveResult.isSuccess, isTrue);

      final allLessons = await lessonRepo.getAll();
      expect(allLessons.isSuccess, isTrue);
      expect(allLessons.data!.length, 1);
      expect(allLessons.data!.first.title, 'Algebra Basics');
    });

    test('handles error when lesson repo is unavailable', () async {
      final lessonRepo = _FakeLessonRepo();
      lessonRepo.shouldThrow = true;

      final result = await lessonRepo.getAll();
      expect(result.isFailure, isTrue);
      expect(result.error, isNotEmpty);
    });

    test('recovers after lesson repo error', () async {
      final lessonRepo = _FakeLessonRepo();

      final lesson = Lesson(
        id: 'lesson-2',
        subjectId: 's1',
        topicId: 't1',
        title: 'Recovery Lesson',
        createdAt: DateTime.now(),
      );
      await lessonRepo.save(lesson.id, lesson);

      lessonRepo.shouldThrow = true;
      final errorResult = await lessonRepo.getAll();
      expect(errorResult.isFailure, isTrue);

      lessonRepo.shouldThrow = false;
      final recoveryResult = await lessonRepo.getAll();
      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.data!.length, 1);
    });
  });
}
