import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/features/planner/data/repositories/plan_repository.dart';
import 'package:studyking/core/services/plan_adapter.dart';
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
  Future<PersonalLearningPlan?> loadPlan(String studentId) async {
    return storedPlan;
  }

  @override
  Future<void> savePlan(PersonalLearningPlan plan) async {
    storedPlan = plan;
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
  group('PlanAdapter', () {
    late _FakePlanAdherenceRepository adherenceRepo;
    late _FakePlanRepository planRepo;
    late PlanAdapter adapter;

    setUp(() {
      adherenceRepo = _FakePlanAdherenceRepository();
      planRepo = _FakePlanRepository();
      adapter = PlanAdapter(
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

    group('recordFromFocusSession', () {
      test('records focus session adherence', () async {
        await adapter.recordFromFocusSession(
          studentId: 'student-1',
          actualMinutes: 25,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all, hasLength(1));
        expect(all.first.actualMinutes, 25);
      });

      test('records zero questions for focus sessions', () async {
        await adapter.recordFromFocusSession(
          studentId: 'student-1',
          actualMinutes: 30,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all.first.actualQuestions, 0);
      });
    });

    group('recordFromPracticeSession', () {
      test('records practice session adherence', () async {
        await adapter.recordFromPracticeSession(
          studentId: 'student-1',
          actualQuestions: 15,
          actualMinutes: 45,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all, hasLength(1));
        expect(all.first.actualQuestions, 15);
        expect(all.first.actualMinutes, 45);
      });
    });

    group('recordFromTutorSession', () {
      test('records tutor session adherence', () async {
        await adapter.recordFromTutorSession(
          studentId: 'student-1',
          actualMinutes: 50,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all, hasLength(1));
        expect(all.first.actualMinutes, 50);
      });

      test('records zero questions for tutor sessions', () async {
        await adapter.recordFromTutorSession(
          studentId: 'student-1',
          actualMinutes: 30,
        );

        final all = await adherenceRepo.getByStudent('student-1');
        expect(all.first.actualQuestions, 0);
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
  });
}
