import '../errors/result.dart';
import '../utils/logger.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import '../utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:studyking/features/planner/services/personal_learning_plan_service.dart';
import 'mastery_graph_service.dart';
import 'student_id_service.dart';

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

class AbsenceDeviation extends AdherenceDeviation {
  final int daysSinceLastActivity;

  const AbsenceDeviation({
    this.daysSinceLastActivity = 0,
    super.requiresRegeneration = true,
    super.requiresEscalation = true,
    super.message = '',
  }) : super(consecutiveLowDays: daysSinceLastActivity);
}

class PlanAdherenceOrchestrator {
  final PlanAdherenceRepository _adherenceRepository;

  PlanAdherenceRepository get adherenceRepository => _adherenceRepository;
  final PlanRepository _planRepository;
  final PersonalLearningPlanService _planService;
  final AppLocalizations? _l10n;

  PlanAdherenceOrchestrator({
    PlanAdherenceRepository? adherenceRepository,
    PlanRepository? planRepository,
    PersonalLearningPlanService? planService,
    MasteryGraphService? masteryService,
    AppLocalizations? l10n,
  })  : _adherenceRepository = adherenceRepository ?? PlanAdherenceRepository(),
        _planRepository = planRepository ?? PlanRepository(),
        _planService = planService ?? PersonalLearningPlanService(),
        _l10n = l10n;

  Future<Result<AdherenceDeviation>> checkAdherence(String studentId) async {
    try {
      await _adherenceRepository.init();
      await _planRepository.init();

      final studentIdService = StudentIdService();
      final daysSinceLastActivity = studentIdService.getDaysSinceLastActivity();

      if (daysSinceLastActivity >= 3) {
        final absenceDeviation = AbsenceDeviation(
          daysSinceLastActivity: daysSinceLastActivity,
          message: _l10n?.absenceDetectedBody(daysSinceLastActivity)
              ?? 'You haven\'t used StudyKing in $daysSinceLastActivity days. '
                 'How would you like to proceed?',
        );
        return Result.success(absenceDeviation);
      }

      final lowDays = await _adherenceRepository.getConsecutiveLowAdherenceDays(studentId);
      final avgAdherence = await _adherenceRepository.getAverageAdherence(studentId);

      AdherenceDeviation result;
      if (lowDays >= 7) {
        result = AdherenceDeviation(
          consecutiveLowDays: lowDays,
          averageAdherence: avgAdherence,
          requiresRegeneration: true,
          requiresEscalation: true,
          message: _l10n?.adherenceLowDaysAdjust(lowDays)
              ?? 'You have had $lowDays consecutive days of low adherence. '
                 'Consider adjusting your study plan or discussing with your mentor.',
        );
      } else if (lowDays >= 3) {
        result = AdherenceDeviation(
          consecutiveLowDays: lowDays,
          averageAdherence: avgAdherence,
          requiresRegeneration: true,
          requiresEscalation: false,
          message: _l10n?.adherenceLowDaysRegenerate(lowDays)
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
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<PersonalLearningPlan?>> suggestRegeneration({
    required String studentId,
    double? adjustmentFactor,
  }) async {
    try {
      final existingResult = await _planRepository.loadPlan(studentId);
      final existingPlan = existingResult.data;

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

      _planService.config = adjustedConfig;

      return await _planService.generatePlan(studentId);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getAdherenceReport(String studentId) async {
    try {
      await _adherenceRepository.init();
      final metrics = await _adherenceRepository.getByStudent(studentId);
      if (metrics.isEmpty) {
        return Result.success({
          'totalDays': 0,
          'averageAdherence': null,
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
      return Result.failure(e.toString());
    }
  }

  /// Provides per-day real-time adherence feedback after a session.
  /// Returns a message like "You studied 20min today vs 45min planned (44%).
  /// Want to adjust tomorrow's target?"
  Future<String?> getDailyAdherenceFeedback(String studentId) async {
    try {
      await _planRepository.init();
      final planResult = await _planRepository.loadPlan(studentId);
      final plan = planResult.data;
      if (plan == null) return null;

      await _adherenceRepository.init();
      final today = DateTime.now();
      final todayStart = today.dateOnly;

      int plannedMinutes = 0;
      int plannedQuestions = 0;
      for (final day in plan.dailyPlans) {
        final dDay = day.date.dateOnly;
        if (dDay == todayStart) {
          plannedMinutes = day.targetMinutes;
          plannedQuestions = day.targetQuestions;
          break;
        }
      }

      final todayRecords = await _adherenceRepository.getByStudent(studentId);
      int actualMinutes = 0;
      int actualQuestions = 0;
      for (final r in todayRecords) {
        final rDay = r.date.dateOnly;
        if (rDay == todayStart) {
          actualMinutes += r.actualMinutes;
          actualQuestions += r.actualQuestions;
        }
      }

      if (plannedMinutes == 0 && plannedQuestions == 0) return null;

      final minRatio = plannedMinutes > 0
          ? actualMinutes / plannedMinutes
          : 1.0;
      final qRatio = plannedQuestions > 0
          ? actualQuestions / plannedQuestions
          : 1.0;
      final overallRatio = (minRatio * 0.6 + qRatio * 0.4).clamp(0.0, 1.5);

      if (overallRatio < 0.3) {
        return _l10n?.adherenceLowToday(actualMinutes, plannedMinutes)
            ?? 'You studied $actualMinutes min today vs $plannedMinutes min planned. '
               'Consider redistributing the remaining workload.';
      } else if (overallRatio < 0.7) {
        return _l10n?.adherencePartialToday(actualMinutes, plannedMinutes)
            ?? 'You studied $actualMinutes min today vs $plannedMinutes min planned. '
               'Try to catch up with the remaining topics.';
      } else if (overallRatio > 1.2) {
        return _l10n?.adherenceExceededToday(actualMinutes, plannedMinutes)
            ?? 'Great work! You studied $actualMinutes min vs $plannedMinutes min planned.';
      }
      return null;
    } catch (e) {
      Logger('PlanAdherenceOrchestrator').e('getDailyAdherenceFeedback failed', e);
      return null;
    }
  }

  Future<void> recordActivity({
    required String studentId,
    required int actualMinutes,
    int actualQuestions = 0,
    String? planId,
  }) async {
    await _planService.recordDailyAdherence(
      studentId: studentId,
      actualQuestions: actualQuestions,
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
    } catch (e) {
      Logger('PlanAdherenceOrchestrator').e('_calculateAdjustmentFactor failed', e);
      return 0.7;
    }
  }
}
