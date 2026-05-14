import '../../../core/services/plan_adapter.dart';
import '../../../core/services/student_id_service.dart';

class SessionPlanIntegrationService {
  final PlanAdapter _planAdapter;
  final String? fixedStudentId;

  SessionPlanIntegrationService({
    PlanAdapter? planAdapter,
    this.fixedStudentId,
  }) : _planAdapter = planAdapter ?? PlanAdapter();

  String get _studentId =>
      fixedStudentId ?? StudentIdService().getStudentId();

  Future<void> recordFocusSessionCompletion({
    required int actualDurationSeconds,
    String? studentId,
  }) async {
    final id = studentId ?? _studentId;
    final actualMinutes = (actualDurationSeconds / 60).ceil().clamp(1, 480);
    await _planAdapter.recordFromFocusSession(
      studentId: id,
      actualMinutes: actualMinutes,
    );
  }

  Future<void> recordPracticeSessionCompletion({
    required int actualQuestions,
    required int elapsedMinutes,
    String? studentId,
  }) async {
    final id = studentId ?? _studentId;
    await _planAdapter.recordFromPracticeSession(
      studentId: id,
      actualQuestions: actualQuestions,
      actualMinutes: elapsedMinutes.clamp(1, 480),
    );
  }

  Future<void> recordTutorSessionCompletion({
    required int elapsedMinutes,
    String? studentId,
  }) async {
    final id = studentId ?? _studentId;
    await _planAdapter.recordFromTutorSession(
      studentId: id,
      actualMinutes: elapsedMinutes.clamp(1, 480),
    );
  }
}
