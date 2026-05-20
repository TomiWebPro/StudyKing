import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, spacedRepetitionServiceProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/questions/providers/question_providers.dart' show questionRepositoryProvider;
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart' show SyllabusGoal;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider;

final _dashboardLogger = const Logger('DashboardDataProviders');

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
  if (result.isFailure) {
    _dashboardLogger.w('Failed to load dashboard mastery data: ${result.error}');
  }
  return result.isSuccess ? (result.data ?? []) : [];
});

final dashboardMasterySnapshotProvider =
    FutureProvider.family<MasterySnapshot?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final masteryService = ref.watch(masteryGraphServiceProvider);
  final result = await masteryService.getMasterySnapshot(studentId);
  final snapshot = result.data;
  return result.isSuccess && snapshot != null ? MasterySnapshot.fromMap(snapshot) : null;
});

final dashboardOverallStatsProvider =
    FutureProvider.family<OverallStats?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
    final statsResult = await tracker.getOverallStats(studentId);
    final stats = statsResult.data ?? <String, dynamic>{};
    return OverallStats.fromMap(stats);
  } catch (e) {
    _dashboardLogger.w('Failed to get overall stats', e);
    return null;
  }
});

final dashboardWeeklyTrendProvider =
    FutureProvider.family<List<WeeklyTrendEntry>, String>(
        (ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
    final trendResult = await tracker.getWeeklyTrend(8, studentId: studentId);
    final trend = trendResult.data ?? [];
    return trend.map((m) => WeeklyTrendEntry.fromMap(m)).toList();
  } catch (e) {
    _dashboardLogger.w('Failed to get weekly trend', e);
    return [];
  }
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
    final totalSeconds = focusToday.fold<int>(0, (sum, s) => sum + s.actualDurationMs) ~/ msPerSecond;
    return FocusTodayStats.fromMap({
      'totalSeconds': totalSeconds,
      'completedSessions': focusToday.where((s) => s.completed).length,
      'totalSessions': focusToday.length,
      'plannedMinutes': focusToday.fold<int>(0, (sum, s) => sum + (s.plannedDurationMinutes ?? 0)),
    });
  } catch (e) {
    _dashboardLogger.w('Failed to get focus stats', e);
    return null;
  }
});

final dashboardAdherenceDataProvider =
    FutureProvider.family<AdherenceData, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final adherenceRepo = ref.watch(engagementAdherenceRepoProvider);
    final avgResult = await adherenceRepo.getAverageAdherence(studentId);
    final averageAdherence = avgResult.data ?? 0.0;
    final weeklyResult = await adherenceRepo.getWeekly(studentId);
    final weeklyRecords = weeklyResult.data ?? [];
    final weeklyAdherence = weeklyRecords.isEmpty
        ? 0.0
        : weeklyRecords.fold<double>(0.0, (sum, r) => sum + r.adherenceScore) /
            weeklyRecords.length;
    return AdherenceData(
      averageAdherence: averageAdherence,
      weeklyAdherence: weeklyAdherence,
    );
  } catch (e) {
    _dashboardLogger.w('Failed to get adherence data', e);
    return AdherenceData(averageAdherence: 0.0, weeklyAdherence: 0.0);
  }
});

final dashboardTopicNamesProvider =
    FutureProvider.family<Map<String, String>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
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
  } catch (e) {
    _dashboardLogger.w('Failed to get topic names', e);
    return {};
  }
});

final dashboardBadgesProvider =
    FutureProvider.family<List<BadgeDisplay>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
  try {
    final badgesResult = await tracker.getBadges(studentId);
    final badges = badgesResult.data ?? [];
    return badges.map((b) {
      return BadgeDisplay(
        name: (b['name'] as String?) ?? '',
        description: (b['description'] as String?) ?? '',
        category: (b['category'] as String?) ?? 'general',
      );
    }).toList();
  } catch (e) {
    _dashboardLogger.w('Failed to get badges', e);
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
      subjectTitle: 'all',
      topicTitles: topicNames,
      questionsPerTopic: questionsPerTopic,
      topicMasteryLevels: topicMasteryLevels,
    );
  } catch (e) {
    _dashboardLogger.w('Failed to estimate workload', e);
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
    _dashboardLogger.w('Failed to load due reviews', e);
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
    _dashboardLogger.w('Failed to get source count', e);
    return 0;
  }
});

final dashboardSyllabusProgressProvider =
    FutureProvider.family<List<SyllabusGoal>, String>((ref, studentId) async {
  try {
    final plannerService = ref.watch(plannerServiceProvider);
    final planResult = await plannerService.loadExistingPlan();
    final plan = planResult.data;
    if (plan == null) return [];
    return plan.syllabusGoals;
  } catch (e) {
    _dashboardLogger.w('Failed to load syllabus progress', e);
    return [];
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
    final lessonsResult = await plannerService.getScheduledLessons();
    final lessons = lessonsResult.data ?? [];
    final hasScheduledLessons = lessons.isNotEmpty;

    return ChecklistProgress(
      hasSubjects: hasSubjects,
      hasSources: hasSources,
      hasPracticeSessions: hasPracticeSessions,
      hasScheduledLessons: hasScheduledLessons,
    );
  } catch (e) {
    _dashboardLogger.w('Failed to get checklist progress', e);
    return const ChecklistProgress();
  }
});

