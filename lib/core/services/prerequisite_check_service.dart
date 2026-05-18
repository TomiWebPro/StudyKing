import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';

class PrerequisiteCheckResult {
  final bool isReady;
  final List<Topic> unmetPrerequisiteTopics;

  const PrerequisiteCheckResult({
    required this.isReady,
    this.unmetPrerequisiteTopics = const [],
  });
}

class PrerequisiteCheckService {
  final Logger _logger = const Logger('PrerequisiteCheckService');
  final TopicRepository _topicRepository;
  final MasteryGraphRepository _masteryRepository;

  PrerequisiteCheckService({
    TopicRepository? topicRepository,
    MasteryGraphRepository? masteryRepository,
  })  : _topicRepository = topicRepository ?? TopicRepository(),
        _masteryRepository = masteryRepository ?? MasteryGraphRepository();

  Future<Result<PrerequisiteCheckResult>> checkPrerequisites({
    required String topicId,
    required String studentId,
    double masteryThreshold = 0.8,
  }) async {
    try {
      await _topicRepository.init();
      await _masteryRepository.init();

      final topicResult = await _topicRepository.get(topicId);
      if (topicResult.isFailure || topicResult.data == null) {
        return Result.success(const PrerequisiteCheckResult(isReady: true));
      }

      List<TopicDependency> allDeps = [];
      final depsResult = await _masteryRepository.getAllDependencies();
      if (depsResult.isSuccess) {
        allDeps = depsResult.data!;
      }

      final dep = allDeps.where((d) => d.topicId == topicId).firstOrNull;
      if (dep == null || dep.prerequisites.isEmpty) {
        return Result.success(const PrerequisiteCheckResult(isReady: true));
      }

      final masteryResult = await _masteryRepository.getAllMasteryStates(studentId);
      final masteredIds = <String>{};
      if (masteryResult.isSuccess) {
        for (final state in masteryResult.data!) {
          if (state.masteryLevel.index >= 3) {
            masteredIds.add(state.topicId);
          }
        }
      }

      final unmetPrereqIds = dep.prerequisites
          .where((id) => !masteredIds.contains(id))
          .toList();

      if (unmetPrereqIds.isEmpty) {
        return Result.success(const PrerequisiteCheckResult(isReady: true));
      }

      final unmetTopics = <Topic>[];
      for (final id in unmetPrereqIds) {
        final tResult = await _topicRepository.get(id);
        if (tResult.isSuccess && tResult.data != null) {
          unmetTopics.add(tResult.data!);
        }
      }

      return Result.success(PrerequisiteCheckResult(
        isReady: false,
        unmetPrerequisiteTopics: unmetTopics,
      ));
    } catch (e) {
      _logger.e('Failed to check prerequisites', e);
      return Result.success(const PrerequisiteCheckResult(isReady: true));
    }
  }

  static Future<bool> showPrerequisiteDialog(
    BuildContext context, {
    required List<Topic> unmetTopics,
    VoidCallback? onPracticePrerequisites,
  }) async {
    final topicNames = unmetTopics.map((t) => t.title).join(', ');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prerequisites Not Met'),
        content: Text(
          'This topic requires mastery of: $topicNames. '
          'Would you like to practice those first?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Practice Prerequisites'),
          ),
        ],
      ),
    );
    if (result == true && onPracticePrerequisites != null) {
      onPracticePrerequisites();
    }
    return result ?? false;
  }
}
