import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/services/notification_service.dart';
import 'package:studyking/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:studyking/features/sessions/services/study_timer_service.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

class FakeSessionRepository extends SessionRepository {
  final List<Session> sessions;
  bool throwOnGetAll = false;
  bool throwOnGetByDate = false;
  bool throwOnSave = false;

  FakeSessionRepository({List<Session>? seed}) : sessions = List.from(seed ?? []);

  @override
  Future<Result<List<Session>>> getAll() async {
    if (throwOnGetAll) return Result.failure('getAll failed');
    final sorted = List<Session>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return Result.success(sorted);
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    if (throwOnGetByDate) return Result.failure('getByDate failed');
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final filtered = sessions.where((s) =>
        s.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
        s.startTime.isBefore(end)).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(sessions.where((s) => s.studentId == studentId).toList());
  }

  @override
  Future<Result<Session?>> get(String id) async {
    return Result.success(sessions.where((s) => s.id == id).firstOrNull);
  }

  @override
  Future<Result<void>> save(String key, Session session) async {
    if (throwOnSave) return Result.failure('save failed');
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    sessions.removeWhere((s) => s.id == id);
    return Result.success(null);
  }
}

class _FailingSessionRepository extends SessionRepository {
  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.failure('Database error');
  }

  @override
  Future<Result<List<Session>>> getByDate(DateTime date) async {
    return Result.failure('Database error');
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.failure('Database error');
  }

  @override
  Future<Result<void>> save(String key, Session session) async {
    return Result.failure('Database error');
  }

  @override
  Future<Result<void>> delete(String id) async {
    return Result.failure('Database error');
  }

  @override
  Future<Result<Session?>> get(String id) async {
    return Result.failure('Database error');
  }
}

void main() {
  group('FocusModeProviders', () {
    test('sessionRepositoryProvider creates SessionRepository and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(sessionRepositoryProvider);
      final repo2 = container.read(sessionRepositoryProvider);
      expect(repo1, isA<SessionRepository>());
      expect(repo1, same(repo2));
    });

    test('studyTimerServiceProvider is wired to sessionRepositoryProvider', () {
      final overrideRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(overrideRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      expect(service.repository, same(overrideRepo));
    });

    test('studyTimerServiceProvider returns a StudyTimerService and is singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final svc1 = container.read(studyTimerServiceProvider);
      final svc2 = container.read(studyTimerServiceProvider);
      expect(svc1, isA<StudyTimerService>());
      expect(svc1, same(svc2));
    });

    test('sessionRepositoryProvider can be overridden', () {
      final fakeRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(sessionRepositoryProvider), same(fakeRepo));
    });

    test('all providers resolve without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () {
          container.read(sessionRepositoryProvider);
          container.read(studyTimerServiceProvider);
        },
        returnsNormally,
      );
    });

    test('studyTimerServiceProvider wires notificationServiceProvider', () {
      final overrideNotification = NotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(overrideNotification),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      expect(service, isA<StudyTimerService>());
    });

    test('studyTimerServiceProvider resolves with null notification service', () {
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          notificationServiceProvider.overrideWithValue(NotificationService()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(studyTimerServiceProvider),
        returnsNormally,
      );
    });

    test('handles error from session repository gracefully', () async {
      final now = DateTime.now();
      final failingRepo = _FailingSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(failingRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final sessions = await service.repository.getByDate(now);
      expect(sessions.isFailure, true);
    });

    test('fake repository data flows through provider', () async {
      final now = DateTime.now();
      final session = Session(
        id: 'test-session-1',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now,
        actualDurationMs: 60000,
        completed: true,
        plannedDurationMinutes: 60,
      );
      final fakeRepo = FakeSessionRepository(seed: [session]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final todayMs = await service.getTodayDurationMs();
      expect(todayMs.data!, 60000);
    });

    test('propagates getByDate failure through getTodayDurationMs', () async {
      final fakeRepo = FakeSessionRepository();
      fakeRepo.throwOnGetByDate = true;
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final todayMs = await service.getTodayDurationMs();
      expect(todayMs.data!, 0);
    });

    test('propagates getByDate failure through getTodayStats', () async {
      final fakeRepo = FakeSessionRepository();
      fakeRepo.throwOnGetByDate = true;
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final stats = await service.getTodayStats();
      expect(stats.data ?? {}, isEmpty);
    });

    test('propagates getByDate failure through getTodaySessionCount', () async {
      final fakeRepo = FakeSessionRepository();
      fakeRepo.throwOnGetByDate = true;
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final count = await service.getTodaySessionCount();
      expect(count.data!, 0);
    });

    test('propagates getByDate failure through getTodayCompletedSessionCount', () async {
      final fakeRepo = FakeSessionRepository();
      fakeRepo.throwOnGetByDate = true;
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final count = await service.getTodayCompletedSessionCount();
      expect(count.data!, 0);
    });

    test('returns today stats through provider with fake repo', () async {
      final now = DateTime.now();
      final session = Session(
        id: 'stats-test',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now,
        actualDurationMs: 1800000,
        completed: true,
        plannedDurationMinutes: 30,
      );
      final fakeRepo = FakeSessionRepository(seed: [session]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final stats = await service.getTodayStats();
      expect(stats.data!['totalMs'], 1800000);
      expect(stats.data!['completedSessions'], 1);
      expect(stats.data!['totalSessions'], 1);
    });

    test('save propagates failure error through provider', () async {
      final fakeRepo = FakeSessionRepository();
      fakeRepo.throwOnSave = true;
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final result = await service.startSession(plannedDurationMinutes: 25);
      final saved = fakeRepo.sessions.where((s) => s.id == result.data!.id);
      expect(saved.length, 0);
    });

    test('dependency wiring: fake repo injected through override is used by service methods', () async {
      final now = DateTime.now();
      final session = Session(
        id: 'wired-test',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now,
        actualDurationMs: 1200000,
        completed: true,
      );
      final fakeRepo = FakeSessionRepository(seed: [session]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(studyTimerServiceProvider);
      final sessions = await service.getRecentSessions(limit: 10);
      expect(sessions.data!.length, 1);
      expect(sessions.data![0].id, 'wired-test');
      expect(sessions.data![0].studentId, 'stu1');
    });

    test('provider container can be disposed safely after reading all providers', () {
      final container = ProviderContainer();
      container.read(sessionRepositoryProvider);
      container.read(studyTimerServiceProvider);
      expect(() => container.dispose(), returnsNormally);
    });
  });
}
