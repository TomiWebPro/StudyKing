import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/lessons/services/session_query_service.dart';

class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions = [];

  void addSession(Session s) => _sessions.add(s);

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(_sessions);
  }
}

class _FakeTopicRepository extends TopicRepository {
  final Map<String, Topic> _topics = {};

  void addTopic(Topic t) => _topics[t.id] = t;

  @override
  Future<Result<Topic?>> get(String id) async {
    return Result.success(_topics[id]);
  }
}

DatabaseService _createFakeDb({
  required SessionRepository sessionRepository,
  required TopicRepository topicRepository,
}) {
  return DatabaseService(
    topicRepository: topicRepository,
    questionRepository: QuestionRepository(),
    attemptRepository: AttemptRepository(),
    lessonRepository: LessonRepository(),
    sessionRepository: sessionRepository,
    subjectRepository: SubjectRepository(),
    conversationRepository: ConversationRepository(),
    tutorSessionRepository: TutorSessionRepository(),
  );
}

void main() {
  late _FakeSessionRepository fakeSessionRepo;
  late _FakeTopicRepository fakeTopicRepo;
  late DatabaseService fakeDb;
  late SessionQueryService service;
  const studentId = 'student-1';

  setUp(() {
    fakeSessionRepo = _FakeSessionRepository();
    fakeTopicRepo = _FakeTopicRepository();
    fakeDb = _createFakeDb(
      sessionRepository: fakeSessionRepo,
      topicRepository: fakeTopicRepo,
    );
    service = SessionQueryService(database: fakeDb);
  });

  group('getLessonsForStudent', () {
    test('returns empty list when no sessions', () async {
      final result = await service.getLessonsForStudent(studentId);
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('returns all sessions for student', () async {
      final now = DateTime(2025, 6, 1);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        studentId: studentId,
      ));
      fakeSessionRepo.addSession(Session(
        id: 's2',
        startTime: now.add(const Duration(hours: 1)),
        studentId: studentId,
      ));

      final result = await service.getLessonsForStudent(studentId);
      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
    });
  });

  group('getLessonsByTopic', () {
    test('filters by topic ID', () async {
      final now = DateTime(2025, 6, 1);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        studentId: studentId,
        topicId: 'topic-a',
      ));
      fakeSessionRepo.addSession(Session(
        id: 's2',
        startTime: now,
        studentId: studentId,
        topicId: 'topic-b',
      ));

      final result = await service.getLessonsByTopic(studentId, 'topic-a');
      expect(result.isSuccess, true);
      final topicALessons = result.data!;
      expect(topicALessons.length, 1);
      expect(topicALessons.first.id, 's1');
    });
  });

  group('getTopicsWithLessons', () {
    test('returns topics that have lessons', () async {
      final now = DateTime(2025, 6, 1);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        studentId: studentId,
        topicId: 'topic-a',
      ));
      fakeTopicRepo.addTopic(Topic(
        id: 'topic-a',
        title: 'Algebra',
        description: '',
        syllabusText: '',
        subjectId: 'subj-1',
      ));

      final result = await service.getTopicsWithLessons(studentId);
      expect(result.isSuccess, true);
      final topics = result.data!;
      expect(topics.length, 1);
      expect(topics.first.title, 'Algebra');
    });
  });

  group('getLessonCountBySubject', () {
    test('counts lessons per subject', () async {
      final now = DateTime(2025, 6, 1);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        studentId: studentId,
        subjectId: 'subj-a',
      ));
      fakeSessionRepo.addSession(Session(
        id: 's2',
        startTime: now,
        studentId: studentId,
        subjectId: 'subj-a',
      ));
      fakeSessionRepo.addSession(Session(
        id: 's3',
        startTime: now,
        studentId: studentId,
        subjectId: 'subj-b',
      ));

      final result = await service.getLessonCountBySubject(studentId);
      expect(result.isSuccess, true);
      final counts = result.data!;
      expect(counts['subj-a'], 2);
      expect(counts['subj-b'], 1);
    });
  });

  group('getCompletionRate', () {
    test('returns 0 when no lessons', () async {
      final result = await service.getCompletionRate(studentId);
      expect(result.isSuccess, true);
      expect(result.data, 0.0);
    });

    test('returns ratio of completed lessons', () async {
      final now = DateTime(2025, 6, 1);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        studentId: studentId,
        completed: true,
      ));
      fakeSessionRepo.addSession(Session(
        id: 's2',
        startTime: now,
        studentId: studentId,
        completed: false,
      ));
      fakeSessionRepo.addSession(Session(
        id: 's3',
        startTime: now,
        studentId: studentId,
        completed: true,
      ));

      final result = await service.getCompletionRate(studentId);
      expect(result.isSuccess, true);
      expect(result.data, closeTo(2.0 / 3.0, 0.001));
    });
  });

  group('getTotalStudyMinutes', () {
    test('returns sum of lesson durations', () async {
      final now = DateTime(2025, 6, 1, 10, 0);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 45)),
        studentId: studentId,
      ));
      fakeSessionRepo.addSession(Session(
        id: 's2',
        startTime: now,
        studentId: studentId,
        plannedDurationMinutes: 30,
      ));

      final result = await service.getTotalStudyMinutes(studentId);
      expect(result.isSuccess, true);
      expect(result.data, 75);
    });
  });

  group('getRemainingLessonCount', () {
    test('returns remaining lessons for subject', () async {
      final now = DateTime(2025, 6, 1);
      fakeSessionRepo.addSession(Session(
        id: 's1',
        startTime: now,
        studentId: studentId,
        subjectId: 'subj-a',
        completed: true,
      ));
      fakeSessionRepo.addSession(Session(
        id: 's2',
        startTime: now,
        studentId: studentId,
        subjectId: 'subj-a',
        completed: false,
      ));

      final result = await service.getRemainingLessonCount(studentId, 'subj-a');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });
  });

  group('getRecentLessons', () {
    test('returns most recent lessons limited by count', () async {
      final now = DateTime(2025, 6, 5);
      for (var i = 0; i < 10; i++) {
        fakeSessionRepo.addSession(Session(
          id: 's$i',
          startTime: now.subtract(Duration(days: i)),
          studentId: studentId,
        ));
      }

      const limit = 3;
      final result = await service.getRecentLessons(studentId, limit: limit);
      expect(result.isSuccess, true);
      final recent = result.data!;
      expect(recent.length, limit);
      expect(recent.first.startTime.isAfter(recent.last.startTime), isTrue);
    });
  });

  group('getUpcomingLessons', () {
    test('returns only future, uncompleted lessons', () async {
      final now = DateTime(2025, 6, 10);
      fakeSessionRepo.addSession(Session(
        id: 'future-1',
        startTime: now.add(const Duration(days: 1)),
        studentId: studentId,
        completed: false,
      ));
      fakeSessionRepo.addSession(Session(
        id: 'past-1',
        startTime: now.subtract(const Duration(days: 1)),
        studentId: studentId,
        completed: true,
      ));
      fakeSessionRepo.addSession(Session(
        id: 'ongoing-1',
        startTime: now.subtract(const Duration(hours: 1)),
        studentId: studentId,
        endTime: now,
      ));

      final result = await service.getUpcomingLessons(studentId);
      expect(result.isSuccess, true);
      final upcoming = result.data!;
      expect(upcoming.length, 1);
      expect(upcoming.first.id, 'future-1');
    });
  });
}
