import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_service.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/teaching/data/models/tutor_session_model.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

void main() {
  group('lessonRepositoryProvider', () {
    test('creates a LessonRepository and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo1 = container.read(lessonRepositoryProvider);
      final repo2 = container.read(lessonRepositoryProvider);
      expect(repo1, isA<LessonRepository>());
      expect(repo1, same(repo2));
    });

    test('can be overridden with custom repository', () {
      final fakeRepo = LessonRepository();
      final container = ProviderContainer(
        overrides: [
          lessonRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(lessonRepositoryProvider), same(fakeRepo));
    });

    test('resolves without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(lessonRepositoryProvider),
        returnsNormally,
      );
    });

    test('uses overridden repository with seeded data', () async {
      final fakeRepo = LessonRepository();
      final container = ProviderContainer(
        overrides: [
          lessonRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(lessonRepositoryProvider);
      expect(repo, same(fakeRepo));
    });

    test('behavioral: overridden repository returns seeded data through provider', () async {
      final now = DateTime.now();
      final fakeRepo = _SeededFakeLessonRepository(seed: [
        Lesson(
          id: 'seeded-lesson', subjectId: 'sub-1', title: 'Seeded Lesson',
          topicId: 't-1', blocks: [], createdAt: now,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          lessonRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(lessonRepositoryProvider);
      final all = await repo.getAll();
      expect(all.isSuccess, isTrue);
      expect(all.data, hasLength(1));
      expect(all.data!.first.id, 'seeded-lesson');
      expect(all.data!.first.title, 'Seeded Lesson');
    });
  });

  group('tutorSessionRepositoryProvider', () {
    test('creates a TutorSessionRepository and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo1 = container.read(tutorSessionRepositoryProvider);
      final repo2 = container.read(tutorSessionRepositoryProvider);
      expect(repo1, isA<TutorSessionRepository>());
      expect(repo1, same(repo2));
    });

    test('can be overridden with custom repository', () {
      final fakeRepo = TutorSessionRepository();
      final container = ProviderContainer(
        overrides: [
          tutorSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(tutorSessionRepositoryProvider), same(fakeRepo));
    });

    test('uses overridden repository with seeded data', () async {
      final fakeRepo = TutorSessionRepository();
      final container = ProviderContainer(
        overrides: [
          tutorSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(tutorSessionRepositoryProvider);
      expect(repo, same(fakeRepo));
    });

    test('behavioral: overridden repository returns seeded sessions through provider', () async {
      final fakeRepo = _SeededFakeTutorSessionRepository(seed: [
        TutorSession(
          id: 'seeded-ts', studentId: 'stu1', subjectId: 'sub-1',
          topicId: 't-1', topicTitle: 'Algebra',
          status: SessionStatus.completed,
          startTime: DateTime.now(), plannedDurationMinutes: 45,
          lessonPlanJson: '', questionsAsked: 0, questionsCorrect: 0,
          confidenceRating: 0,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          tutorSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(tutorSessionRepositoryProvider);
      final sessions = await repo.getStudentSessions('stu1');
      expect(sessions, hasLength(1));
      expect(sessions.first.id, 'seeded-ts');
      expect(sessions.first.topicTitle, 'Algebra');
    });
  });

  group('lessonServiceProvider', () {
    test('creates a LessonService and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final svc1 = container.read(lessonServiceProvider);
      final svc2 = container.read(lessonServiceProvider);
      expect(svc1, isA<LessonService>());
      expect(svc1, same(svc2));
    });

    test('uses database with injected session repository', () async {
      final fakeSessionRepo = FakeSessionRepository(seed: [
        Session(
          id: 'wired-session',
          studentId: 'stu1',
          type: SessionType.tutoring,
          startTime: DateTime.now(),
          completed: false,
        ),
      ]);
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: fakeSessionRepo,
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: TutorSessionRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(lessonServiceProvider);
      final lessons = await service.getLessonsForStudent('stu1');
      expect(lessons, hasLength(1));
      expect(lessons.first.id, 'wired-session');
    });

    test('handles error from session repository gracefully', () async {
      final failingRepo = FakeSessionRepository();
      failingRepo.throwOnSave = true;
      final db = DatabaseService(
        topicRepository: TopicRepository(),
        questionRepository: QuestionRepository(),
        attemptRepository: AttemptRepository(),
        lessonRepository: LessonRepository(),
        sessionRepository: failingRepo,
        subjectRepository: SubjectRepository(),
        conversationRepository: ConversationRepository(),
        tutorSessionRepository: TutorSessionRepository(),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(lessonServiceProvider);
      // Should not throw; returns empty list on error
      final lessons = await service.getLessonsForStudent('stu1');
      expect(lessons, isEmpty);
    });
  });
}

class _SeededFakeLessonRepository extends LessonRepository {
  final List<Lesson> _lessons;

  _SeededFakeLessonRepository({List<Lesson>? seed}) : _lessons = List.from(seed ?? []);

  @override
  Future<Result<List<Lesson>>> getAll() async => Result.success(List.from(_lessons));

  @override
  Future<Result<Lesson?>> get(String id) async =>
      Result.success(_lessons.where((l) => l.id == id).firstOrNull);

  @override
  Future<Result<void>> save(String key, Lesson lesson) async {
    _lessons.removeWhere((l) => l.id == lesson.id);
    _lessons.add(lesson);
    return Result.success(null);
  }
}

class _SeededFakeTutorSessionRepository extends TutorSessionRepository {
  final List<TutorSession> _sessions;
  bool throwOnGet = false;

  _SeededFakeTutorSessionRepository({List<TutorSession>? seed})
      : _sessions = List.from(seed ?? []);

  @override
  Future<List<TutorSession>> getStudentSessions(String studentId) async {
    if (throwOnGet) throw Exception('Error');
    return _sessions.where((s) => s.studentId == studentId).toList();
  }
}

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions = [];
  bool throwOnSave = false;
  bool throwOnDelete = false;

  FakeSessionRepository({List<Session>? seed}) {
    if (seed != null) {
      sessions.addAll(seed);
    }
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List.from(sessions));
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    final allResult = await getAll();
    if (allResult.isFailure) return Result.failure(allResult.error);
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return Result.success(allResult.data!
        .where((s) =>
            s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            s.startTime.isBefore(end))
        .toList());
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(
      sessions.where((s) => s.studentId == studentId).toList(),
    );
  }

  @override
  Future<Result<void>> save(String key, Session session) async {
    if (throwOnSave) throw Exception('save failed');
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (throwOnDelete) throw Exception('delete failed');
    sessions.removeWhere((s) => s.id == id);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    try {
      final session = sessions.where((s) => s.id == id).firstOrNull;
      return Result.success(session);
    } catch (_) {
      return Result.success(null);
    }
  }
}
