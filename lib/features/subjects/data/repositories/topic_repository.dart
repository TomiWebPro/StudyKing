import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repository.dart';

class TopicRepository extends Repository<Topic> {
  Future<void> init() async {
    await openBox(HiveBoxNames.topics);
  }

  Future<void> create(Topic topic) async {
    await save(topic.id, topic);
  }

  Future<List<Topic>> getBySubject(String subjectId) async {
    return filterBy((t) => t.subjectId, subjectId);
  }

  Future<List<Topic>> getByParent(String parentId) async {
    return filterBy((t) => t.parentId, parentId);
  }

  Future<List<Topic>> getRootTopics() async {
    final getAllResult = await getAll();
    final all = getAllResult.data ?? [];
    return all.where((t) => t.parentId == null).toList();
  }

  Future<void> addParent(Topic topic, String parentId) async {
    final getResult = await get(parentId);
    final parent = getResult.data;
    if (parent != null) {
      final updated =
          topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
      await create(updated);
    }
  }
}
