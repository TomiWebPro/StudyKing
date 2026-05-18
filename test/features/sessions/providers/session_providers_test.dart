import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/sessions/providers/session_providers.dart';

class _FakeSessionRepository extends SessionRepository {
  final List<Session> sessions;
  bool throwOnGetAll = false;
  bool throwOnGetTodayStats = false;

  _FakeSessionRepository({List<Session>? seed}) : sessions = List.from(seed ?? []);

  @override
  Future<Result<List<Session>>> getAll() async {
    if (throwOnGetAll) return Result.failure('getAll failed');
    final sorted = List<Session>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return Result.success(sorted);
  }

  @override
  Future<Result<Map<String, dynamic>>> getTodayStats() async {
    if (throwOnGetTodayStats) return Result.failure('getTodayStats failed');
    final now = DateTime.now();
    final todayResult = await getByDate(now);
    if (todayResult.isFailure) return Result.failure(todayResult.error);
    final todaySessions = todayResult.data!;
    final totalMs = todaySessions.fold<int>(0, (sum, s) => sum + s.actualDurationMs);
    final completed = todaySessions.where((s) => s.completed).length;
    final plannedMinutes = todaySessions.fold<int>(0, (sum, s) =>
        sum + (s.plannedDurationMinutes ?? 0));
    return Result.success({
      'totalMs': totalMs,
      'totalSeconds': totalMs ~/ 1000,
      'completedSessions': completed,
      'totalSessions': todaySessions.length,
      'plannedMinutes': plannedMinutes,
    });
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
  Future<Result<Session?>> get(String id) async {
    return Result.success(sessions.where((s) => s.id == id).firstOrNull);
  }

  @override
  @override
  Future<Result<void>> save(String key, Session session) async {
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

void main() {
  group('sessionRepositoryProvider', () {
    test('creates a SessionRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, isA<SessionRepository>());
    });

    test('returns the same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(sessionRepositoryProvider);
      final repo2 = container.read(sessionRepositoryProvider);
      expect(repo1, same(repo2));
    });

    test('can be overridden with a fake', () {
      final fakeRepo = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, same(fakeRepo));
    });

    test('can be overridden with a real SessionRepository', () {
      final overrideRepo = SessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(overrideRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, same(overrideRepo));
    });

    test('resolves without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(sessionRepositoryProvider),
        returnsNormally,
      );
    });

    test('container can be disposed safely after reading', () {
      final container = ProviderContainer();
      container.read(sessionRepositoryProvider);
      expect(() => container.dispose(), returnsNormally);
    });

    test('override propagates to downstream consumers', () {
      final fakeRepo = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(sessionRepositoryProvider);
      expect(repo, same(fakeRepo));
      final session = Session(
        id: 'test-1',
        studentId: 's1',
        type: SessionType.focus,
        startTime: DateTime.now(),
      );
      repo.save(session.id, session);
    });
  });

  group('allSessionsProvider', () {
    test('returns sessions from repository', () async {
      final session = Session(
        id: 's1',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: DateTime.now(),
        actualDurationMs: 1000,
      );
      final fakeRepo = _FakeSessionRepository(seed: [session]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(allSessionsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data![0].id, 's1');
    });

    test('returns empty list when no sessions exist', () async {
      final fakeRepo = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(allSessionsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!.isEmpty, true);
    });

    test('returns multiple sessions sorted by startTime descending', () async {
      final now = DateTime.now();
      final session1 = Session(
        id: 's1',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final session2 = Session(
        id: 's2',
        studentId: 'stu1',
        type: SessionType.practice,
        startTime: now.subtract(const Duration(hours: 1)),
      );
      final fakeRepo = _FakeSessionRepository(seed: [session1, session2]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(allSessionsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
      expect(result.data![0].id, 's2');
      expect(result.data![1].id, 's1');
    });

    test('resolves without throwing', () {
      final fakeRepo = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(allSessionsProvider),
        returnsNormally,
      );
    });

    test('dependency wiring: fake repo injected through override is used', () async {
      final fakeRepo = _FakeSessionRepository(seed: [
        Session(
          id: 'wired-1',
          studentId: 'stu1',
          type: SessionType.focus,
          startTime: DateTime.now(),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(allSessionsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data![0].id, 'wired-1');
      expect(result.data![0].studentId, 'stu1');
    });
  });

  group('todayStatsProvider', () {
    test('returns today stats from repository', () async {
      final now = DateTime.now();
      final session = Session(
        id: 's1',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now,
        actualDurationMs: 3600000,
        completed: true,
        plannedDurationMinutes: 60,
      );
      final fakeRepo = _FakeSessionRepository(seed: [session]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(todayStatsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!['totalMs'], 3600000);
      expect(result.data!['totalSeconds'], 3600);
      expect(result.data!['completedSessions'], 1);
      expect(result.data!['totalSessions'], 1);
      expect(result.data!['plannedMinutes'], 60);
    });

    test('returns zero stats when no sessions today', () async {
      final fakeRepo = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(todayStatsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!['totalSessions'], 0);
      expect(result.data!['completedSessions'], 0);
      expect(result.data!['totalMs'], 0);
    });

    test('aggregates multiple sessions correctly', () async {
      final now = DateTime.now();
      final session1 = Session(
        id: 's1',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now.subtract(const Duration(hours: 3)),
        actualDurationMs: 1800000,
        completed: true,
        plannedDurationMinutes: 30,
      );
      final session2 = Session(
        id: 's2',
        studentId: 'stu1',
        type: SessionType.practice,
        startTime: now.subtract(const Duration(hours: 1)),
        actualDurationMs: 900000,
        completed: true,
        plannedDurationMinutes: 15,
      );
      final session3 = Session(
        id: 's3',
        studentId: 'stu1',
        type: SessionType.focus,
        startTime: now.subtract(const Duration(days: 1)),
        actualDurationMs: 3600000,
      );
      final fakeRepo = _FakeSessionRepository(seed: [session1, session2, session3]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(todayStatsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!['totalSessions'], 2);
      expect(result.data!['completedSessions'], 2);
      expect(result.data!['totalMs'], 2700000);
      expect(result.data!['totalSeconds'], 2700);
      expect(result.data!['plannedMinutes'], 45);
    });

    test('resolves without throwing', () {
      final fakeRepo = _FakeSessionRepository();
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(todayStatsProvider),
        returnsNormally,
      );
    });

    test('dependency wiring: fake repo injected through override is used', () async {
      final now = DateTime.now();
      final fakeRepo = _FakeSessionRepository(seed: [
        Session(
          id: 'stats-wired',
          studentId: 'stu1',
          type: SessionType.focus,
          startTime: now,
          actualDurationMs: 60000,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(todayStatsProvider.future);
      expect(result.isSuccess, true);
      expect(result.data!['totalSessions'], 1);
      expect(result.data!['totalMs'], 60000);
    });
  });
}
