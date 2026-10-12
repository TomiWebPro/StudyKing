import '../../../core/errors/result.dart';
import '../../../core/utils/logger.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import '../../../core/data/models/topic_model.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import '../../../core/data/models/question_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class SyllabusTopicNode {
  final Topic topic;
  final TopicDependency? dependency;
  final MasteryState? mastery;
  final List<String> prerequisiteTopicIds;
  final bool isReady;
  final double priority;

  SyllabusTopicNode({
    required this.topic,
    this.dependency,
    this.mastery,
    this.prerequisiteTopicIds = const [],
    this.isReady = false,
    this.priority = 0.0,
  });
}

class SyllabusResolver {
  static final Logger _logger = const Logger('SyllabusResolver');
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
    AppLocalizations? l10n,
  }) async {
    try {
      await _topicRepository.init();
      final topicsResult = await _topicRepository.getBySubject(subjectId);
      final topics = topicsResult.data ?? [];
      if (topics.isEmpty) {
        return Result.failure(
          l10n?.noTopicsFoundForSubject(subjectId),
        );
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
              downstreamCount: dep.downstreamTopics.length,
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

      if (_containsCycle(nodes, topicMap)) {
        return Result.failure(
          l10n?.failedToResolveSyllabus('cyclic dependency detected') ??
              'Failed to resolve syllabus: cyclic dependency detected',
        );
      }

      final sortedNodes = _topologicalSort(nodes, topicMap);
      return Result.success(sortedNodes);
    } catch (e) {
      _logger.w('resolveSyllabus failed', e);
      return Result.failure(
        l10n?.failedToResolveSyllabus(e.toString()) ?? 'Failed to resolve syllabus: $e',
      );
    }
  }

  Future<Result<List<Question>>> getQuestionsForTopic(
    String topicId, {
    AppLocalizations? l10n,
  }) async {
    try {
      await _questionRepository.init();
      final allQuestionsResult = await _questionRepository.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final questions = allQuestions
          .where((q) => q.topicId == topicId)
          .toList();
      return Result.success(questions);
    } catch (e) {
      _logger.w('getQuestionsForTopic failed', e);
      return Result.failure(
        l10n?.failedToGetQuestionsForTopic(e.toString()) ?? 'Failed to get questions for topic: $e',
      );
    }
  }

  Future<Result<Map<String, List<Question>>>> getQuestionsForTopics(
    List<String> topicIds, {
    AppLocalizations? l10n,
  }) async {
    try {
      await _questionRepository.init();
      final allQuestionsResult = await _questionRepository.getAll();
      final allQuestions = allQuestionsResult.data ?? [];
      final result = <String, List<Question>>{};
      for (final topicId in topicIds) {
        result[topicId] = allQuestions
            .where((q) => q.topicId == topicId)
            .toList();
      }
      return Result.success(result);
    } catch (e) {
      _logger.w('getQuestionsForTopics failed', e);
      return Result.failure(
        l10n?.failedToGetQuestionsForTopics(e.toString()) ?? 'Failed to get questions for topics: $e',
      );
    }
  }

  bool _containsCycle(
    List<SyllabusTopicNode> nodes,
    Map<String, Topic> topicMap,
  ) {
    final visited = <String>{};
    final inProgress = <String>{};
    final nodeMap = {for (final n in nodes) n.topic.id: n};
    var hasCycle = false;

    void visit(String topicId) {
      if (visited.contains(topicId)) return;
      if (inProgress.contains(topicId)) {
        hasCycle = true;
        return;
      }
      inProgress.add(topicId);
      final node = nodeMap[topicId];
      if (node != null) {
        for (final prereqId in node.prerequisiteTopicIds) {
          if (topicMap.containsKey(prereqId)) visit(prereqId);
        }
      }
      inProgress.remove(topicId);
      visited.add(topicId);
    }

    for (final node in nodes) {
      visit(node.topic.id);
    }
    return hasCycle;
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

  /// Base minutes per topic used when a topic has no dependency record
  /// carrying its own `estimatedMinutes`.
  static const double _baseMinutesPerTopic = 45.0;

  /// Question volume above which the practice-time factor stops growing.
  static const int _questionCountCap = 40;

  /// Estimates the plan feasibility ratio (available minutes / needed
  /// minutes, clamped to 0..3) for a syllabus.
  ///
  /// When [topics] (the output of [resolveSyllabus]) is provided, the
  /// per-topic minutes are weighted by the data the flat 45-minute
  /// placeholder ignored: the dependency's own `estimatedMinutes` and
  /// `syllabusWeight` (difficulty), prerequisite depth, question volume
  /// ([questionCounts] or `TopicDependency.estimatedQuestions`), and
  /// current mastery (`MasteryState.accuracy` reduces remaining work).
  /// Without [topics] the flat base estimate is kept for compatibility.
  double estimateWorkload({
    required int totalTopics,
    required int targetDays,
    required int hoursPerDay,
    List<SyllabusTopicNode> topics = const [],
    Map<String, int> questionCounts = const {},
  }) {
    if (targetDays <= 0) return 0;
    final minutesPerDay = hoursPerDay * 60.0;
    final totalMinutesAvailable = targetDays * minutesPerDay;

    double minutesPerTopic;
    if (topics.isEmpty) {
      minutesPerTopic = _baseMinutesPerTopic;
    } else {
      final depths = _prerequisiteDepths(topics);
      var totalMinutes = 0.0;
      for (final node in topics) {
        totalMinutes += _estimatedTopicMinutes(
          node,
          questionCount: questionCounts[node.topic.id] ??
              node.dependency?.estimatedQuestions ??
              0,
          prerequisiteDepth: depths[node.topic.id] ?? 0,
        );
      }
      minutesPerTopic = totalMinutes / topics.length;
    }

    final totalMinutesNeeded = totalTopics * minutesPerTopic;
    return (totalMinutesAvailable / totalMinutesNeeded).clamp(0.0, 3.0);
  }

  /// Weighted minutes for a single topic.
  double _estimatedTopicMinutes(
    SyllabusTopicNode node, {
    required int questionCount,
    required int prerequisiteDepth,
  }) {
    final dependency = node.dependency;
    final baseMinutes = (dependency != null && dependency.estimatedMinutes > 0)
        ? dependency.estimatedMinutes.toDouble()
        : _baseMinutesPerTopic;
    // Difficulty: the syllabus weight of the topic (1.0 = average).
    final difficultyFactor =
        (dependency?.syllabusWeight ?? 1.0).clamp(0.25, 3.0);
    // Dependency depth: topics deeper in a prerequisite chain build on
    // more accumulated context and need proportionally more time.
    final depthFactor = (1.0 + 0.1 * prerequisiteDepth).clamp(1.0, 1.5);
    // Practice volume: more questions means more practice time.
    final questionFactor = (1.0 +
        (questionCount.clamp(0, _questionCountCap) / _questionCountCap))
        .clamp(1.0, 2.0);
    // Mastery: the more the student already masters the topic, the less
    // work remains (floored so a mastered topic still costs review time).
    final accuracy = (node.mastery?.accuracy ?? 0.0).clamp(0.0, 1.0);
    final masteryFactor = (1.0 - 0.75 * accuracy).clamp(0.25, 1.0);

    return baseMinutes *
        difficultyFactor *
        depthFactor *
        questionFactor *
        masteryFactor;
  }

  /// Longest prerequisite-chain depth for each topic in [topics],
  /// counting only prerequisites that are part of [topics] itself.
  /// Cyclic prerequisite lists (rejected by [resolveSyllabus]) are
  /// guarded against so this always terminates.
  Map<String, int> _prerequisiteDepths(List<SyllabusTopicNode> topics) {
    final nodesById = {for (final n in topics) n.topic.id: n};
    final depths = <String, int>{};
    final visiting = <String>{};

    int depthOf(SyllabusTopicNode node) {
      final cached = depths[node.topic.id];
      if (cached != null) return cached;
      if (visiting.contains(node.topic.id)) return 0;
      visiting.add(node.topic.id);
      var maxPrereqDepth = 0;
      for (final prereqId in node.prerequisiteTopicIds) {
        final prereq = nodesById[prereqId];
        if (prereq == null) continue;
        final prereqDepth = 1 + depthOf(prereq);
        if (prereqDepth > maxPrereqDepth) {
          maxPrereqDepth = prereqDepth;
        }
      }
      visiting.remove(node.topic.id);
      depths[node.topic.id] = maxPrereqDepth;
      return maxPrereqDepth;
    }

    for (final node in topics) {
      depthOf(node);
    }
    return depths;
  }
}
