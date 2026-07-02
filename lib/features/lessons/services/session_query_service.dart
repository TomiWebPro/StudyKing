import '../../../core/errors/result.dart';
import '../../../core/data/database_service.dart';
import '../../../core/data/models/session_model.dart';
import '../../../core/data/models/topic_model.dart';

class SessionQueryService {
  final DatabaseService _database;

  SessionQueryService({
    required DatabaseService database,
  }) : _database = database;

  Future<Result<List<Session>>> getLessonsForStudent(String studentId) async {
    return _database.sessionRepository.getByStudent(studentId);
  }

  Future<Result<List<Session>>> getLessonsByTopic(
      String studentId, String topicId) async {
    final allResult = await getLessonsForStudent(studentId);
    if (allResult.isFailure) return Result.failure(allResult.error);
    final all = allResult.data!;
    return Result.success(all.where((s) => s.topicId == topicId).toList());
  }

  Future<Result<List<Topic>>> getTopicsWithLessons(String studentId) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    final topicIds = lessons.map((l) => l.topicId).whereType<String>().toSet();
    final topics = <Topic>[];
    for (final id in topicIds) {
      final topicResult = await _database.topicRepository.get(id);
      final topic = topicResult.data;
      if (topic != null) {
        topics.add(topic);
      }
    }
    return Result.success(topics);
  }

  Future<Result<Map<String, int>>> getLessonCountBySubject(String studentId) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    final counts = <String, int>{};
    for (final lesson in lessons) {
      if (lesson.subjectId != null) {
        counts[lesson.subjectId!] = (counts[lesson.subjectId!] ?? 0) + 1;
      }
    }
    return Result.success(counts);
  }

  Future<Result<double>> getCompletionRate(String studentId) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    if (lessons.isEmpty) return Result.success(0.0);
    final completed = lessons.where((s) => s.completed).length;
    return Result.success(completed / lessons.length);
  }

  Future<Result<int>> getTotalStudyMinutes(String studentId) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    return Result.success(lessons.fold<int>(0, (sum, s) {
      final duration = s.endTime != null
          ? s.endTime!.difference(s.startTime).inMinutes
          : (s.plannedDurationMinutes ?? 0);
      return sum + duration;
    }));
  }

  Future<Result<int>> getRemainingLessonCount(
      String studentId, String subjectId) async {
    final result = await _database.sessionRepository.getByStudent(studentId);
    if (result.isFailure) return Result.failure(result.error);
    final lessons = result.data!;
    final subjectLessons = lessons.where((s) => s.subjectId == subjectId);
    final completed = subjectLessons.where((s) => s.completed).length;
    final total = subjectLessons.length;
    final remaining = total - completed;
    return Result.success(remaining < 0 ? 0 : remaining);
  }

  Future<Result<Map<String, double>>> getProgressBySubject(String studentId) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    final progress = <String, double>{};
    final subjectLessons = <String, List<Session>>{};

    for (final lesson in lessons) {
      if (lesson.subjectId != null) {
        subjectLessons.putIfAbsent(lesson.subjectId!, () => []);
        subjectLessons[lesson.subjectId!]!.add(lesson);
      }
    }

    for (final entry in subjectLessons.entries) {
      final total = entry.value.length;
      final completed = entry.value.where((s) => s.completed).length;
      progress[entry.key] = total > 0 ? completed / total : 0.0;
    }

    return Result.success(progress);
  }

  Future<Result<List<Session>>> getRecentLessons(
      String studentId, {int limit = 5}) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    lessons.sort((a, b) => b.startTime.compareTo(a.startTime));
    return Result.success(lessons.take(limit).toList());
  }

  Future<Result<List<Session>>> getUpcomingLessons(String studentId) async {
    final lessonsResult = await getLessonsForStudent(studentId);
    if (lessonsResult.isFailure) return Result.failure(lessonsResult.error);
    final lessons = lessonsResult.data!;
    final now = DateTime.now();
    return Result.success(lessons
        .where((s) =>
            s.startTime.isAfter(now) && !s.completed && s.endTime == null)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime)));
  }
}
