import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class LessonRepository extends Repository<Lesson> {
  final Logger _logger = const Logger('LessonRepository');
  late Box<LessonBlock> _blockBox;

  Future<void> init() async {
    try {
      await openBox(HiveBoxNames.lessons);
      _blockBox = await Hive.openBox<LessonBlock>(HiveBoxNames.lessonBlocks);
    } catch (e) {
      _logger.e('Error initializing lesson repository', e);
      rethrow;
    }
  }

  Future<Result<void>> create(Lesson lesson) async {
    try {
      await save(lesson.id, lesson);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error creating lesson', e);
      return Result.failure('Failed to create lesson: ${e.toString()}');
    }
  }

  Future<Result<List<Lesson>>> getBySubject(String subjectId) async {
    try {
      return Result.success(filterBy((l) => l.subjectId, subjectId));
    } catch (e) {
      _logger.e('Error getting lessons by subject', e);
      return Result.failure('Failed to get lessons: ${e.toString()}');
    }
  }

  Future<Result<List<Lesson>>> getByTopic(String topicId) async {
    try {
      return Result.success(filterBy((l) => l.topicId, topicId));
    } catch (e) {
      _logger.e('Error getting lessons by topic', e);
      return Result.failure('Failed to get lessons: ${e.toString()}');
    }
  }

  Future<Result<List<Lesson>>> getBySubjectAndTopic(
      String subjectId, String topicId) async {
    try {
      final bySubject = filterBy((l) => l.subjectId, subjectId);
      return Result.success(bySubject.where((l) => l.topicId == topicId).toList());
    } catch (e) {
      _logger.e('Error getting lessons by subject and topic', e);
      return Result.failure('Failed to get lessons: ${e.toString()}');
    }
  }

  Future<Result<void>> addBlock(LessonBlock block) async {
    try {
      await _blockBox.put(block.id, block);
      return Result.success(null);
    } catch (e) {
      _logger.e('Error adding lesson block', e);
      return Result.failure('Failed to add lesson block: ${e.toString()}');
    }
  }

  Future<Result<List<LessonBlock>>> getBlocksForLesson(String lessonId) async {
    try {
      final all = _blockBox.values.toList();
      return Result.success(all.where((b) => b.lessonId == lessonId).toList());
    } catch (e) {
      _logger.e('Error getting blocks for lesson', e);
      return Result.failure('Failed to get blocks: ${e.toString()}');
    }
  }

  Future<Result<List<LessonBlock>>> getBlocksBySubject(String subjectId) async {
    try {
      final all = _blockBox.values.toList();
      return Result.success(all.where((b) => b.subjectId == subjectId).toList());
    } catch (e) {
      _logger.e('Error getting blocks by subject', e);
      return Result.failure('Failed to get blocks: ${e.toString()}');
    }
  }
}
