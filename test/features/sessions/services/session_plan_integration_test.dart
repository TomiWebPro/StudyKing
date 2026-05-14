import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/personal_learning_plan_model.dart';
import 'package:studyking/core/data/models/plan_adherence_model.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/data/repositories/plan_repository.dart';
import 'package:studyking/core/services/plan_adapter.dart';
import 'package:studyking/features/sessions/services/session_plan_integration_service.dart';

class _FakePlanAdherenceRepository extends PlanAdherenceRepository {
  final List<PlanAdherenceModel> _storage = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> save(PlanAdherenceModel model) async {
    _storage.add(model);
  }

  @override
  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    return _storage.where((m) => m.studentId == studentId).toList();
  }

  List<PlanAdherenceModel> get stored => _storage;
}

class _FakePlanRepository extends PlanRepository {
  @override
  Future<void> init() async {}

  @override
  Future<PersonalLearningPlan?> loadPlan(String studentId) async => null;
}

class _FakePlanAdapter extends PlanAdapter {
  _FakePlanAdapter({required PlanAdherenceRepository adherenceRepository})
      : super(adherenceRepository: adherenceRepository, planRepository: _FakePlanRepository());

  final List<Map<String, dynamic>> records = [];

  @override
  Future<void> recordFromFocusSession({
    required String studentId,
    required int actualMinutes,
    String? planId,
  }) async {
    records.add({'type': 'focus', 'studentId': studentId, 'actualMinutes': actualMinutes});
  }

  @override
  Future<void> recordFromPracticeSession({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
    String? planId,
  }) async {
    records.add({
      'type': 'practice',
      'studentId': studentId,
      'actualQuestions': actualQuestions,
      'actualMinutes': actualMinutes,
    });
  }

  @override
  Future<void> recordFromTutorSession({
    required String studentId,
    required int actualMinutes,
    String? planId,
  }) async {
    records.add({'type': 'tutor', 'studentId': studentId, 'actualMinutes': actualMinutes});
  }
}

void main() {
  group('SessionPlanIntegrationService', () {
    late _FakePlanAdapter fakeAdapter;
    late SessionPlanIntegrationService service;

    setUp(() {
      final adherenceRepo = _FakePlanAdherenceRepository();
      fakeAdapter = _FakePlanAdapter(adherenceRepository: adherenceRepo);
      service = SessionPlanIntegrationService(
        planAdapter: fakeAdapter,
        fixedStudentId: 'test-student',
      );
    });

    test('recordFocusSessionCompletion records focus session adherence', () async {
      await service.recordFocusSessionCompletion(
        actualDurationSeconds: 1500,
      );

      expect(fakeAdapter.records, hasLength(1));
      expect(fakeAdapter.records[0]['type'], 'focus');
      expect(fakeAdapter.records[0]['studentId'], 'test-student');
      expect(fakeAdapter.records[0]['actualMinutes'], 25);
    });

    test('recordFocusSessionCompletion uses provided studentId', () async {
      await service.recordFocusSessionCompletion(
        actualDurationSeconds: 600,
        studentId: 'custom-student',
      );

      expect(fakeAdapter.records[0]['studentId'], 'custom-student');
    });

    test('recordPracticeSessionCompletion records practice session adherence', () async {
      await service.recordPracticeSessionCompletion(
        actualQuestions: 10,
        elapsedMinutes: 30,
      );

      expect(fakeAdapter.records, hasLength(1));
      expect(fakeAdapter.records[0]['type'], 'practice');
      expect(fakeAdapter.records[0]['actualQuestions'], 10);
      expect(fakeAdapter.records[0]['actualMinutes'], 30);
    });

    test('recordTutorSessionCompletion records tutor session adherence', () async {
      await service.recordTutorSessionCompletion(
        elapsedMinutes: 45,
      );

      expect(fakeAdapter.records, hasLength(1));
      expect(fakeAdapter.records[0]['type'], 'tutor');
      expect(fakeAdapter.records[0]['studentId'], 'test-student');
      expect(fakeAdapter.records[0]['actualMinutes'], 45);
    });

    test('elapsed minutes clamped to valid range', () async {
      await service.recordTutorSessionCompletion(elapsedMinutes: 0);
      expect(fakeAdapter.records[0]['actualMinutes'], 1);

      await service.recordPracticeSessionCompletion(
        actualQuestions: 5,
        elapsedMinutes: 999,
      );
      expect(fakeAdapter.records[1]['actualMinutes'], 480);
    });
  });
}
