import 'dart:async';
import '../../../core/data/database_service.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import '../../../core/data/models/topic_model.dart';

class LessonService {
  final DatabaseService _database;

  LessonService({
    required DatabaseService database,
  }) : _database = database;

  Future<List<TutorSession>> getLessonsForStudent(String studentId) async {
    return _database.tutorSessionRepository.getStudentSessions(studentId);
  }

  Future<List<TutorSession>> getLessonsByTopic(
      String studentId, String topicId) async {
    final all = await getLessonsForStudent(studentId);
    return all.where((s) => s.topicId == topicId).toList();
  }

  Future<List<Topic>> getTopicsWithLessons(String studentId) async {
    final lessons = await getLessonsForStudent(studentId);
    final topicIds = lessons.map((l) => l.topicId).toSet();
    final topics = <Topic>[];
    for (final id in topicIds) {
      final topic = await _database.topicRepository.get(id);
      if (topic != null) {
        topics.add(topic);
      }
    }
    return topics;
  }

  Future<Map<String, int>> getLessonCountBySubject(String studentId) async {
    final lessons = await getLessonsForStudent(studentId);
    final counts = <String, int>{};
    for (final lesson in lessons) {
      counts[lesson.subjectId] = (counts[lesson.subjectId] ?? 0) + 1;
    }
    return counts;
  }

  Future<double> getCompletionRate(String studentId) async {
    final lessons = await getLessonsForStudent(studentId);
    if (lessons.isEmpty) return 0.0;
    final completed =
        lessons.where((s) => s.status == SessionStatus.completed).length;
    return completed / lessons.length;
  }

  Future<int> getTotalStudyMinutes(String studentId) async {
    final lessons = await getLessonsForStudent(studentId);
    return lessons.fold<int>(0, (sum, s) {
      final duration = s.endTime != null
          ? s.endTime!.difference(s.startTime).inMinutes
          : s.plannedDurationMinutes;
      return sum + duration;
    });
  }

  Future<int> getRemainingLessonCount(
      String studentId, String subjectId) async {
    final lessons = await _database.tutorSessionRepository
        .getStudentSessions(studentId);
    final subjectLessons = lessons.where((s) => s.subjectId == subjectId);
    final completed = subjectLessons
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final total = subjectLessons.length;
    final remaining = total - completed;
    return remaining < 0 ? 0 : remaining;
  }

  Future<Map<String, double>> getProgressBySubject(String studentId) async {
    final lessons = await getLessonsForStudent(studentId);
    final progress = <String, double>{};
    final subjectLessons = <String, List<TutorSession>>{};

    for (final lesson in lessons) {
      subjectLessons.putIfAbsent(lesson.subjectId, () => []);
      subjectLessons[lesson.subjectId]!.add(lesson);
    }

    for (final entry in subjectLessons.entries) {
      final total = entry.value.length;
      final completed =
          entry.value.where((s) => s.status == SessionStatus.completed).length;
      progress[entry.key] = total > 0 ? completed / total : 0.0;
    }

    return progress;
  }

  Future<List<TutorSession>> getRecentLessons(
      String studentId, {int limit = 5}) async {
    final lessons = await getLessonsForStudent(studentId);
    lessons.sort((a, b) => b.startTime.compareTo(a.startTime));
    return lessons.take(limit).toList();
  }

  Future<List<TutorSession>> getUpcomingLessons(String studentId) async {
    final lessons = await getLessonsForStudent(studentId);
    final now = DateTime.now();
    return lessons
        .where((s) =>
            s.startTime.isAfter(now) && s.status == SessionStatus.planned)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}
