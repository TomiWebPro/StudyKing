import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, spacedRepetitionServiceProvider, subjectRepositoryProvider;
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;

final dashboardInitProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    ref.watch(masteryGraphServiceProvider).init(),
    ref.watch(dashboardInstrumentationServiceProvider).init(),
    ref.watch(topicRepositoryProvider).init(),
    ref.watch(engagementAdherenceRepoProvider).init(),
  ]);
});

final dashboardAllMasteryProvider =
    FutureProvider.family<List<MasteryState>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final result = await masteryService.getAllTopicMastery(studentId);
  return result.isSuccess ? result.data! : [];
});

final dashboardMasterySnapshotProvider =
    FutureProvider.family<MasterySnapshot?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final result = await masteryService.getMasterySnapshot(studentId);
  return result.isSuccess ? MasterySnapshot.fromMap(result.data!) : null;
});

final dashboardOverallStatsProvider =
    FutureProvider.family<OverallStats?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
  final stats = await tracker.getOverallStats(studentId);
  return OverallStats.fromMap(stats);
});

final dashboardWeeklyTrendProvider =
    FutureProvider.family<List<WeeklyTrendEntry>, String>(
        (ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
  final trend = await tracker.getWeeklyTrend(8, studentId: studentId);
  return trend.map((m) => WeeklyTrendEntry.fromMap(m)).toList();
});

final dashboardFocusStatsProvider =
    FutureProvider.family<FocusTodayStats?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final todayResult = await sessionRepo.getByDate(DateTime.now());
    final todaySessions = todayResult.data ?? [];
    final focusToday = todaySessions.where((s) => s.type == SessionType.focus).toList();
    if (focusToday.isEmpty) return null;
    final totalSeconds = focusToday.fold<int>(0, (sum, s) => sum + s.actualDurationMs) ~/ 1000;
    return FocusTodayStats.fromMap({
      'totalSeconds': totalSeconds,
      'completedSessions': focusToday.where((s) => s.completed).length,
      'totalSessions': focusToday.length,
      'plannedMinutes': focusToday.fold<int>(0, (sum, s) => sum + (s.plannedDurationMinutes ?? 0)),
    });
  } catch (e) {
    const Logger('dashboardFocusStatsProvider').e('Failed to get focus stats', e);
    return null;
  }
});

final dashboardAdherenceDataProvider =
    FutureProvider.family<AdherenceData, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final adherenceRepo = ref.watch(engagementAdherenceRepoProvider);
  final averageAdherence = await adherenceRepo.getAverageAdherence(studentId);
  final weeklyRecords = await adherenceRepo.getWeekly(studentId);
  final weeklyAdherence = weeklyRecords.isEmpty
      ? 0.0
      : weeklyRecords.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
          weeklyRecords.length;
  return AdherenceData(
    averageAdherence: averageAdherence,
    weeklyAdherence: weeklyAdherence,
  );
});

final dashboardTopicNamesProvider =
    FutureProvider.family<Map<String, String>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final topicRepo = ref.watch(topicRepositoryProvider);
  final allMastery = await ref.watch(dashboardAllMasteryProvider(studentId).future);
  final allTopicsResult = await topicRepo.getAll();
  final allTopics = allTopicsResult.data ?? [];
  final topicMap = <String, String>{};
  for (final topic in allTopics) {
    topicMap[topic.id] = topic.title;
  }
  for (final state in allMastery) {
    topicMap.putIfAbsent(state.topicId, () => state.topicId);
  }
  return topicMap;
});

final dashboardBadgesProvider =
    FutureProvider.family<List<BadgeDisplay>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
  try {
    final badges = await tracker.getBadges(studentId);
    return badges.map((b) {
      return BadgeDisplay(
        name: (b['name'] as String?) ?? '',
        description: (b['description'] as String?) ?? '',
        category: (b['category'] as String?) ?? 'general',
      );
    }).toList();
  } catch (e) {
    const Logger('dashboardBadgesProvider').e('Failed to get badges', e);
    return [];
  }
});

final dashboardWorkloadProvider =
    FutureProvider.family<SubjectWorkload?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final allMastery =
        await ref.watch(dashboardAllMasteryProvider(studentId).future);
    final topicNames =
        await ref.watch(dashboardTopicNamesProvider(studentId).future);
    final questionRepo = ref.watch(questionRepositoryProvider);

    final allQuestionsResult = await questionRepo.getAll();
    final allQuestions = allQuestionsResult.data ?? [];
    final questionsPerTopic = <String, int>{};
    for (final q in allQuestions) {
      questionsPerTopic[q.topicId] =
          (questionsPerTopic[q.topicId] ?? 0) + 1;
    }

    final topicMasteryLevels = <String, double>{};
    for (final state in allMastery) {
      topicMasteryLevels[state.topicId] = state.accuracy;
    }

    final estimator = RemainingWorkloadEstimator();
    return estimator.estimateSubjectWorkload(
      subjectId: 'all',
      subjectTitle: 'All Subjects',
      topicTitles: topicNames,
      questionsPerTopic: questionsPerTopic,
      topicMasteryLevels: topicMasteryLevels,
    );
  } catch (e) {
    const Logger('dashboardWorkloadProvider').e('Failed to estimate workload', e);
    return null;
  }
});

final dashboardDueReviewsProvider =
    FutureProvider.family<DueReviewsData?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final subjectRepo = ref.watch(subjectRepositoryProvider);
    final srService = ref.watch(spacedRepetitionServiceProvider);
    final subjectsResult = await subjectRepo.getAll();
    final subjects = subjectsResult.data ?? [];

    int totalDue = 0;
    final breakdown = <SubjectDueCount>[];
    for (final subject in subjects) {
      final result = await srService.getSubjectDueCount(subject.id);
      final count = result.isSuccess ? (result.data ?? 0) : 0;
      totalDue += count;
      breakdown.add(SubjectDueCount(
        subjectId: subject.id,
        subjectName: subject.name,
        dueCount: count,
      ));
    }

    return DueReviewsData(totalDue: totalDue, subjectBreakdown: breakdown);
  } catch (e) {
    const Logger('dashboardDueReviewsProvider').e('Failed to load due reviews', e);
    return null;
  }
});

final dashboardSourceCountProvider = FutureProvider.family<int, String>((ref, studentId) async {
  try {
    final repo = SourceRepository();
    await repo.init();
    final sources = await repo.getByStudent(studentId);
    return sources.length;
  } catch (e) {
    const Logger('dashboardSourceCountProvider').e('Failed to get source count', e);
    return 0;
  }
});

final dashboardChecklistProgressProvider = FutureProvider.family<ChecklistProgress, String>((ref, studentId) async {
  try {
    final subjectRepo = SubjectRepository();
    await subjectRepo.init();
    final subjectsResult = await subjectRepo.getAll();
    final hasSubjects = (subjectsResult.data ?? []).isNotEmpty;

    final sourceRepo = SourceRepository();
    await sourceRepo.init();
    final sourcesResult = await sourceRepo.getByStudent(studentId);
    final hasSources = sourcesResult.isNotEmpty;

    final sessionRepo = ref.watch(sessionRepositoryProvider);
    await sessionRepo.init();
    final allSessionsResult = await sessionRepo.getAll();
    final sessions = allSessionsResult.data ?? [];
    final hasPracticeSessions = sessions.any((s) => s.type == SessionType.practice);

    final plannerService = ref.watch(plannerServiceProvider);
    final lessons = await plannerService.getScheduledLessons();
    final hasScheduledLessons = lessons.isNotEmpty;

    return ChecklistProgress(
      hasSubjects: hasSubjects,
      hasSources: hasSources,
      hasPracticeSessions: hasPracticeSessions,
      hasScheduledLessons: hasScheduledLessons,
    );
  } catch (e) {
    const Logger('dashboardChecklistProgressProvider').e('Failed to get checklist progress', e);
    return const ChecklistProgress();
  }
});

