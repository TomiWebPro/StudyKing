import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/adapters.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/services/plan_adherence_orchestrator.dart';
import 'package:studyking/core/services/personal_learning_plan_service.dart';

class _FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _storage = [];
  bool failOnInit = false;

  @override
  Future<void> init() async {
    if (failOnInit) throw Exception('Init failed');
  }

  @override
  Future<void> create(PlanAdherenceModel model) async {
    _storage.add(model);
  }

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    return _storage.where((m) => m.studentId == studentId).toList();
  }

  @override
  Future<double> getAverageAdherence(String studentId) async {
    final metrics = _storage.where((m) => m.studentId == studentId).toList();
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(0.0, (s, m) => s + m.adherenceScore) / metrics.length;
  }

  @override
  Future<int> getConsecutiveLowAdherenceDays(String studentId, {double threshold = 0.5}) async {
    final metrics = _storage.where((m) => m.studentId == studentId).toList();
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

  @override
  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    return _storage.where((m) => m.studentId == studentId).toList();
  }

  @override
  Future<PlanAdherenceModel?> getToday(String studentId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final matches = _storage.where((m) =>
        m.studentId == studentId &&
        m.date.isAfter(start) &&
        m.date.isBefore(end));
    return matches.isNotEmpty ? matches.first : null;
  }

  List<PlanAdherenceModel> get stored => _storage;
}

class _FakePlanRepository extends PlanRepository {
  PersonalLearningPlan? storedPlan;

  @override
  Future<void> init() async {}

  @override
  Future<Result<PersonalLearningPlan?>> loadPlan(String studentId) async {
    return Result.success(storedPlan);
  }

  @override
  Future<Result<void>> savePlan(PersonalLearningPlan plan) async {
    storedPlan = plan;
    return Result.success(null);
  }
}

class _FakePlanService extends PersonalLearningPlanService {
  final _FakePlanAdherenceRepository adherenceRepo;

  _FakePlanService({required this.adherenceRepo})
      : super(adherenceRepository: adherenceRepo);

  @override
  Future<void> recordDailyAdherence({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
    String? planId,
  }) async {
    final model = PlanAdherenceModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      date: DateTime.now(),
      plannedQuestions: 0,
      actualQuestions: actualQuestions,
      plannedMinutes: 0,
      actualMinutes: actualMinutes,
      adherenceScore: actualQuestions > 0 || actualMinutes > 0 ? 0.8 : 0.0,
      planId: planId,
    );
    await adherenceRepo.create(model);
  }
}

void main() {
  group('PlanAdherenceOrchestrator', () {
    late _FakePlanAdherenceRepository adherenceRepo;
    late _FakePlanRepository planRepo;
    late PlanAdherenceOrchestrator adapter;

    setUp(() {
      Hive.init(Directory.systemTemp.createTempSync('plan_adapter_test_').path);
      registerPlannerAdapters();
      adherenceRepo = _FakePlanAdherenceRepository();
      planRepo = _FakePlanRepository();
      adapter = PlanAdherenceOrchestrator(
        adherenceRepository: adherenceRepo,
        planRepository: planRepo,
        planService: _FakePlanService(adherenceRepo: adherenceRepo),
      );
    });

    group('checkAdherence', () {
      test('returns no deviation when no adherence data exists', () async {
        final result = await adapter.checkAdherence('student-1');

        expect(result.isSuccess, true);
        expect(result.data!.consecutiveLowDays, 0);
        expect(result.data!.requiresRegeneration, false);
        expect(result.data!.requiresEscalation, false);
        expect(result.data!.message, '');
      });

      test('returns no deviation when adherence is high', () async {
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'adh_1',
          studentId: 'student-1',
          date: DateTime.now(),
          adherenceScore: 0.9,
        ));
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'adh_2',
          studentId: 'student-1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          adherenceScore: 0.8,
        ));

        final result = await adapter.checkAdherence('student-1');

        expect(result.isSuccess, true);
        expect(result.data!.consecutiveLowDays, 0);
        expect(result.data!.requiresRegeneration, false);
      });

      test('returns regeneration suggestion after 3+ low adherence days', () async {
        for (var i = 0; i < 3; i++) {
          await adherenceRepo.create(PlanAdherenceModel(
            id: 'adh_low_$i',
            studentId: 'student-1',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.3,
          ));
        }

        final result = await adapter.checkAdherence('student-1');

        expect(result.isSuccess, true);
        expect(result.data!.consecutiveLowDays, 3);
        expect(result.data!.requiresRegeneration, true);
        expect(result.data!.requiresEscalation, false);
      });

      test('returns escalation after 7+ low adherence days', () async {
        for (var i = 0; i < 7; i++) {
          await adherenceRepo.create(PlanAdherenceModel(
            id: 'adh_vlow_$i',
            studentId: 'student-1',
            date: DateTime.now().subtract(Duration(days: i)),
            adherenceScore: 0.2,
          ));
        }

        final result = await adapter.checkAdherence('student-1');

        expect(result.isSuccess, true);
        expect(result.data!.consecutiveLowDays, 7);
        expect(result.data!.requiresRegeneration, true);
        expect(result.data!.requiresEscalation, true);
      });

      test('returns failure when adherence repository init fails', () async {
        adherenceRepo.failOnInit = true;

        final result = await adapter.checkAdherence('student-1');

        expect(result.isFailure, true);
      });

      test('breaks consecutive count on high adherence day', () async {
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'adh_high',
          studentId: 'student-1',
          date: DateTime.now(),
          adherenceScore: 0.9,
        ));
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'adh_low',
          studentId: 'student-1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          adherenceScore: 0.3,
        ));

        final result = await adapter.checkAdherence('student-1');

        expect(result.data!.consecutiveLowDays, 0);
        expect(result.data!.requiresRegeneration, false);
      });
    });

    group('recordActivity', () {
      test('records activity with minutes only (focus/tutor style)', () async {
        await adapter.recordActivity(
          studentId: 'student-1',
          actualMinutes: 25,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all, hasLength(1));
        expect(all.first.actualMinutes, 25);
        expect(all.first.actualQuestions, 0);
      });

      test('records activity with questions (practice style)', () async {
        await adapter.recordActivity(
          studentId: 'student-1',
          actualQuestions: 15,
          actualMinutes: 45,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all, hasLength(1));
        expect(all.first.actualQuestions, 15);
        expect(all.first.actualMinutes, 45);
      });

      test('records zero questions by default', () async {
        await adapter.recordActivity(
          studentId: 'student-1',
          actualMinutes: 30,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all.first.actualQuestions, 0);
      });
    });

    group('suggestRegeneration', () {
      test('returns failure when no mastery data exists for plan generation', () async {
        final result = await adapter.suggestRegeneration(studentId: 'student-1');
        expect(result.isFailure, true);
      });

      test('returns failure even when existing plan exists due to empty mastery data', () async {
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 50, totalMinutes: 300, newTopics: 5,
            reviewTopics: 3, estimatedCoverage: 0.5, focusAreas: [],
          ),
          recommendations: [],
          planDurationDays: 7,
          targetMinutesPerDay: 60.0,
          targetQuestionsPerDay: 15,
        );

        final result = await adapter.suggestRegeneration(
          studentId: 'student-1',
          adjustmentFactor: 0.8,
        );
        expect(result.isFailure, true);
      });
    });

    group('getAdherenceReport', () {
      test('returns empty report when no data exists', () async {
        final result = await adapter.getAdherenceReport('student-1');

        expect(result.isSuccess, true);
        expect(result.data!['totalDays'], 0);
        expect(result.data!['averageAdherence'], 1.0);
        expect(result.data!['lowAdherenceDays'], 0);
      });

      test('returns accurate report from stored data', () async {
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'adh_r1',
          studentId: 'student-1',
          date: DateTime.now(),
          adherenceScore: 0.8,
        ));
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'adh_r2',
          studentId: 'student-1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          adherenceScore: 0.3,
        ));

        final result = await adapter.getAdherenceReport('student-1');

        expect(result.isSuccess, true);
        expect(result.data!['totalDays'], 2);
        expect(result.data!['lowAdherenceDays'], 1);
        expect((result.data!['averageAdherence'] as double), closeTo(0.55, 0.01));
      });
    });

    group('getDailyAdherenceFeedback', () {
      test('returns null when no plan exists', () async {
        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNull);
      });

      test('returns null when plan has no daily plans for today', () async {
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: DateTime.now(),
          dailyPlans: [],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0.0, focusAreas: [],
          ),
          recommendations: [],
        );

        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNull);
      });

      test('returns null when planned minutes and questions are both zero', () async {
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: DateTime.now(),
          dailyPlans: [
            DailyPlan(
              date: DateTime.now(),
              dayNumber: 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 0,
              targetMinutes: 0,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 0, totalMinutes: 0, newTopics: 0,
            reviewTopics: 0, estimatedCoverage: 0.0, focusAreas: [],
          ),
          recommendations: [],
        );

        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNull);
      });

      test('returns low adherence feedback when ratio < 0.3', () async {
        final now = DateTime.now();
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: now,
          dailyPlans: [
            DailyPlan(
              date: now,
              dayNumber: 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 10,
              targetMinutes: 60,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 10, totalMinutes: 60, newTopics: 1,
            reviewTopics: 0, estimatedCoverage: 0.1, focusAreas: [],
          ),
          recommendations: [],
        );
        // actual = 10 min -> raio = 10/60 = 0.167 < 0.3
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'fb_low', studentId: 'student-1', date: now.dateOnly,
          plannedMinutes: 60, actualMinutes: 10,
          plannedQuestions: 10, actualQuestions: 2,
          adherenceScore: 0.17,
        ));

        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNotNull);
        expect(result, contains('10 min today vs 60 min planned'));
        expect(result, contains('redistributing'));
      });

      test('returns partial adherence feedback when ratio < 0.7', () async {
        final now = DateTime.now();
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: now,
          dailyPlans: [
            DailyPlan(
              date: now,
              dayNumber: 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 10,
              targetMinutes: 60,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 10, totalMinutes: 60, newTopics: 1,
            reviewTopics: 0, estimatedCoverage: 0.1, focusAreas: [],
          ),
          recommendations: [],
        );
        // actual = 30 min -> ratio = 30/60 = 0.5 < 0.7
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'fb_part', studentId: 'student-1', date: now.dateOnly,
          plannedMinutes: 60, actualMinutes: 30,
          plannedQuestions: 10, actualQuestions: 5,
          adherenceScore: 0.5,
        ));

        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNotNull);
        expect(result, contains('30 min today vs 60 min planned'));
        expect(result, contains('catch up'));
      });

      test('returns exceeded feedback when ratio > 1.2', () async {
        final now = DateTime.now();
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: now,
          dailyPlans: [
            DailyPlan(
              date: now,
              dayNumber: 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 10,
              targetMinutes: 60,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 10, totalMinutes: 60, newTopics: 1,
            reviewTopics: 0, estimatedCoverage: 0.1, focusAreas: [],
          ),
          recommendations: [],
        );
        // actual = 90 min -> ratio = 90/60 = 1.5 > 1.2
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'fb_exc', studentId: 'student-1', date: now.dateOnly,
          plannedMinutes: 60, actualMinutes: 90,
          plannedQuestions: 10, actualQuestions: 15,
          adherenceScore: 1.5,
        ));

        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNotNull);
        expect(result, contains('Great work'));
        expect(result, contains('90 min vs 60 min'));
      });

      test('returns null when ratio is within normal range', () async {
        final now = DateTime.now();
        planRepo.storedPlan = PersonalLearningPlan(
          studentId: 'student-1',
          generatedAt: now,
          dailyPlans: [
            DailyPlan(
              date: now,
              dayNumber: 1,
              priorityTopics: [],
              reviewQuestionIds: [],
              stretchGoalQuestionIds: [],
              targetQuestions: 10,
              targetMinutes: 60,
            ),
          ],
          summary: PlanSummary(
            totalQuestions: 10, totalMinutes: 60, newTopics: 1,
            reviewTopics: 0, estimatedCoverage: 0.1, focusAreas: [],
          ),
          recommendations: [],
        );
        // actual = 45 min -> ratio = 45/60 = 0.75 which is between 0.7 and 1.2
        await adherenceRepo.create(PlanAdherenceModel(
          id: 'fb_norm', studentId: 'student-1', date: now.dateOnly,
          plannedMinutes: 60, actualMinutes: 45,
          plannedQuestions: 10, actualQuestions: 8,
          adherenceScore: 0.75,
        ));

        final result = await adapter.getDailyAdherenceFeedback('student-1');
        expect(result, isNull);
      });
    });
  });
}
