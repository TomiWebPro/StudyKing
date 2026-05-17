import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/session_model.dart';

abstract class SessionQueryContract {
  Future<void> init();
  Future<Result<void>> save(Session session);
  Future<Result<Session?>> get(String id);
  Future<Result<List<Session>>> getAll();
  Future<Result<List<Session>>> getByStudent(String studentId);
  Future<Result<List<Session>>> getByDate(DateTime date);
  Future<Result<int>> getTodayDurationMs();
  Future<bool> hasSchedulingConflict({
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  });
  Future<List<Session>> getScheduledLessons();
}
