import 'package:hive_flutter/hive_flutter.dart';
import '../errors/result.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import '../utils/logger.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_metric_model.dart';
import 'package:studyking/features/practice/data/models/mastery_improvement_metric_model.dart';
import '../data/hive_box_names.dart';

class PlanAdherenceTracker {
  List<PlanAdherenceMetric> _metrics = [];
  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(HiveBoxNames.planAdherenceMetrics);
    _metrics = _box.values.cast<PlanAdherenceMetric>().toList();
    _initialized = true;
  }

  void recordDay({
    required String studentId,
    required DateTime date,
    required int plannedQuestions,
    required int actualQuestions,
    required int plannedMinutes,
    required int actualMinutes,
    Map<String, dynamic>? metadata,
  }) {
    final adherenceScore = _calculateAdherenceScore(
      plannedQuestions: plannedQuestions,
      actualQuestions: actualQuestions,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
    );

    final metric = PlanAdherenceMetric(
      date: date,
      studentId: studentId,
      plannedQuestions: plannedQuestions,
      actualQuestions: actualQuestions,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
      adherenceScore: adherenceScore,
      metadata: metadata,
    );
    _metrics.add(metric);
    _box.add(metric);
  }

  double _calculateAdherenceScore({
    required int plannedQuestions,
    required int actualQuestions,
    required int plannedMinutes,
    required int actualMinutes,
  }) {
    if (plannedQuestions == 0 && plannedMinutes == 0) return 1.0;

    final questionScore = plannedQuestions > 0
        ? (actualQuestions / plannedQuestions).clamp(0.0, 1.0)
        : 0.5;
    final timeScore = plannedMinutes > 0
        ? (actualMinutes / plannedMinutes).clamp(0.0, 1.5)
        : 0.5;

    return (questionScore * 0.6 + timeScore * 0.4).clamp(0.0, 1.0);
  }

  double getAverageAdherence(String studentId) {
    final studentMetrics = _metrics.where((m) => m.studentId == studentId).toList();
    if (studentMetrics.isEmpty) return 0.0;
    return studentMetrics.map((m) => m.adherenceScore).reduce((a, b) => a + b) / studentMetrics.length;
  }

  List<PlanAdherenceMetric> getWeeklyMetrics(String studentId) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _metrics.where((m) =>
        m.studentId == studentId &&
        m.date.isAfter(weekAgo)
    ).toList();
  }

  List<PlanAdherenceMetric> getAllMetrics(String studentId) {
    return _metrics.where((m) => m.studentId == studentId).toList();
  }

  int getConsecutiveLowAdherenceDays(String studentId, {double threshold = 0.5}) {
    final metrics = _metrics.where((m) => m.studentId == studentId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    int consecutive = 0;
    for (final metric in metrics) {
      if (metric.adherenceScore < threshold) {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }
}

class MasteryImprovementTracker {
  final Map<String, MasteryState> _previousStates = {};
  List<MasteryImprovementMetric> _metrics = [];
  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(HiveBoxNames.masteryImprovementMetrics);
    _metrics = _box.values.cast<MasteryImprovementMetric>().toList();
    _initialized = true;
  }

  void trackImprovement({
    required MasteryState currentState,
    required String studentId,
  }) {
    final key = '${studentId}_${currentState.topicId}';
    final previousState = _previousStates[key];

    if (previousState != null && previousState.accuracy != currentState.accuracy) {
      final metric = MasteryImprovementMetric(
        date: DateTime.now(),
        studentId: studentId,
        topicId: currentState.topicId,
        previousAccuracy: previousState.accuracy,
        currentAccuracy: currentState.accuracy,
        accuracyDelta: currentState.accuracy - previousState.accuracy,
        previousMasteryLevel: previousState.readinessScore,
        currentMasteryLevel: currentState.readinessScore,
        previousLevel: previousState.masteryLevel,
        currentLevel: currentState.masteryLevel,
      );
      _metrics.add(metric);
      _box.add(metric);
    }

    _previousStates[key] = currentState;
  }

  List<MasteryImprovementMetric> getImprovements(String studentId) {
    return _metrics.where((m) => m.studentId == studentId).toList();
  }

  List<MasteryImprovementMetric> getRecentImprovements(String studentId, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _metrics.where((m) =>
        m.studentId == studentId &&
        m.date.isAfter(cutoff)
    ).toList();
  }

  int getLevelUpCount(String studentId) {
    return _metrics.where((m) => m.studentId == studentId && m.leveledUp).length;
  }

  double getAverageImprovement(String studentId) {
    final studentMetrics = _metrics.where((m) => m.studentId == studentId).toList();
    if (studentMetrics.isEmpty) return 0.0;
    return studentMetrics.map((m) => m.accuracyDelta).reduce((a, b) => a + b) / studentMetrics.length;
  }

  MasteryState? getPreviousState(String studentId, String topicId) {
    return _previousStates['${studentId}_$topicId'];
  }
}

class InstrumentationService {
  final Logger _logger = const Logger('InstrumentationService');
  final MasteryGraphRepository _repository;
  final PlanAdherenceTracker _adherenceTracker;
  final MasteryImprovementTracker _improvementTracker;

  InstrumentationService({
    MasteryGraphRepository? repository,
  })  : _repository = repository ?? MasteryGraphRepository(),
        _adherenceTracker = PlanAdherenceTracker(),
        _improvementTracker = MasteryImprovementTracker();

  Future<void> init() async {
    await _repository.init();
    await _adherenceTracker.init();
    await _improvementTracker.init();
  }

  void recordPlanAdherence({
    required String studentId,
    required int plannedQuestions,
    required int actualQuestions,
    required int plannedMinutes,
    required int actualMinutes,
    DateTime? date,
  }) {
    _adherenceTracker.recordDay(
      studentId: studentId,
      date: date ?? DateTime.now(),
      plannedQuestions: plannedQuestions,
      actualQuestions: actualQuestions,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
    );
  }

  Future<Result<void>> trackMasteryImprovement(String studentId, String topicId) async {
    final result = await _repository.getMasteryState(studentId, topicId);
    if (result.isFailure) {
      return Result.failure(result.error);
    }

    _improvementTracker.trackImprovement(
      currentState: result.data!,
      studentId: studentId,
    );

    return Result.success(null);
  }

  Future<Result<Map<String, dynamic>>> getInstrumentationDashboard(String studentId) async {
    try {
      final avgAdherence = _adherenceTracker.getAverageAdherence(studentId);
      final weeklyMetrics = _adherenceTracker.getWeeklyMetrics(studentId);
      final consecutiveLowDays = _adherenceTracker.getConsecutiveLowAdherenceDays(studentId);
      final improvements = _improvementTracker.getRecentImprovements(studentId, days: 7);
      final levelUps = _improvementTracker.getLevelUpCount(studentId);
      final avgImprovement = _improvementTracker.getAverageImprovement(studentId);

      final snapshotResult = await _repository.getMasterySnapshot(studentId);

      return Result.success({
        'planAdherence': {
          'averageAdherence': avgAdherence,
          'weeklyMetricsCount': weeklyMetrics.length,
          'weeklyAdherenceAvg': weeklyMetrics.isEmpty
              ? 0.0
              : weeklyMetrics.map((m) => m.adherenceScore).reduce((a, b) => a + b) / weeklyMetrics.length,
          'consecutiveLowDays': consecutiveLowDays,
        },
        'masteryImprovement': {
          'recentImprovementsCount': improvements.length,
          'levelUpsThisWeek': levelUps,
          'averageAccuracyDelta': avgImprovement,
          'totalTopicsTracked': snapshotResult.isSuccess
              ? snapshotResult.data!['totalTopics']
              : 0,
          'masteredTopics': snapshotResult.isSuccess
              ? snapshotResult.data!['masteredTopics']
              : 0,
        },
        'generatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  List<PlanAdherenceMetric> getAdherenceHistory(String studentId) {
    return _adherenceTracker.getAllMetrics(studentId);
  }

  List<MasteryImprovementMetric> getImprovementHistory(String studentId) {
    return _improvementTracker.getImprovements(studentId);
  }

  Future<Result<void>> exportInstrumentationData(String studentId) async {
    try {
      final adherence = getAdherenceHistory(studentId);
      final improvements = getImprovementHistory(studentId);

      final data = {
        'studentId': studentId,
        'exportedAt': DateTime.now().toIso8601String(),
        'adherenceMetrics': adherence.map((m) => m.toJson()).toList(),
        'improvementMetrics': improvements.map((m) => m.toJson()).toList(),
      };

      _logger.i('Instrumentation data exported: ${data.keys.length} categories');
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
