import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'planner_providers.dart' show plannerServiceProvider;

final _logger = const Logger('SyllabusProviders');

class SyllabusProgressData {
  final int totalTopics;
  final int completedTopics;
  final double completionPercentage;
  final List<String> focusAreas;

  const SyllabusProgressData({
    this.totalTopics = 0,
    this.completedTopics = 0,
    this.completionPercentage = 0.0,
    this.focusAreas = const [],
  });
}

final syllabusProgressProvider =
    FutureProvider.family<SyllabusProgressData, String>((ref, studentId) async {
  final service = ref.watch(plannerServiceProvider);
  try {
    final planResult = await service.loadExistingPlan();
    final plan = planResult.data;
    if (plan == null) {
      return const SyllabusProgressData();
    }

    final totalTopics = plan.dailyPlans
        .expand((d) => d.priorityTopics)
        .map((t) => t.topicId)
        .toSet()
        .length;

    final adherenceResult = await service.getAdherenceRecords();
    final adherenceRecords = adherenceResult.data ?? [];
    final completedTopicIds = <String>{};
    for (final day in plan.dailyPlans) {
      final matched = adherenceRecords.where(
        (r) => r.date.dateOnly == day.date.dateOnly && r.adherenceScore >= 0.5,
      );
      if (matched.isNotEmpty) {
        completedTopicIds.addAll(day.priorityTopics.map((t) => t.topicId));
      }
    }

    final focusAreas = plan.recommendations
        .where((r) => r.priority > 0.7)
        .take(3)
        .map((r) => r.topicId)
        .toList();

    return SyllabusProgressData(
      totalTopics: totalTopics,
      completedTopics: completedTopicIds.length,
      completionPercentage:
          totalTopics > 0 ? completedTopicIds.length / totalTopics : 0.0,
      focusAreas: focusAreas,
    );
  } catch (e) {
    _logger.w('Failed to load syllabus progress', e);
    return const SyllabusProgressData();
  }
});

class RoadmapListData {
  final List<RoadmapModel> roadmaps;
  final bool isLoading;

  const RoadmapListData({
    this.roadmaps = const [],
    this.isLoading = false,
  });
}

final roadmapListProvider =
    FutureProvider.family<RoadmapListData, String>((ref, studentId) async {
  final service = ref.watch(plannerServiceProvider);
  try {
    final result = await service.loadRoadmaps();
    return RoadmapListData(
      roadmaps: result.data ?? [],
      isLoading: false,
    );
  } catch (e) {
    _logger.w('Failed to load roadmaps', e);
    return const RoadmapListData(isLoading: false);
  }
});
