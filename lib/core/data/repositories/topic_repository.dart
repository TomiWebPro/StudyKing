import 'package:hive_flutter/hive_flutter.dart';
import '../models/topic_model.dart';

class TopicRepository {
  late Box<Topic> _box;

  Future<void> init() async {
    _box = Hive.box<Topic>('topics');
  }

  Future<void> create(Topic topic) async {
    await _box.put(topic.id, topic);
  }

  Future<Topic?> get(String id) async {
    return _box.get(id);
  }

  Future<List<Topic>> getAll() async {
    return _box.values.toList();
  }

  Future<List<Topic>> getBySubject(String subjectId) async {
    final all = _box.values.toList();
    return all.where((t) => t.subjectId == subjectId).toList();
  }

  Future<List<Topic>> getByParent(String parentId) async {
    final all = _box.values.toList();
    return all.where((t) => t.parentId == parentId).toList();
  }

  Future<List<Topic>> getRootTopics() async {
    final all = _box.values.toList();
    return all.where((t) => t.parentId == null).toList();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> addParent(Topic topic, String parentId) async {
    final parent = await get(parentId);
    if (parent != null) {
      topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
      await create(topic);
    }
  }
}
