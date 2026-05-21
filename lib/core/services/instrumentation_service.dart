import 'package:studyking/core/utils/id_generator.dart';
import '../errors/result.dart';
import '../utils/study_utils.dart';
import 'package:studyking/features/practice/data/repositories/mastery_graph_repository.dart';
import '../utils/logger.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/models/mastery_improvement_metric_model.dart';
import '../data/hive_box_names.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  static final Logger _logger = const Logger('InstrumentationService');
  final MasteryGraphRepository _repository;
  final MasteryImprovementTracker _improvementTracker;
  final PlanAdherenceRepository? _adherenceRepository;

  InstrumentationService({
    MasteryGraphRepository? repository,
    PlanAdherenceRepository? adherenceRepository,
  })  : _repository = repository ?? MasteryGraphRepository(),
        _adherenceRepository = adherenceRepository,
        _improvementTracker = MasteryImprovementTracker();

  Future<void> init() async {
    await _repository.init();
    await _adherenceRepository?.init();
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
    final recordDate = date ?? DateTime.now();
    final score = calculateAdherenceScore(
      plannedQuestions: plannedQuestions,
      actualQuestions: actualQuestions,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
    );
    final model = PlanAdherenceModel(
      id: IdGenerator.generate('adh'),
      studentId: studentId,
      date: recordDate,
      plannedQuestions: plannedQuestions,
      actualQuestions: actualQuestions,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes,
      adherenceScore: score,
    );
    _adherenceRepository?.create(model);
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
      double avgAdherence = 0.0;
      int weeklyMetricsCount = 0;
      double weeklyAdherenceAvg = 0.0;
      int consecutiveLowDays = 0;

      if (_adherenceRepository != null) {
        final avgResult = await _adherenceRepository.getAverageAdherence(studentId);
        avgAdherence = avgResult.data ?? 0.0;
        final weeklyResult = await _adherenceRepository.getWeekly(studentId);
        final weeklyMetrics = weeklyResult.data ?? [];
        weeklyMetricsCount = weeklyMetrics.length;
        weeklyAdherenceAvg = weeklyMetrics.isEmpty
            ? 0.0
            : weeklyMetrics.fold<double>(0.0, (sum, m) => sum + m.adherenceScore) / weeklyMetrics.length;
        final lowDaysResult = await _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
        consecutiveLowDays = lowDaysResult.data ?? 0;
      }

      final improvements = _improvementTracker.getRecentImprovements(studentId, days: 7);
      final levelUps = _improvementTracker.getLevelUpCount(studentId);
      final avgImprovement = _improvementTracker.getAverageImprovement(studentId);

      final snapshotResult = await _repository.getMasterySnapshot(studentId);

      return Result.success({
        'planAdherence': {
          'averageAdherence': avgAdherence,
          'weeklyMetricsCount': weeklyMetricsCount,
          'weeklyAdherenceAvg': weeklyAdherenceAvg,
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

  Future<List<PlanAdherenceModel>> getAdherenceHistory(String studentId) async {
    if (_adherenceRepository == null) return [];
    final result = await _adherenceRepository.getByStudent(studentId);
    return result.data ?? [];
  }

  List<MasteryImprovementMetric> getImprovementHistory(String studentId) {
    return _improvementTracker.getImprovements(studentId);
  }

  Future<Result<void>> exportInstrumentationData(String studentId) async {
    try {
      final improvements = getImprovementHistory(studentId);

      List<Map<String, dynamic>> adherenceData = [];
      if (_adherenceRepository != null) {
        final modelsResult = await _adherenceRepository.getByStudent(studentId);
        final adherenceModels = modelsResult.data ?? [];
        adherenceData = adherenceModels.map((m) => m.toJson()).toList();
      }

      final data = {
        'studentId': studentId,
        'exportedAt': DateTime.now().toIso8601String(),
        'adherenceMetrics': adherenceData,
        'improvementMetrics': improvements.map((m) => m.toJson()).toList(),
      };

      _logger.d('Instrumentation data exported: ${data.keys.length} categories');
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
