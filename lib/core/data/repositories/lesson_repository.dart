import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson_model.dart';
import '../models/lesson_block_model.dart';

class LessonRepository {
  late Box<Lesson> _box;
  late Box<LessonBlock> _blockBox;

  Future<void> init() async {
    _box = Hive.box<Lesson>('lessons');
    _blockBox = Hive.box<LessonBlock>('lessonBlocks');
  }

  Future<void> create(Lesson lesson) async {
    await _box.put(lesson.id, lesson);
  }

  Future<Lesson?> get(String id) async {
    return _box.get(id);
  }

  Future<List<Lesson>> getAll() async {
    return _box.values.toList();
  }

  Future<List<Lesson>> getBySubject(String subjectId) async {
    final all = _box.values.toList();
    return all.where((l) => l.subjectId == subjectId).toList();
  }

  Future<List<Lesson>> getByTopic(String topicId) async {
    final all = _box.values.toList();
    return all.where((l) => l.topicId == topicId).toList();
  }

  Future<List<Lesson>> getBySubjectAndTopic(String subjectId, String topicId) async {
    final all = _box.values.toList();
    return all.where((l) => 
      l.subjectId == subjectId && l.topicId == topicId
    ).toList();
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

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
