import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart' show masteryGraphServiceProvider;
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart' show topicRepositoryProvider;
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

/// Per-subject scoped data for `SyllabusProgressCard`, fetched once for ALL
/// syllabus goals instead of per-card. Eliminates the N×2 redundant
/// `getAllMasteryStates` + `getBySubject` round-trips when rendering 12 cards.
class SyllabusProgressScope {
  final List<MasteryState> masteryStates;
  final int totalTopics;

  const SyllabusProgressScope({
    required this.masteryStates,
    required this.totalTopics,
  });
}

/// Fetches all mastery states once and all topics once, then returns a
/// per-subject-map keyed by `subjectId`. Both the dashboard and planner's
/// `SubjectProgressTabs` consume this so that rendering N syllabus progress
/// cards triggers exactly **two** repository calls (one mastery, one topics),
/// not 2×N.
final syllabusProgressForCardsProvider =
    FutureProvider.family<Map<String, SyllabusProgressScope>, String>(
        (ref, studentId) async {
  try {
    final plannerService = ref.watch(plannerServiceProvider);
    final masteryService = ref.watch(masteryGraphServiceProvider);
    final topicRepo = ref.watch(topicRepositoryProvider);

    final planResult = await plannerService.loadExistingPlan();
    final plan = planResult.data;
    if (plan == null || plan.syllabusGoals.isEmpty) return {};

    final goals = plan.syllabusGoals;

    // One mastery fetch for all subjects.
    final masteryResult = await masteryService.getAllTopicMastery(studentId);
    final allMastery =
        masteryResult.isSuccess ? (masteryResult.data ?? []) : <MasteryState>[];

    // One topics fetch for all subjects, then filter per subject.
    final topicsResult = await topicRepo.getAll();
    final allTopics = topicsResult.isSuccess ? (topicsResult.data ?? []) : <Topic>[];

    final result = <String, SyllabusProgressScope>{};
    for (final goal in goals) {
      final subjectTopics =
          allTopics.where((t) => t.subjectId == goal.subjectId).toList();
      final topicIds = subjectTopics.map((t) => t.id).toSet();
      final scopedMastery =
          allMastery.where((m) => topicIds.contains(m.topicId)).toList();
      result[goal.subjectId] = SyllabusProgressScope(
        masteryStates: scopedMastery,
        totalTopics: subjectTopics.length,
      );
    }
    return result;
  } catch (e) {
    _logger.w('Failed to load syllabus progress for cards', e);
    return {};
  }
});
