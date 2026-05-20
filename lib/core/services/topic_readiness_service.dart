import '../errors/result.dart';
import '../utils/logger.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';

class TopicReadinessResult {
  final String topicId;
  final String topicTitle;
  final TopicDependency? dependency;
  final MasteryState? mastery;
  final bool isReady;
  final double priority;
  final List<String> unmetPrerequisites;

  const TopicReadinessResult({
    required this.topicId,
    required this.topicTitle,
    this.dependency,
    this.mastery,
    required this.isReady,
    required this.priority,
    this.unmetPrerequisites = const [],
  });
}

class TopicReadinessService {
  static final Logger _logger = const Logger('TopicReadinessService');
  final MasteryGraphRepository _masteryRepository;
  final TopicRepository _topicRepository;

  TopicReadinessService({
    MasteryGraphRepository? masteryRepository,
    TopicRepository? topicRepository,
  })  : _masteryRepository = masteryRepository ?? MasteryGraphRepository(),
        _topicRepository = topicRepository ?? TopicRepository();

  Future<Result<List<TopicReadinessResult>>> getReadyTopics({
    required String subjectId,
    required String studentId,
    double masteryThreshold = 0.6,
  }) async {
    try {
      await _topicRepository.init();
      await _masteryRepository.init();

      final topicsResult = await _topicRepository.getBySubject(subjectId);
      final topics = topicsResult.data ?? [];
      if (topics.isEmpty) {
        return Result.success([]);
      }

      final depsResult = await _masteryRepository.getAllDependencies();
      final dependencyMap = <String, TopicDependency>{};
      if (depsResult.isSuccess) {
        for (final dep in depsResult.data!) {
          dependencyMap[dep.topicId] = dep;
        }
      }

      final masteryResult = await _masteryRepository.getAllMasteryStates(studentId);
      final masteryMap = <String, MasteryState>{};
      if (masteryResult.isSuccess) {
        for (final state in masteryResult.data!) {
          masteryMap[state.topicId] = state;
        }
      }

      final proficientTopicIds = masteryMap.values
          .where((s) => s.masteryLevel.index >= MasteryLevel.proficient.index)
          .map((s) => s.topicId)
          .toSet();

      final results = <TopicReadinessResult>[];
      for (final topic in topics) {
        final dep = dependencyMap[topic.id];
        final mastery = masteryMap[topic.id];
        final prereqs = dep?.prerequisites ?? [];

        final unmetPrereqs = prereqs.where((p) =>
            !proficientTopicIds.contains(p)).toList();

        final isReady = dep?.isReady(
              proficientTopicIds.toList(),
              mastery?.readinessScore ?? 0.0,
            ) ??
            true;

        final priority = dep?.calculatePriority(
              masteryState: mastery?.accuracy ?? 0.0,
              isPrerequisite: prereqs.any((p) => !proficientTopicIds.contains(p)),
              downstreamCount: dep.downstreamTopics.length,
            ) ??
            (1 - (mastery?.accuracy ?? 0.0));

        results.add(TopicReadinessResult(
          topicId: topic.id,
          topicTitle: topic.title,
          dependency: dep,
          mastery: mastery,
          isReady: isReady && unmetPrereqs.isEmpty,
          priority: priority,
          unmetPrerequisites: unmetPrereqs,
        ));
      }

      results.sort((a, b) => b.priority.compareTo(a.priority));
      return Result.success(results);
    } catch (e) {
      _logger.w('Failed to get ready topics', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<TopicReadinessResult>>> getNextRecommendedTopics({
    required String subjectId,
    required String studentId,
    int maxCount = 3,
  }) async {
    final result = await getReadyTopics(
      subjectId: subjectId,
      studentId: studentId,
    );
    if (result.isFailure) return result;

      final filtered = result.data!.where((r) => r.isReady).toList();
      filtered.sort((a, b) => b.priority.compareTo(a.priority));
      final readyOnly = filtered.take(maxCount).toList();

    return Result.success(readyOnly);
  }
}