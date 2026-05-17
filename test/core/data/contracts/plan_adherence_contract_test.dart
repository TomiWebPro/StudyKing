import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/contracts/plan_adherence_contract.dart';

class _TestPlanAdherenceContract implements PlanAdherenceContract {
  String? capturedStudentId;
  int? capturedActualQuestions;
  int? capturedActualMinutes;

  @override
  Future<void> recordAdherenceForSession({
    required String studentId,
    required int actualQuestions,
    required int actualMinutes,
  }) async {
    capturedStudentId = studentId;
    capturedActualQuestions = actualQuestions;
    capturedActualMinutes = actualMinutes;
  }
}

void main() {
  group('PlanAdherenceContract', () {
    test('can be implemented and called', () async {
      final impl = _TestPlanAdherenceContract();
      await impl.recordAdherenceForSession(
        studentId: 'student-1',
        actualQuestions: 15,
        actualMinutes: 45,
      );
      expect(impl.capturedStudentId, 'student-1');
      expect(impl.capturedActualQuestions, 15);
      expect(impl.capturedActualMinutes, 45);
    });

    test('handles zero values', () async {
      final impl = _TestPlanAdherenceContract();
      await impl.recordAdherenceForSession(
        studentId: 'student-2',
        actualQuestions: 0,
        actualMinutes: 0,
      );
      expect(impl.capturedActualQuestions, 0);
      expect(impl.capturedActualMinutes, 0);
    });
  });
}
