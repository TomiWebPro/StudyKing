import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/core/services/student_id_service.dart';

class GetStudentStatsTool extends AgentTool {
  final StudyProgressTracker _progressTracker;
  final StudentIdService _studentIdService;

  GetStudentStatsTool({
    required StudyProgressTracker progressTracker,
    required StudentIdService studentIdService,
  })  : _progressTracker = progressTracker,
        _studentIdService = studentIdService;

  @override
  String get name => 'get_student_stats';

  @override
  String get description =>
      'Get overall student performance statistics and study data.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {},
    'required': [],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final studentId = _studentIdService.getStudentId();
    final stats = await _progressTracker.getOverallStats(studentId);
    return {
      'totalAttempts': stats['totalAttempts'] ?? 0,
      'correctAttempts': stats['correctAttempts'] ?? 0,
      'accuracy': stats['accuracy'] ?? 0,
      'topicsStudied': stats['topicsStudied'] ?? 0,
      'weeklyActivity': stats['weeklyActivity'] ?? 0,
      'totalStudyTimeHours': stats['totalStudyTimeHours'] ?? 0,
    };
  }
}
