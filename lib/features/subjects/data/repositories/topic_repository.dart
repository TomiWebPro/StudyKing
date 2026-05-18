import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';

class TopicRepository extends Repository<Topic> {
  Future<Result<void>> init() async {
    try {
      await openBox(HiveBoxNames.topics);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> create(Topic topic) async {
    return super.put(topic.id, topic);
  }

  Future<Result<List<Topic>>> getBySubject(String subjectId) async {
    return Result.captureSync(
      () => filterBy((t) => t.subjectId, subjectId),
      context: 'getBySubject',
    );
  }

  Future<Result<List<Topic>>> getByParent(String parentId) async {
    return Result.captureSync(
      () => filterBy((t) => t.parentId, parentId),
      context: 'getByParent',
    );
  }

  Future<Result<List<Topic>>> getRootTopics() async {
    return Result.capture(() async {
      final getAllResult = await getAll();
      final all = getAllResult.data ?? [];
      return all.where((t) => t.parentId == null).toList();
    }, context: 'getRootTopics');
  }

  Future<Result<void>> addParent(Topic topic, String parentId) async {
    return Result.capture(() async {
      final getResult = await get(parentId);
      final parent = getResult.data;
      if (parent != null) {
        final updated =
            topic.copyWith(parentId: parentId, subjectId: parent.subjectId);
        await create(updated);
      }
    }, context: 'addParent');
  }
}
