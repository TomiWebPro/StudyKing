import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/study_session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/lessons/services/lesson_service.dart';

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic topic) => _topics[topic.id] = topic;

  @override
  Future<void> init() async {}

  @override
  Future<Topic?> get(String id) async => _topics[id];

  @override
  Future<List<Topic>> getAll() async => _topics.values.toList();
}

class _FakeTutorSessionRepository extends TutorSessionRepository {
  final Map<String, TutorSession> _sessions = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    return _sessions.values
        .where((s) => s.studentId == studentId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  void addSession(TutorSession session) => _sessions[session.id] = session;

  void clear() => _sessions.clear();
}

TutorSession _session({
  String id = 's1',
  String studentId = 'stu1',
  String subjectId = 'Math',
  String topicId = '',
  SessionStatus status = SessionStatus.completed,
  DateTime? startTime,
  DateTime? endTime,
  int plannedDurationMinutes = 45,
}) {
  final start = startTime ?? DateTime(2025, 6, 15, 10, 0);
  final tid = topicId.isNotEmpty ? topicId : 'topic-$id';
  return TutorSession(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    topicId: tid,
    topicTitle: 'Topic $id',
    status: status,
    startTime: start,
    endTime: endTime ?? start.add(Duration(minutes: plannedDurationMinutes)),
    plannedDurationMinutes: plannedDurationMinutes,
  );
}

void main() {
  late _FakeTopicRepository topicRepo;
  late _FakeTutorSessionRepository sessionRepo;
  late DatabaseService database;
  late LessonService service;

  setUp(() {
    topicRepo = _FakeTopicRepository();
    sessionRepo = _FakeTutorSessionRepository();
    database = DatabaseService(
      topicRepository: topicRepo,
      questionRepository: QuestionRepository(),
      attemptRepository: AttemptRepository(),
      lessonRepository: LessonRepository(),
      sessionRepository: StudySessionRepository(),
      subjectRepository: SubjectRepository(),
      conversationRepository: ConversationRepository(),
      tutorSessionRepository: sessionRepo,
    );
    service = LessonService(database: database);
  });

  group('getLessonsForStudent', () {
    test('returns empty list for student with no lessons', () async {
      final lessons = await service.getLessonsForStudent('stu1');
      expect(lessons, isEmpty);
    });

    test('returns only sessions for the given student', () async {
      sessionRepo.addSession(_session(id: 's1', studentId: 'stu1'));
      sessionRepo.addSession(_session(id: 's2', studentId: 'stu2'));

      final lessons = await service.getLessonsForStudent('stu1');
      expect(lessons, hasLength(1));
      expect(lessons.first.id, 's1');
    });
  });

  group('getLessonsByTopic', () {
    test('returns only lessons for the given topic', () async {
      sessionRepo.addSession(_session(id: 's1', topicId: 'topic-a'));
      sessionRepo.addSession(_session(id: 's2', topicId: 'topic-b'));

      final lessons = await service.getLessonsByTopic('stu1', 'topic-a');
      expect(lessons, hasLength(1));
      expect(lessons.first.topicId, 'topic-a');
    });
  });

  group('getTopicsWithLessons', () {
    test('returns topics that have lessons', () async {
      topicRepo.addTopic(Topic(
        id: 't1',
        subjectId: 'Math',
        title: 'Algebra',
        description: 'Algebraic concepts',
        syllabusText: 'Math syllabus',
      ));
      sessionRepo.addSession(_session(id: 's1', topicId: 't1'));

      final topics = await service.getTopicsWithLessons('stu1');
      expect(topics, hasLength(1));
      expect(topics.first.id, 't1');
      expect(topics.first.title, 'Algebra');
    });

    test('skips topics that no longer exist', () async {
      sessionRepo.addSession(_session(id: 's1', topicId: 'nonexistent'));

      final topics = await service.getTopicsWithLessons('stu1');
      expect(topics, isEmpty);
    });

    test('deduplicates topics with multiple lessons', () async {
      topicRepo.addTopic(Topic(
        id: 't1',
        subjectId: 'Math',
        title: 'Algebra',
        description: 'Algebraic concepts',
        syllabusText: 'Math syllabus',
      ));
      sessionRepo.addSession(_session(id: 's1', topicId: 't1'));
      sessionRepo.addSession(_session(id: 's2', topicId: 't1'));

      final topics = await service.getTopicsWithLessons('stu1');
      expect(topics, hasLength(1));
    });
  });

  group('getLessonCountBySubject', () {
    test('returns correct counts per subject', () async {
      sessionRepo.addSession(_session(id: 's1', subjectId: 'Math'));
      sessionRepo.addSession(_session(id: 's2', subjectId: 'Math'));
      sessionRepo.addSession(_session(id: 's3', subjectId: 'Physics'));

      final counts = await service.getLessonCountBySubject('stu1');
      expect(counts['Math'], 2);
      expect(counts['Physics'], 1);
    });

    test('returns empty map when no lessons', () async {
      final counts = await service.getLessonCountBySubject('stu1');
      expect(counts, isEmpty);
    });
  });

  group('getCompletionRate', () {
    test('returns 0.0 when no lessons exist', () async {
      final rate = await service.getCompletionRate('stu1');
      expect(rate, 0.0);
    });

    test('returns 0.0 when no lessons are completed', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        status: SessionStatus.planned,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        status: SessionStatus.inProgress,
      ));

      final rate = await service.getCompletionRate('stu1');
      expect(rate, 0.0);
    });

    test('returns 1.0 when all lessons are completed', () async {
      sessionRepo.addSession(_session(id: 's1', status: SessionStatus.completed));
      sessionRepo.addSession(_session(id: 's2', status: SessionStatus.completed));

      final rate = await service.getCompletionRate('stu1');
      expect(rate, 1.0);
    });

    test('returns correct ratio for mixed statuses', () async {
      sessionRepo.addSession(_session(id: 's1', status: SessionStatus.completed));
      sessionRepo.addSession(_session(id: 's2', status: SessionStatus.completed));
      sessionRepo.addSession(_session(id: 's3', status: SessionStatus.planned));

      final rate = await service.getCompletionRate('stu1');
      expect(rate, closeTo(2 / 3, 0.001));
    });
  });

  group('getTotalStudyMinutes', () {
    test('returns 0 when no lessons', () async {
      final minutes = await service.getTotalStudyMinutes('stu1');
      expect(minutes, 0);
    });

    test('sums duration from endTime - startTime when endTime is set', () async {
      final start = DateTime(2025, 6, 15, 10, 0);
      final end = start.add(const Duration(minutes: 90));
      sessionRepo.addSession(_session(
        id: 's1',
        startTime: start,
        endTime: end,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        startTime: DateTime(2025, 6, 15, 14, 0),
        endTime: DateTime(2025, 6, 15, 14, 30),
      ));

      final minutes = await service.getTotalStudyMinutes('stu1');
      expect(minutes, 120);
    });

    test('falls back to plannedDurationMinutes when endTime is null', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        startTime: DateTime(2025, 6, 15, 10, 0),
        endTime: null,
        plannedDurationMinutes: 60,
      ));

      final minutes = await service.getTotalStudyMinutes('stu1');
      expect(minutes, 60);
    });
  });

  group('getRemainingLessonCount', () {
    test('returns 0 when no lessons for subject', () async {
      final remaining = await service.getRemainingLessonCount('stu1', 'Math');
      expect(remaining, 0);
    });

    test('returns total when no lessons are completed', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));

      final remaining = await service.getRemainingLessonCount('stu1', 'Math');
      expect(remaining, 2);
    });

    test('returns count of non-completed lessons', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.completed,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));
      sessionRepo.addSession(_session(
        id: 's3',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));

      final remaining = await service.getRemainingLessonCount('stu1', 'Math');
      expect(remaining, 2);
    });

    test('ignores lessons from other subjects', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        subjectId: 'Physics',
        status: SessionStatus.planned,
      ));

      final remaining = await service.getRemainingLessonCount('stu1', 'Math');
      expect(remaining, 1);
    });

    test('returns 0 when remaining would be negative', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.completed,
      ));

      final remaining = await service.getRemainingLessonCount('stu1', 'Math');
      expect(remaining, 0);
    });
  });

  group('getProgressBySubject', () {
    test('returns empty map when no lessons', () async {
      final progress = await service.getProgressBySubject('stu1');
      expect(progress, isEmpty);
    });

    test('returns 1.0 when all lessons in a subject are completed', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.completed,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        subjectId: 'Math',
        status: SessionStatus.completed,
      ));

      final progress = await service.getProgressBySubject('stu1');
      expect(progress['Math'], 1.0);
    });

    test('returns correct ratio per subject', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.completed,
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));
      sessionRepo.addSession(_session(
        id: 's3',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));
      sessionRepo.addSession(_session(
        id: 's4',
        subjectId: 'Physics',
        status: SessionStatus.completed,
      ));

      final progress = await service.getProgressBySubject('stu1');
      expect(progress['Math'], closeTo(1 / 3, 0.001));
      expect(progress['Physics'], 1.0);
    });

    test('returns 0.0 when no lessons in a subject are completed', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        subjectId: 'Math',
        status: SessionStatus.planned,
      ));

      final progress = await service.getProgressBySubject('stu1');
      expect(progress['Math'], 0.0);
    });
  });

  group('getRecentLessons', () {
    test('returns most recent lessons up to default limit', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        startTime: DateTime(2025, 6, 10),
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        startTime: DateTime(2025, 6, 15),
      ));
      sessionRepo.addSession(_session(
        id: 's3',
        startTime: DateTime(2025, 6, 12),
      ));

      final recent = await service.getRecentLessons('stu1');
      expect(recent, hasLength(3));
      expect(recent.first.id, 's2');
    });

    test('respects custom limit', () async {
      sessionRepo.addSession(_session(id: 's1', startTime: DateTime(2025, 6, 10)));
      sessionRepo.addSession(_session(id: 's2', startTime: DateTime(2025, 6, 12)));
      sessionRepo.addSession(_session(id: 's3', startTime: DateTime(2025, 6, 14)));

      final recent = await service.getRecentLessons('stu1', limit: 2);
      expect(recent, hasLength(2));
    });

    test('returns empty when no lessons', () async {
      final recent = await service.getRecentLessons('stu1');
      expect(recent, isEmpty);
    });
  });

  group('getUpcomingLessons', () {
    test('returns only planned lessons in the future', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        status: SessionStatus.planned,
        startTime: DateTime.now().add(const Duration(days: 1)),
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        status: SessionStatus.completed,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      ));
      sessionRepo.addSession(_session(
        id: 's3',
        status: SessionStatus.planned,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      ));

      final upcoming = await service.getUpcomingLessons('stu1');
      expect(upcoming, hasLength(1));
      expect(upcoming.first.id, 's1');
    });

    test('returns empty when no upcoming lessons', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        status: SessionStatus.completed,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      ));

      final upcoming = await service.getUpcomingLessons('stu1');
      expect(upcoming, isEmpty);
    });

    test('sorts upcoming lessons by start time ascending', () async {
      sessionRepo.addSession(_session(
        id: 's1',
        status: SessionStatus.planned,
        startTime: DateTime.now().add(const Duration(days: 3)),
      ));
      sessionRepo.addSession(_session(
        id: 's2',
        status: SessionStatus.planned,
        startTime: DateTime.now().add(const Duration(days: 1)),
      ));

      final upcoming = await service.getUpcomingLessons('stu1');
      expect(upcoming.first.id, 's2');
    });
  });
}
