import '../errors/result.dart';
import '../errors/exceptions.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import '../data/models/personal_learning_plan_model.dart';
import 'personal_learning_plan_service.dart';
import 'mastery_graph_service.dart';
import 'localization_service.dart';

class AdherenceDeviation {
  final int consecutiveLowDays;
  final double averageAdherence;
  final bool requiresRegeneration;
  final bool requiresEscalation;
  final String message;

  const AdherenceDeviation({
    this.consecutiveLowDays = 0,
    this.averageAdherence = 1.0,
    this.requiresRegeneration = false,
    this.requiresEscalation = false,
    this.message = '',
  });
}

class PlanAdapter {
  final PlanAdherenceRepository _adherenceRepository;

  PlanAdherenceRepository get adherenceRepository => _adherenceRepository;
  final PlanRepository _planRepository;
  final PersonalLearningPlanService _planService;
  final MasteryGraphService _masteryService;
  final LocalizationService? _localizationService;

  PlanAdapter({
    PlanAdherenceRepository? adherenceRepository,
    PlanRepository? planRepository,
    PersonalLearningPlanService? planService,
    MasteryGraphService? masteryService,
    LocalizationService? localizationService,
  })  : _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        _planRepository = planRepository ?? PlanRepository(),
        _planService = planService ?? PersonalLearningPlanService(),
        _masteryService = masteryService ?? MasteryGraphService(),
        _localizationService = localizationService;

  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    try {
      await _adherenceRepository.init();
      await _planRepository.init();

      final lowDays = await _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
      final avgAdherence = await _adherenceRepository.getAverageAdherence(studentId);

      AdherenceDeviation result;
      if (lowDays >= 7) {
        result = AdherenceDeviation(
          consecutiveLowDays: lowDays,
          averageAdherence: avgAdherence,
          requiresRegeneration: true,
          requiresEscalation: true,
          message: _localizationService?.adherenceLowDaysAdjust(lowDays)
              ?? 'You have had $lowDays consecutive days of low adherence. '
                 'Consider adjusting your study plan or discussing with your mentor.',
        );
      } else if (lowDays >= 3) {
        result = AdherenceDeviation(
          consecutiveLowDays: lowDays,
          averageAdherence: avgAdherence,
          requiresRegeneration: true,
          requiresEscalation: false,
          message: _localizationService?.adherenceLowDaysRegenerate(lowDays)
              ?? 'You have had $lowDays consecutive days of low adherence. '
                 'Would you like to regenerate your plan with adjusted targets?',
        );
      } else {
        result = AdherenceDeviation(
          consecutiveLowDays: lowDays,
          averageAdherence: avgAdherence,
          requiresRegeneration: false,
          requiresEscalation: false,
          message: '',
        );
      }

      return Result.success(result);
    } on AdherenceException {
      rethrow;
    } catch (e) {
      return Result.failure('Failed to check adherence: $e');
    }
  }

  Future<Result<PersonalLearningPlan?>> suggestRegeneration({
    required String studentId,
    double? adjustmentFactor,
  }) async {
    try {
      final existingResult = await _planRepository.loadPlan(studentId);
      final existingPlan = existingResult;

      final adjustedFactor = adjustmentFactor ??
          await _calculateAdjustmentFactor(studentId);

      final adjustedConfig = PlanGenerationConfig(
        planDurationDays: existingPlan?.planDurationDays ?? 7,
        targetMinutesPerDay: (existingPlan?.targetMinutesPerDay ?? 30.0) * adjustedFactor,
        targetQuestionsPerDay: ((existingPlan?.targetQuestionsPerDay ?? 15) * adjustedFactor).round().clamp(5, 50),
        masteryThreshold: 0.8,
        maxQuestionsPerTopic: 10,
        includeRestDays: true,
        restDayFrequency: 7,
      );

      final svc = PersonalLearningPlanService(
        masteryService: _masteryService,
        config: adjustedConfig,
      );

      return await svc.generatePlan(studentId);
    } catch (e) {
      return Result.failure('Failed to regenerate plan: $e');
    }
  }

  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    try {
      await _adherenceRepository.init();
      final metrics = await _adherenceRepository.getByStudent(studentId);
      if (metrics.isEmpty) {
        return Result.success({
          'totalDays': 0,
          'averageAdherence': 1.0,
          'lowAdherenceDays': 0,
          'weeklyTrend': <double>[],
        });
      }

      final avgAdherence = metrics.fold<double>(0.0, (s, m) => s + m.adherenceScore) / metrics.length;
      final lowDays = metrics.where((m) => m.adherenceScore < 0.5).length;
      final weekly = await _adherenceRepository.getWeekly(studentId);
      final weeklyTrend = weekly.map((m) => m.adherenceScore).toList();

      return Result.success({
        'totalDays': metrics.length,
        'averageAdherence': avgAdherence,
        'lowAdherenceDays': lowDays,
        'weeklyTrend': weeklyTrend,
      });
    } catch (e) {
      return Result.failure('Failed to get adherence report: $e');
    }
  }

  Future<void> recordFromFocusSession({
    required String studentId,
    required int actualMinutes,
    String? planId,
  }) async {
    await _planService.recordDailyAdherence(
      studentId: studentId,
      actualQuestions: 0,
      actualMinutes: actualMinutes,
      planId: planId,
    );
  }

  Future<void> recordFromPracticeSession({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
    String? planId,
  }) async {
    await _planService.recordDailyAdherence(
      studentId: studentId,
      actualQuestions: actualQuestions,
      actualMinutes: actualMinutes,
      planId: planId,
    );
  }

  Future<void> recordFromTutorSession({
    required String studentId,
    required int actualMinutes,
    String? planId,
  }) async {
    await _planService.recordDailyAdherence(
      studentId: studentId,
      actualQuestions: 0,
      actualMinutes: actualMinutes,
      planId: planId,
    );
  }

  Future<double> _calculateAdjustmentFactor(String studentId) async {
    try {
      await _adherenceRepository.init();
      final avgAdherence = await _adherenceRepository.getAverageAdherence(studentId);
      if (avgAdherence <= 0.0) return 0.7;
      return (avgAdherence + 0.3).clamp(0.5, 1.0);
    } catch (_) {
      return 0.7;
    }
  }
}
