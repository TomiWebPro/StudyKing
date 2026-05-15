import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_service.dart';

class _FakeLessonService extends LessonService {
  final List<TutorSession> _lessons;
  final double _completionRate;
  final Map<String, double> _progressBySubject;
  final Map<String, int> _countBySubject;
  final List<TutorSession> _upcoming;
  final List<TutorSession> _recent;
  final Exception? _error;

  _FakeLessonService({
    List<TutorSession> lessons = const [],
    double completionRate = 0.0,
    Map<String, double> progressBySubject = const {},
    Map<String, int> countBySubject = const {},
    List<TutorSession> upcoming = const [],
    List<TutorSession> recent = const [],
    Exception? error,
  })  : _lessons = lessons,
        _completionRate = completionRate,
        _progressBySubject = progressBySubject,
        _countBySubject = countBySubject,
        _upcoming = upcoming,
        _recent = recent,
        _error = error,
        super(
          database: DatabaseService(
            topicRepository: TopicRepository(),
            questionRepository: QuestionRepository(),
            attemptRepository: AttemptRepository(),
            lessonRepository: LessonRepository(),
            sessionRepository: SessionRepository(),
            subjectRepository: SubjectRepository(),
            conversationRepository: ConversationRepository(),
            tutorSessionRepository: TutorSessionRepository(),
          ),
        );

  @override
  Future<List<TutorSession>> getLessonsForStudent(String studentId) async {
    if (_error != null) throw _error;
    return _lessons;
  }

  @override
  Future<double> getCompletionRate(String studentId) async {
    if (_error != null) throw _error;
    return _completionRate;
  }

  @override
  Future<Map<String, double>> getProgressBySubject(String studentId) async {
    if (_error != null) throw _error;
    return _progressBySubject;
  }

  @override
  Future<Map<String, int>> getLessonCountBySubject(String studentId) async {
    if (_error != null) throw _error;
    return _countBySubject;
  }

  @override
  Future<List<TutorSession>> getUpcomingLessons(String studentId) async {
    if (_error != null) throw _error;
    return _upcoming;
  }

  @override
  Future<List<TutorSession>> getRecentLessons(
    String studentId, {
    int limit = 5,
  }) async {
    if (_error != null) throw _error;
    return _recent;
  }
}

TutorSession _session({
  String id = 's1',
  String studentId = 'stu1',
  String subjectId = 'Math',
  String topicId = 'topic-1',
  String topicTitle = 'Algebra',
  SessionStatus status = SessionStatus.completed,
  DateTime? startTime,
  DateTime? endTime,
  int plannedDurationMinutes = 45,
}) {
  final start = startTime ?? DateTime(2025, 6, 15, 10, 0);
  return TutorSession(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    topicId: topicId,
    topicTitle: topicTitle,
    status: status,
    startTime: start,
    endTime: endTime ?? start.add(Duration(minutes: plannedDurationMinutes)),
    plannedDurationMinutes: plannedDurationMinutes,
  );
}

void main() {
  group('lessonRepositoryProvider', () {
    test('creates a LessonRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(lessonRepositoryProvider);
      expect(repo, isA<LessonRepository>());
    });
  });

  group('tutorSessionRepositoryProvider', () {
    test('creates a TutorSessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(tutorSessionRepositoryProvider);
      expect(repo, isA<TutorSessionRepository>());
    });
  });

  group('lessonServiceProvider', () {
    test('creates a LessonService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(lessonServiceProvider);
      expect(service, isA<LessonService>());
    });
  });

  group('studentLessonsProvider', () {
    test('provider is not null', () {
      expect(studentLessonsProvider, isNotNull);
    });

    test('returns lessons from service for given student', () async {
      final lessons = [
        _session(id: 's1', studentId: 'stu1'),
        _session(id: 's2', studentId: 'stu1'),
      ];
      final fakeService = _FakeLessonService(lessons: lessons);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(studentLessonsProvider('stu1').future);
      expect(result, hasLength(2));
      expect(result[0].id, 's1');
      expect(result[1].id, 's2');
    });

    test('returns empty list when service returns no lessons', () async {
      final fakeService = _FakeLessonService(lessons: []);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(studentLessonsProvider('stu1').future);
      expect(result, isEmpty);
    });

    test('propagates error from service', () async {
      final fakeService = _FakeLessonService(error: Exception('fail'));
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(studentLessonsProvider('stu1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('lessonCompletionRateProvider', () {
    test('provider is not null', () {
      expect(lessonCompletionRateProvider, isNotNull);
    });

    test('returns completion rate from service', () async {
      final fakeService = _FakeLessonService(completionRate: 0.75);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(lessonCompletionRateProvider('stu1').future);
      expect(result, 0.75);
    });

    test('returns 0.0 when service returns zero rate', () async {
      final fakeService = _FakeLessonService(completionRate: 0.0);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(lessonCompletionRateProvider('stu1').future);
      expect(result, 0.0);
    });

    test('returns 1.0 for full completion', () async {
      final fakeService = _FakeLessonService(completionRate: 1.0);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(lessonCompletionRateProvider('stu1').future);
      expect(result, 1.0);
    });

    test('propagates error from service', () async {
      final fakeService = _FakeLessonService(error: Exception('fail'));
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(lessonCompletionRateProvider('stu1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('lessonProgressBySubjectProvider', () {
    test('provider is not null', () {
      expect(lessonProgressBySubjectProvider, isNotNull);
    });

    test('returns progress map from service', () async {
      final fakeService = _FakeLessonService(
        progressBySubject: {'Math': 0.5, 'Physics': 1.0},
      );
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(lessonProgressBySubjectProvider('stu1').future);
      expect(result, {'Math': 0.5, 'Physics': 1.0});
    });

    test('returns empty map when no progress data', () async {
      final fakeService = _FakeLessonService(progressBySubject: {});
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(lessonProgressBySubjectProvider('stu1').future);
      expect(result, isEmpty);
    });

    test('propagates error from service', () async {
      final fakeService = _FakeLessonService(error: Exception('fail'));
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(lessonProgressBySubjectProvider('stu1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('lessonCountBySubjectProvider', () {
    test('provider is not null', () {
      expect(lessonCountBySubjectProvider, isNotNull);
    });

    test('returns count map from service', () async {
      final fakeService = _FakeLessonService(
        countBySubject: {'Math': 3, 'Physics': 1},
      );
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(lessonCountBySubjectProvider('stu1').future);
      expect(result, {'Math': 3, 'Physics': 1});
    });

    test('returns empty map when no lessons', () async {
      final fakeService = _FakeLessonService(countBySubject: {});
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(lessonCountBySubjectProvider('stu1').future);
      expect(result, isEmpty);
    });

    test('propagates error from service', () async {
      final fakeService = _FakeLessonService(error: Exception('fail'));
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(lessonCountBySubjectProvider('stu1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('upcomingLessonsProvider', () {
    test('provider is not null', () {
      expect(upcomingLessonsProvider, isNotNull);
    });

    test('returns upcoming lessons from service', () async {
      final upcoming = [
        _session(id: 's1', status: SessionStatus.planned),
        _session(id: 's2', status: SessionStatus.planned),
      ];
      final fakeService = _FakeLessonService(upcoming: upcoming);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(upcomingLessonsProvider('stu1').future);
      expect(result, hasLength(2));
      expect(result[0].id, 's1');
      expect(result[1].id, 's2');
    });

    test('returns empty list when no upcoming lessons', () async {
      final fakeService = _FakeLessonService(upcoming: []);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(upcomingLessonsProvider('stu1').future);
      expect(result, isEmpty);
    });

    test('propagates error from service', () async {
      final fakeService = _FakeLessonService(error: Exception('fail'));
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(upcomingLessonsProvider('stu1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('recentLessonsProvider', () {
    test('provider is not null', () {
      expect(recentLessonsProvider, isNotNull);
    });

    test('returns recent lessons from service', () async {
      final recent = [
        _session(id: 's3'),
        _session(id: 's2'),
        _session(id: 's1'),
      ];
      final fakeService = _FakeLessonService(recent: recent);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(recentLessonsProvider('stu1').future);
      expect(result, hasLength(3));
      expect(result[0].id, 's3');
      expect(result[1].id, 's2');
      expect(result[2].id, 's1');
    });

    test('returns empty list when no recent lessons', () async {
      final fakeService = _FakeLessonService(recent: []);
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(recentLessonsProvider('stu1').future);
      expect(result, isEmpty);
    });

    test('propagates error from service', () async {
      final fakeService = _FakeLessonService(error: Exception('fail'));
      final container = ProviderContainer(overrides: [
        lessonServiceProvider.overrideWithValue(fakeService),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(recentLessonsProvider('stu1').future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
