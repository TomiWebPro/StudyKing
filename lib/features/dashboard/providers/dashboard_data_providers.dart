import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/dashboard/data/models/dashboard_models.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart'
    show masteryGraphServiceProvider;

final dashboardInitProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    ref.read(masteryGraphServiceProvider).init(),
    ref.read(dashboardInstrumentationServiceProvider).init(),
    ref.read(dashboardTopicRepositoryProvider).init(),
    ref.read(dashboardAdherenceRepositoryProvider).init(),
  ]);
});

final dashboardAllMasteryProvider =
    FutureProvider.family<List<MasteryState>, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final masteryService = ref.read(masteryGraphServiceProvider);
  final result = await masteryService.getAllTopicMastery(studentId);
  return result.isSuccess ? result.data! : [];
});

final dashboardMasterySnapshotProvider =
    FutureProvider.family<MasterySnapshot?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final masteryService = ref.read(masteryGraphServiceProvider);
  final result = await masteryService.getMasterySnapshot(studentId);
  return result.isSuccess ? MasterySnapshot.fromMap(result.data!) : null;
});

final dashboardOverallStatsProvider =
    FutureProvider.family<OverallStats?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final tracker = ref.read(dashboardStudyProgressTrackerProvider);
  final stats = await tracker.getOverallStats(studentId);
  return OverallStats.fromMap(stats);
});

final dashboardWeeklyTrendProvider =
    FutureProvider.family<List<WeeklyTrendEntry>, String>(
        (ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final tracker = ref.read(dashboardStudyProgressTrackerProvider);
  final trend = await tracker.getWeeklyTrend(8, studentId: studentId);
  return trend.map((m) => WeeklyTrendEntry.fromMap(m)).toList();
});

final dashboardFocusStatsProvider =
    FutureProvider.family<FocusTodayStats?, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  try {
    final sessionRepo = ref.read(sessionRepositoryProvider);
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
  } catch (_) {
    return null;
  }
});

final dashboardAdherenceDataProvider =
    FutureProvider.family<AdherenceData, String>((ref, studentId) async {
  await ref.watch(dashboardInitProvider.future);
  final adherenceRepo = ref.read(dashboardAdherenceRepositoryProvider);
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
  final topicRepo = ref.read(dashboardTopicRepositoryProvider);
  final allMastery = await ref.watch(dashboardAllMasteryProvider(studentId).future);
  final allTopics = await topicRepo.getAll();
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
  final tracker = ref.read(dashboardStudyProgressTrackerProvider);
  try {
    final badges = await tracker.getBadges(studentId);
    return badges.map((b) {
      return BadgeDisplay(
        name: (b['name'] as String?) ?? '',
        description: (b['description'] as String?) ?? '',
        category: (b['category'] as String?) ?? 'general',
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

