import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';

class TopicRepository extends Repository<Topic> {
  TopicRepository() : super(boxName: HiveBoxNames.topics);

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

  Future<Result<Map<String, List<String>>>> getDependencyGraph(
    List<String> topicIds,
    Map<String, List<String>> dependencies,
  ) async {
    return Result.captureSync(() {
      final graph = <String, List<String>>{};
      for (final id in topicIds) {
        graph[id] = dependencies[id] ?? [];
      }
      return graph;
    }, context: 'getDependencyGraph');
  }

  Future<Result<List<String>>> getTopologicalOrder(
    List<String> topicIds,
    Map<String, List<String>> dependencies,
  ) async {
    return Result.captureSync(() {
      final inDegree = <String, int>{};
      final adj = <String, List<String>>{};

      for (final id in topicIds) {
        inDegree[id] = 0;
        adj[id] = [];
      }

      for (final entry in dependencies.entries) {
        final prereqs = entry.value;
        for (final prereq in prereqs) {
          adj.putIfAbsent(prereq, () => []).add(entry.key);
          inDegree[entry.key] = (inDegree[entry.key] ?? 0) + 1;
        }
      }

      final queue = <String>[];
      for (final id in topicIds) {
        if ((inDegree[id] ?? 0) == 0) {
          queue.add(id);
        }
      }

      final order = <String>[];
      while (queue.isNotEmpty) {
        final node = queue.removeAt(0);
        order.add(node);
        for (final neighbor in adj[node] ?? []) {
          inDegree[neighbor] = (inDegree[neighbor] ?? 1) - 1;
          if ((inDegree[neighbor] ?? 0) == 0) {
            queue.add(neighbor);
          }
        }
      }

      return order;
    }, context: 'getTopologicalOrder');
  }

  Future<Result<List<String>>> getDownstreamTopicIds(
    String topicId,
    Map<String, List<String>> dependencies,
  ) async {
    return Result.captureSync(() {
      final visited = <String>{};
      final downstream = <String>[];

      void dfs(String current) {
        for (final entry in dependencies.entries) {
          if (entry.value.contains(current) && !visited.contains(entry.key)) {
            visited.add(entry.key);
            downstream.add(entry.key);
            dfs(entry.key);
          }
        }
      }

      dfs(topicId);
      return downstream;
    }, context: 'getDownstreamTopicIds');
  }
}
