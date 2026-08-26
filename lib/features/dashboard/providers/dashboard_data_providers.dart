import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/remaining_workload_estimator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/study_utils.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart'
    show focusSessionRepositoryProvider;
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider, spacedRepetitionServiceProvider;
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider, sourceRepositoryProvider;
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart' show SyllabusGoal;
import 'package:studyking/features/planner/providers/planner_providers.dart' show plannerServiceProvider, activePlanIdProvider;
import 'package:studyking/features/planner/services/mastery_remaining_lessons_estimator.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/providers/service_providers.dart' show learningMethodAnalyticsServiceProvider;

final _dashboardLogger = const Logger('DashboardDataProviders');

final dashboardInitProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    ref.watch(masteryGraphServiceProvider).init(),
    ref.watch(dashboardInstrumentationServiceProvider).init(),
    ref.watch(topicRepositoryProvider).init(),
    ref.watch(engagementAdherenceRepoProvider).init(),
    ref.watch(engagementNudgeRepoProvider).init(),
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

final dashboardDailyTrendProvider =
    FutureProvider.family<List<DailyTrendEntry>, String>(
        (ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
    final result = await tracker.getDailyTrend(365, studentId: studentId);
    final trend = result.data ?? [];
    return trend.map((m) => DailyTrendEntry(
      date: DateTime.parse(m['date'] as String),
      attempts: m['attempts'] as int? ?? 0,
      accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0.0,
      focusSeconds: m['focusSeconds'] as int? ?? 0,
      sessions: m['sessions'] as int? ?? 0,
      compositeScore: (m['compositeScore'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  } catch (e) {
    _dashboardLogger.w('Failed to get daily trend', e);
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
    final dueCounts = <String, int>{};
    for (final subject in subjects) {
      final result = await srService.getSubjectDueCount(subject.id);
      dueCounts[subject.id] = result.data ?? 0;
    }
    for (final subject in subjects) {
      final count = dueCounts[subject.id] ?? 0;
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
    final repo = ref.watch(sourceRepositoryProvider);
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
    ref.watch(activePlanIdProvider);
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
    final subjectRepo = ref.watch(subjectRepositoryProvider);
    final subjectsResult = await subjectRepo.getAll();
    final hasSubjects = (subjectsResult.data ?? []).isNotEmpty;

    final sourceRepo = ref.watch(sourceRepositoryProvider);
    final sourcesResult = await sourceRepo.getByStudent(studentId);
    final hasSources = sourcesResult.isNotEmpty;

    final sessionRepo = ref.watch(sessionRepositoryProvider);
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

final dashboardLastFocusSessionProvider =
    FutureProvider.family<FocusSession?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final repo = await ref.watch(focusSessionRepositoryProvider.future);
    final result = await repo.getLatest();
    return result.data;
  } catch (e) {
    _dashboardLogger.w('Failed to load last focus session', e);
    return null;
  }
});

final dashboardLearningInsightsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final analyticsService = ref.watch(learningMethodAnalyticsServiceProvider);
    final result = await analyticsService.getLearningInsights(studentId);
    if (result.isSuccess) {
      return result.data;
    }
    return null;
  } catch (e) {
    _dashboardLogger.w('Failed to get learning insights', e);
    return null;
  }
});

final dashboardMasteryRemainingLessonsProvider =
    FutureProvider.family<RemainingLessonsEstimate, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final masteryService = ref.watch(masteryGraphServiceProvider);
    final srService = ref.watch(spacedRepetitionServiceProvider);
    final topicRepo = ref.watch(topicRepositoryProvider);

    final masteryResult = await masteryService.getAllTopicMastery(studentId);
    final states =
        masteryResult.isSuccess ? (masteryResult.data ?? []) : <MasteryState>[];

    final dueResult = await srService.getQuestionsDueForReview();
    final dueQuestions =
        dueResult.isSuccess ? (dueResult.data ?? []) : <Question>[];
    final duePerTopic = <String, int>{};
    for (final question in dueQuestions) {
      duePerTopic[question.topicId] =
          (duePerTopic[question.topicId] ?? 0) + 1;
    }

    final inputs = states
        .map((s) => RemainingLessonsTopicInput.fromMasteryState(
              s,
              dueQuestionCount: duePerTopic[s.topicId] ?? 0,
            ))
        .toList();

    int totalTopics = 0;
    try {
      await topicRepo.init();
      final allTopics = await topicRepo.getAll();
      totalTopics = allTopics.data?.length ?? 0;
    } catch (e) {
      _dashboardLogger.w('Failed to load topic count for coverage', e);
    }

    final estimateResult = MasteryRemainingLessonsEstimator.estimateForSubject(
      inputs,
      syllabusTopicCount: totalTopics,
    );
    if (estimateResult.isFailure) {
      _dashboardLogger.w(
        'Failed to estimate remaining lessons to mastery: ${estimateResult.error}',
      );
      return RemainingLessonsEstimate(0, 0);
    }
    return estimateResult.data!;
  } catch (e) {
    _dashboardLogger.w('Failed to compute remaining lessons to mastery', e);
    return RemainingLessonsEstimate(0, 0);
  }
});

/// Holds the currently selected syllabus (subject id) used to scope the
/// dashboard. `null` means "all syllabi" (aggregate view).
final dashboardSelectedSyllabusProvider = StateProvider<String?>((ref) => null);

/// Returns per-syllabus progress/stats derived from the active learning plan's
/// `SyllabusGoal[]`. For each goal it computes completion %, accuracy, weak
/// topics, and study time scoped to that syllabus' subject.
final dashboardSyllabusBreakdownProvider =
    FutureProvider.family<List<SyllabusBreakdown>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    ref.watch(activePlanIdProvider);
    final plannerService = ref.watch(plannerServiceProvider);
    final planResult = await plannerService.loadExistingPlan();
    final plan = planResult.data;
    if (plan == null) return [];
    final goals = plan.syllabusGoals;
    if (goals.isEmpty) return [];

    final masteryService = ref.watch(masteryGraphServiceProvider);
    final topicRepo = ref.watch(topicRepositoryProvider);
    final sessionRepo = ref.watch(sessionRepositoryProvider);

    final masteryResult = await masteryService.getAllTopicMastery(studentId);
    final allMastery =
        masteryResult.isSuccess ? (masteryResult.data ?? []) : <MasteryState>[];

    final sessionsResult = await sessionRepo.getAll();
    final allSessions =
        sessionsResult.isSuccess ? (sessionsResult.data ?? []) : <Session>[];

    final breakdowns = <SyllabusBreakdown>[];
    for (final goal in goals) {
      List<Topic> topics = [];
      try {
        final topicsResult = await topicRepo.getBySubject(goal.subjectId);
        topics = topicsResult.isSuccess ? (topicsResult.data ?? []) : [];
      } catch (e) {
        _dashboardLogger.w('Failed to load topics for syllabus ${goal.subjectId}', e);
      }
      final topicIds = topics.map((t) => t.id).toSet();
      final syllabusMastery =
          allMastery.where((m) => topicIds.contains(m.topicId)).toList();

      final totalTopics = topicIds.length;
      final masteredTopics = syllabusMastery
          .where((m) => m.masteryLevel.index >= MasteryLevel.proficient.index)
          .length;
      final weakMastery = syllabusMastery.where((m) => m.accuracy < 0.6).toList();
      final weakTopics = weakMastery.length;
      final weakTopicIds = weakMastery.map((m) => m.topicId).toList();
      final accuracy = syllabusMastery.isNotEmpty
          ? syllabusMastery.fold<double>(0.0, (sum, m) => sum + m.accuracy) /
              syllabusMastery.length
          : 0.0;
      final completionPercent = totalTopics > 0 ? masteredTopics / totalTopics : 0.0;
      final studyMs = allSessions
          .where((s) => s.subjectId == goal.subjectId)
          .fold<int>(0, (sum, s) => sum + s.actualDurationMs);

      breakdowns.add(SyllabusBreakdown(
        subjectId: goal.subjectId,
        subjectTitle: goal.subjectTitle,
        completionPercent: completionPercent,
        accuracy: accuracy,
        totalTopics: totalTopics,
        masteredTopics: masteredTopics,
        weakTopics: weakTopics,
        studyHours: studyMs / 3600000,
        topicIds: topicIds.toList(),
        weakTopicIds: weakTopicIds,
      ));
    }
    return breakdowns;
  } catch (e) {
    _dashboardLogger.w('Failed to load syllabus breakdown', e);
    return [];
  }
});

