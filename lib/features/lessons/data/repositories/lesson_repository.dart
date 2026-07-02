import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class LessonRepository extends Repository<Lesson> {
  LessonRepository() : super(boxName: HiveBoxNames.lessons);
  static final Logger _logger = const Logger('LessonRepository');

  Future<void> init() async {
    await openBox(HiveBoxNames.lessons);
  }

  Future<Result<void>> create(Lesson lesson) async {
    try {
      await save(lesson.id, lesson);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error creating lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Lesson>>> getBySubject(String subjectId) async {
    try {
      return Result.success(filterBy((l) => l.subjectId, subjectId));
    } catch (e) {
      _logger.w('Error getting lessons by subject', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Lesson>>> getByTopic(String topicId) async {
    try {
      return Result.success(filterBy((l) => l.topicId, topicId));
    } catch (e) {
      _logger.w('Error getting lessons by topic', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Lesson>>> getBySubjectAndTopic(
      String subjectId, String topicId) async {
    try {
      final bySubject = filterBy((l) => l.subjectId, subjectId);
      return Result.success(bySubject.where((l) => l.topicId == topicId).toList());
    } catch (e) {
      _logger.w('Error getting lessons by subject and topic', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> addBlock(LessonBlock block) async {
    try {
      final lessonResult = await get(block.lessonId);
      final lesson = lessonResult.data;
      if (lesson == null) {
        return Result.failure('Lesson_not_found: ${block.lessonId}');
      }
      final updated = lesson.copyWith(blocks: [...lesson.blocks, block]);
      await save(lesson.id, updated);
      return Result.success(null);
    } catch (e) {
      _logger.w('Error adding block to lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<LessonBlock>>> getBlocksForLesson(String lessonId) async {
    try {
      final lessonResult = await get(lessonId);
      final lesson = lessonResult.data;
      if (lesson == null) {
        return Result.success([]);
      }
      return Result.success(lesson.blocks);
    } catch (e) {
      _logger.w('Error getting blocks for lesson', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<LessonBlock>>> getBlocksBySubject(String subjectId) async {
    try {
      final lessonsResult = await getAll();
      final lessons = lessonsResult.data ?? [];
      final blocks = lessons
          .expand((l) => l.blocks)
          .where((b) => b.subjectId == subjectId)
          .toList();
      return Result.success(blocks);
    } catch (e) {
      _logger.w('Error getting blocks by subject', e);
      return Result.failure(e.toString());
    }
  }
}
