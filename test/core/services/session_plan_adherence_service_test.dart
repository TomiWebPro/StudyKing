import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/contracts/plan_adherence_contract.dart';
import 'package:studyking/core/services/session_plan_adherence_service.dart';

void main() {
  group('SessionPlanAdherenceService', () {
    test('implements PlanAdherenceContract', () {
      final service = SessionPlanAdherenceService();
      expect(service, isA<PlanAdherenceContract>());
    });

    test('recordAdherenceForSession does not throw when called', () async {
      final service = SessionPlanAdherenceService();
      await expectLater(
        service.recordAdherenceForSession(
          studentId: 'student-1',
          actualQuestions: 10,
          actualMinutes: 30,
        ),
        completes,
      );
    });

    test('handles zero values gracefully', () async {
      final service = SessionPlanAdherenceService();
      await expectLater(
        service.recordAdherenceForSession(
          studentId: 'student-2',
          actualQuestions: 0,
          actualMinutes: 0,
        ),
        completes,
      );
    });
  });
}
