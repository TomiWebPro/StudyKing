import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/focus_mode/data/models/focus_session_model.dart';
import 'package:studyking/features/focus_mode/data/repositories/focus_session_repository.dart';

void main() {
  late FocusSessionRepository repository;
  late DateTime now;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox<String>('focus_sessions');

    now = DateTime(2026, 5, 14, 10, 30);
    repository = FocusSessionRepository();
    await repository.init();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('focus_sessions')) {
      await Hive.deleteBoxFromDisk('focus_sessions');
    }
  });

  FocusSession createSession({
    String id = 's1',
    int plannedMinutes = 25,
    int actualSeconds = 0,
    bool completed = false,
    DateTime? startTime,
  }) {
    return FocusSession(
      id: id,
      startTime: startTime ?? now,
      endTime: completed ? (startTime ?? now).add(const Duration(minutes: 25)) : null,
      plannedDurationMinutes: plannedMinutes,
      actualDurationSeconds: actualSeconds,
      completed: completed,
    );
  }

  group('FocusSessionRepository', () {
    group('init', () {
      test('initializes successfully', () async {
        final repo = FocusSessionRepository();
        await repo.init();
        // No exception means success
      });

      test('can be called multiple times without error', () async {
        await repository.init();
        await repository.init();
        // No exception means success
      });
    });

    group('save and get', () {
      test('saves and retrieves a session', () async {
        final session = createSession();
        await repository.save(session);

        final retrieved = await repository.get('s1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 's1');
        expect(retrieved.plannedDurationMinutes, 25);
      });

      test('get returns null for non-existent session', () async {
        final retrieved = await repository.get('non-existent');
        expect(retrieved, isNull);
      });
    });

    group('getAll', () {
      test('returns empty list when no sessions', () async {
        final sessions = await repository.getAll();
        expect(sessions, isEmpty);
      });

      test('returns all saved sessions sorted by startTime desc', () async {
        final earlier = createSession(
          id: 's1',
          startTime: DateTime(2026, 5, 14, 8, 0),
        );
        final later = createSession(
          id: 's2',
          startTime: DateTime(2026, 5, 14, 10, 0),
        );
        await repository.save(earlier);
        await repository.save(later);

        final sessions = await repository.getAll();

        expect(sessions.length, 2);
        expect(sessions[0].id, 's2');
        expect(sessions[1].id, 's1');
      });
    });

    group('getByDate', () {
      test('returns sessions for given date', () async {
        final session = createSession(startTime: now);
        await repository.save(session);

        final result = await repository.getByDate(now);

        expect(result.length, 1);
        expect(result[0].id, 's1');
      });

      test('returns empty list for date with no sessions', () async {
        final result = await repository.getByDate(
          DateTime(2025, 1, 1),
        );
        expect(result, isEmpty);
      });

      test('excludes sessions on different date', () async {
        final yesterday = now.subtract(const Duration(days: 1));
        final session = createSession(
          id: 's1',
          startTime: yesterday,
        );
        await repository.save(session);

        final todaySessions = await repository.getByDate(now);
        expect(todaySessions, isEmpty);
      });
    });

    group('getActive', () {
      test('returns only active sessions', () async {
        final active = createSession(id: 'active-1');
        final completed = createSession(
          id: 'completed-1',
          completed: true,
        );
        await repository.save(active);
        await repository.save(completed);

        final result = await repository.getActive();

        expect(result.length, 1);
        expect(result[0].id, 'active-1');
      });

      test('returns empty list when no active sessions', () async {
        final completed = createSession(
          id: 'completed-1',
          completed: true,
        );
        await repository.save(completed);

        final result = await repository.getActive();
        expect(result, isEmpty);
      });
    });

    group('update', () {
      test('updates an existing session', () async {
        final session = createSession();
        await repository.save(session);

        final updated = createSession(
          id: 's1',
          plannedMinutes: 45,
          actualSeconds: 2700,
          completed: true,
        );
        await repository.update('s1', updated);

        final retrieved = await repository.get('s1');
        expect(retrieved!.plannedDurationMinutes, 45);
        expect(retrieved.actualDurationSeconds, 2700);
      });
    });

    group('delete', () {
      test('deletes a session', () async {
        final session = createSession();
        await repository.save(session);
        await repository.delete('s1');

        final retrieved = await repository.get('s1');
        expect(retrieved, isNull);
      });

      test('delete on non-existent id does not throw', () async {
        await repository.delete('non-existent');
        // No exception means success
      });
    });

    group('clearAll', () {
      test('clears all sessions', () async {
        await repository.save(createSession(id: 's1'));
        await repository.save(createSession(id: 's2'));
        await repository.clearAll();

        final sessions = await repository.getAll();
        expect(sessions, isEmpty);
      });
    });

    group('corrupted data handling', () {
      test('get returns null for corrupted session data', () async {
        final box = Hive.box<String>('focus_sessions');
        await box.put('corrupted', 'not valid json');

        final result = await repository.get('corrupted');
        expect(result, isNull);
      });

      test('getAll skips corrupted entries', () async {
        final box = Hive.box<String>('focus_sessions');
        await repository.save(createSession(id: 'valid-1'));
        await box.put('corrupted', 'not valid json');
        await repository.save(createSession(id: 'valid-2'));

        final result = await repository.getAll();
        expect(result.length, 2);
        expect(result.any((s) => s.id == 'corrupted'), isFalse);
      });

      test('getAll returns empty when all entries are corrupted', () async {
        final box = Hive.box<String>('focus_sessions');
        await box.put('bad-1', '{invalid json');
        await box.put('bad-2', '{{{');

        final result = await repository.getAll();
        expect(result, isEmpty);
      });
    });

    group('getByDate edge cases', () {
      test('includes session at start of day (midnight)', () async {
        final midnight = DateTime(2026, 5, 14, 0, 0, 0, 0);
        final session = createSession(
          id: 'midnight-session',
          startTime: midnight,
        );
        await repository.save(session);

        final result = await repository.getByDate(
          DateTime(2026, 5, 14),
        );
        expect(result.length, 1);
        expect(result[0].id, 'midnight-session');
      });

      test('excludes session at start of next day', () async {
        final nextMidnight = DateTime(2026, 5, 15, 0, 0, 0, 0);
        final session = createSession(
          id: 'next-day',
          startTime: nextMidnight,
        );
        await repository.save(session);

        final result = await repository.getByDate(
          DateTime(2026, 5, 14),
        );
        expect(result, isEmpty);
      });

      test('includes session just before midnight of next day', () async {
        final justBeforeMidnight = DateTime(2026, 5, 14, 23, 59, 59, 999);
        final session = createSession(
          id: 'end-of-day',
          startTime: justBeforeMidnight,
        );
        await repository.save(session);

        final result = await repository.getByDate(
          DateTime(2026, 5, 14),
        );
        expect(result.length, 1);
      });

      test('returns multiple sessions for same date sorted correctly', () async {
        final morning = createSession(
          id: 'morning',
          startTime: DateTime(2026, 5, 14, 8, 0),
        );
        final evening = createSession(
          id: 'evening',
          startTime: DateTime(2026, 5, 14, 20, 0),
        );
        final afternoon = createSession(
          id: 'afternoon',
          startTime: DateTime(2026, 5, 14, 14, 0),
        );
        await repository.save(morning);
        await repository.save(evening);
        await repository.save(afternoon);

        final result = await repository.getByDate(
          DateTime(2026, 5, 14),
        );
        expect(result.length, 3);
        expect(result[0].id, 'evening');
        expect(result[1].id, 'afternoon');
        expect(result[2].id, 'morning');
      });
    });

    group('save overwrite', () {
      test('save overwrites existing session with same id', () async {
        final original = createSession(
          plannedMinutes: 25,
          actualSeconds: 0,
        );
        await repository.save(original);

        final overwrite = createSession(
          plannedMinutes: 50,
          actualSeconds: 3000,
          completed: true,
        );
        await repository.save(overwrite);

        final retrieved = await repository.get('s1');
        expect(retrieved!.plannedDurationMinutes, 50);
        expect(retrieved.actualDurationSeconds, 3000);
        expect(retrieved.completed, true);
      });
    });

    group('update on non-existent', () {
      test('update creates session when id does not exist', () async {
        final session = createSession(id: 'new-session');
        await repository.update('new-session', session);

        final retrieved = await repository.get('new-session');
        expect(retrieved, isNotNull);
        expect(retrieved!.plannedDurationMinutes, 25);
      });
    });
  });
}
