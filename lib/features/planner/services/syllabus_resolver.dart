import '../../../core/errors/result.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/data/repositories/topic_repository.dart';
import '../../../core/data/repositories/mastery_graph_repository.dart';
import '../../../core/data/repositories/question_repository.dart';
import '../../../core/data/models/topic_model.dart';
import '../../../core/data/models/topic_dependency_model.dart';
import '../../../core/data/models/question_model.dart';
import '../../../core/data/models/mastery_state_model.dart';

class SyllabusTopicNode {
  final Topic topic;
  final TopicDependency? dependency;
  final MasteryState? mastery;
  final List<String> prerequisiteTopicIds;
  final List<SyllabusTopicNode> prerequisites;
  final bool isReady;
  final double priority;

  SyllabusTopicNode({
    required this.topic,
    this.dependency,
    this.mastery,
    this.prerequisiteTopicIds = const [],
    this.prerequisites = const [],
    this.isReady = false,
    this.priority = 0.0,
  });
}

class SyllabusResolver {
  final TopicRepository _topicRepository;
  final MasteryGraphRepository _masteryRepository;
  final QuestionRepository _questionRepository;

  SyllabusResolver({
    TopicRepository? topicRepository,
    MasteryGraphRepository? masteryRepository,
    QuestionRepository? questionRepository,
  })  : _topicRepository = topicRepository ?? TopicRepository(),
        _masteryRepository = masteryRepository ?? MasteryGraphRepository(),
        _questionRepository = questionRepository ?? QuestionRepository();

  Future<Result<List<SyllabusTopicNode>>> resolveSyllabus({
    required String subjectId,
    String? studentId,
  }) async {
    try {
      await _topicRepository.init();
      final topics = await _topicRepository.getBySubject(subjectId);
      if (topics.isEmpty) {
        return Result.failure('No topics found for subject $subjectId');
      }

      final depsResult = await _masteryRepository.getAllDependencies();
      final dependencyMap = <String, TopicDependency>{};
      if (depsResult.isSuccess) {
        for (final dep in depsResult.data!) {
          dependencyMap[dep.topicId] = dep;
        }
      }

      Map<String, MasteryState> masteryMap = {};
      if (studentId != null) {
        final masteryResult = await _masteryRepository.getAllMasteryStates(studentId);
        if (masteryResult.isSuccess) {
          for (final state in masteryResult.data!) {
            masteryMap[state.topicId] = state;
          }
        }
      }

      final topicMap = {for (final t in topics) t.id: t};

      final nodes = <SyllabusTopicNode>[];
      for (final topic in topics) {
        final dep = dependencyMap[topic.id];
        final mastery = masteryMap[topic.id];
        final prereqs = dep?.prerequisites ?? [];
        final completedTopicIds = masteryMap.values
            .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
            .map((s) => s.topicId)
            .toSet();
        final isReady = dep?.isReady(
              completedTopicIds.toList(),
              mastery?.readinessScore ?? 0.0,
            ) ??
            true;
        final priority = dep?.calculatePriority(
              masteryState: mastery?.accuracy ?? 0.0,
              isPrerequisite: prereqs.any((p) => !completedTopicIds.contains(p)),
              downstreamCount: dep?.downstreamTopics.length ?? 0, // ignore: invalid_null_aware_operator
            ) ??
            (1 - (mastery?.accuracy ?? 0.0));

        nodes.add(SyllabusTopicNode(
          topic: topic,
          dependency: dep,
          mastery: mastery,
          prerequisiteTopicIds: prereqs,
          isReady: isReady,
          priority: priority,
        ));
      }

      for (final node in nodes) {
        final prereqNodes = <SyllabusTopicNode>[];
        for (final prereqId in node.prerequisiteTopicIds) {
          final prereqTopic = topicMap[prereqId];
          if (prereqTopic != null) {
            final prereqNode = nodes.firstWhere(
              (n) => n.topic.id == prereqId,
              orElse: () => SyllabusTopicNode(topic: prereqTopic),
            );
            prereqNodes.add(prereqNode);
          }
        }
      }

      final sortedNodes = _topologicalSort(nodes, topicMap);
      return Result.success(sortedNodes);
    } on SyllabusException {
      rethrow;
    } catch (e) {
      return Result.failure('Failed to resolve syllabus: $e');
    }
  }

  Future<Result<List<Question>>> getQuestionsForTopic(String topicId) async {
    try {
      await _questionRepository.init();
      final result = await _questionRepository.getAll();
      if (result.isFailure) return Result.failure(result.error);
      final questions = result.data!
          .where((q) => q.topicId == topicId)
          .toList();
      return Result.success(questions);
    } catch (e) {
      return Result.failure('Failed to get questions for topic: $e');
    }
  }

  Future<Result<Map<String, List<Question>>>> getQuestionsForTopics(
    List<String> topicIds,
  ) async {
    try {
      await _questionRepository.init();
      final allResult = await _questionRepository.getAll();
      if (allResult.isFailure) return Result.failure(allResult.error);
      final allQuestions = allResult.data!;
      final result = <String, List<Question>>{};
      for (final topicId in topicIds) {
        result[topicId] = allQuestions
            .where((q) => q.topicId == topicId)
            .toList();
      }
      return Result.success(result);
    } catch (e) {
      return Result.failure('Failed to get questions for topics: $e');
    }
  }

  List<SyllabusTopicNode> _topologicalSort(
    List<SyllabusTopicNode> nodes,
    Map<String, Topic> topicMap,
  ) {
    final visited = <String>{};
    final sorted = <SyllabusTopicNode>[];
    final nodeMap = {for (final n in nodes) n.topic.id: n};

    void visit(String topicId) {
      if (visited.contains(topicId)) return;
      visited.add(topicId);
      final node = nodeMap[topicId];
      if (node != null) {
        for (final prereqId in node.prerequisiteTopicIds) {
          if (topicMap.containsKey(prereqId)) {
            visit(prereqId);
          }
        }
        sorted.add(node);
      }
    }

    for (final node in nodes) {
      visit(node.topic.id);
    }

    return sorted;
  }

  List<List<String>> buildLearningLevels(List<SyllabusTopicNode> nodes) {
    final visited = <String>{};
    final levels = <List<String>>[];
    final allIds = nodes.map((n) => n.topic.id).toSet();

    while (visited.length < allIds.length) {
      final currentLevel = <String>[];
      for (final node in nodes) {
        if (visited.contains(node.topic.id)) continue;
        final prereqsMet = node.prerequisiteTopicIds
            .every((p) => !allIds.contains(p) || visited.contains(p));
        if (prereqsMet) {
          currentLevel.add(node.topic.id);
        }
      }
      if (currentLevel.isEmpty) break;
      visited.addAll(currentLevel);
      levels.add(currentLevel);
    }

    return levels;
  }

  double estimateWorkload({
    required int totalTopics,
    required int targetDays,
    required int hoursPerDay,
  }) {
    if (targetDays <= 0) return 0;
    final minutesPerDay = hoursPerDay * 60.0;
    final minutesPerTopic = 45.0;
    final totalMinutesNeeded = totalTopics * minutesPerTopic;
    final totalMinutesAvailable = targetDays * minutesPerDay;
    return (totalMinutesAvailable / totalMinutesNeeded).clamp(0.0, 3.0);
  }
}
