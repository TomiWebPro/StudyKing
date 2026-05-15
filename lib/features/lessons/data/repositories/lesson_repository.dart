import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/lesson_model.dart';
import 'package:studyking/core/data/models/lesson_block_model.dart';
import 'package:studyking/core/data/repository.dart';

class LessonRepository extends Repository<Lesson> {
  late Box<LessonBlock> _blockBox;

  Future<void> init() async {
    await openBox(HiveBoxNames.lessons);
    _blockBox = await Hive.openBox<LessonBlock>(HiveBoxNames.lessonBlocks);
  }

  Future<void> create(Lesson lesson) async {
    await save(lesson.id, lesson);
  }

  Future<List<Lesson>> getBySubject(String subjectId) async {
    return filterBy((l) => l.subjectId, subjectId);
  }

  Future<List<Lesson>> getByTopic(String topicId) async {
    return filterBy((l) => l.topicId, topicId);
  }

  Future<List<Lesson>> getBySubjectAndTopic(
      String subjectId, String topicId) async {
    final bySubject = filterBy((l) => l.subjectId, subjectId);
    return bySubject.where((l) => l.topicId == topicId).toList();
  }

  Future<void> addBlock(LessonBlock block) async {
    await _blockBox.put(block.id, block);
  }

  Future<List<LessonBlock>> getBlocksForLesson(String lessonId) async {
    final all = _blockBox.values.toList();
    return all.where((b) => b.lessonId == lessonId).toList();
  }

  Future<List<LessonBlock>> getBlocksBySubject(String subjectId) async {
    final all = _blockBox.values.toList();
    return all.where((b) => b.subjectId == subjectId).toList();
  }
}
