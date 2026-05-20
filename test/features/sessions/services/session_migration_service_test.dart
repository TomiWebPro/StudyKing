import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/data/adapters/session_adapter.dart';
import 'package:studyking/features/sessions/services/session_migration_service.dart';

Map<String, dynamic> createFocusSessionJson({
  String id = 'focus-1',
  String studentId = 'student-1',
  String? subjectId = 'subject-1',
  String? topicId = 'topic-1',
  String startTime = '2025-01-15T10:00:00',
  String? endTime = '2025-01-15T10:25:00',
  int actualDurationSeconds = 1500,
  int plannedDurationMinutes = 25,
  bool completed = true,
  String? createdAt,
}) {
  return {
    'id': id,
    'studentId': studentId,
    'subjectId': subjectId,
    'topicId': topicId,
    'startTime': startTime,
    'endTime': endTime,
    'actualDurationSeconds': actualDurationSeconds,
    'plannedDurationMinutes': plannedDurationMinutes,
    'completed': completed,
    if (createdAt != null) 'createdAt': createdAt,
  };
}

void main() {
  group('SessionMigrationService', () {
    late String hivePath;

    setUp(() async {
      hivePath = (await Directory.systemTemp.createTemp('migration_test_')).path;
      Hive.init(hivePath);
      if (!Hive.isAdapterRegistered(36)) {
        Hive.registerAdapter(SessionAdapter());
      }
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('full migration lifecycle', () async {
      await Hive.openBox<String>(HiveBoxNames.focusSessions);
      await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

      final focusBox = Hive.box<String>(HiveBoxNames.focusSessions);
      final sessionsBox = Hive.box<Session>(HiveBoxNames.sessionsTyped);

      focusBox.put('s1', jsonEncode(createFocusSessionJson(
        id: 'f1', studentId: 'stu-1', subjectId: 'sub-1',
        topicId: 'topic-1', startTime: '2025-01-15T10:00:00',
        endTime: '2025-01-15T10:45:00', actualDurationSeconds: 2700,
        plannedDurationMinutes: 45, completed: true,
      )));
      focusBox.put('corrupt', 'not-json');

      sessionsBox.put('f2', Session(
        id: 'f2',
        studentId: 'existing',
        startTime: DateTime(2025, 1, 15),
        type: SessionType.focus,
      ));
      focusBox.put('dup', jsonEncode(createFocusSessionJson(id: 'f2')));

      focusBox.put('s3', jsonEncode(createFocusSessionJson(
        id: 'f3', endTime: null, actualDurationSeconds: 0, completed: false,
      )));

      await SessionMigrationService.migrateIfNeeded();

      expect(sessionsBox.containsKey('f1'), isTrue);
      expect(sessionsBox.containsKey('f3'), isTrue);
      expect(sessionsBox.containsKey('f2'), isTrue);
      expect(sessionsBox.length, 3);

      final migrated = sessionsBox.get('f1')!;
      expect(migrated.id, 'f1');
      expect(migrated.studentId, 'stu-1');
      expect(migrated.subjectId, 'sub-1');
      expect(migrated.topicId, 'topic-1');
      expect(migrated.type, SessionType.focus);
      expect(migrated.startTime, DateTime(2025, 1, 15, 10, 0, 0));
      expect(migrated.endTime, DateTime(2025, 1, 15, 10, 45, 0));
      expect(migrated.actualDurationMs, 2700000);
      expect(migrated.plannedDurationMinutes, 45);
      expect(migrated.completed, isTrue);

      final migratedIncomplete = sessionsBox.get('f3')!;
      expect(migratedIncomplete.actualDurationMs, 0);
      expect(migratedIncomplete.completed, isFalse);
      expect(migratedIncomplete.endTime, isNull);

      await SessionMigrationService.migrateIfNeeded();
      expect(sessionsBox.length, 3);
    });

    test('completes without error when focus_sessions box does not exist', () async {
      await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);
      await expectLater(
        SessionMigrationService.migrateIfNeeded(),
        completes,
      );
    });

    test('skips migration gracefully when focus_sessions is empty', () async {
      await Hive.openBox<String>(HiveBoxNames.focusSessions);
      await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

      await SessionMigrationService.migrateIfNeeded();

      final sessionsBox = Hive.box<Session>(HiveBoxNames.sessionsTyped);
      expect(sessionsBox.isEmpty, isTrue);
    });

    test('handles corrupt JSON entry gracefully', () async {
      await Hive.openBox<String>(HiveBoxNames.focusSessions);
      await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

      final focusBox = Hive.box<String>(HiveBoxNames.focusSessions);
      focusBox.put('corrupt', 'not-valid-json-at-all{{{');

      await SessionMigrationService.migrateIfNeeded();

      final sessionsBox = Hive.box<Session>(HiveBoxNames.sessionsTyped);
      expect(sessionsBox.isEmpty, isTrue);
    });

    test('handles missing required fields in JSON gracefully', () async {
      await Hive.openBox<String>(HiveBoxNames.focusSessions);
      await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

      final focusBox = Hive.box<String>(HiveBoxNames.focusSessions);
      focusBox.put('partial', jsonEncode({
        'id': 'partial-1',
        'studentId': 'stu-1',
      }));

      await SessionMigrationService.migrateIfNeeded();

      final sessionsBox = Hive.box<Session>(HiveBoxNames.sessionsTyped);
      expect(sessionsBox.length, 1);
      final migrated = sessionsBox.get('partial-1')!;
      expect(migrated.id, 'partial-1');
    });

    test('handles results from second call gracefully (idempotent)', () async {
      await Hive.openBox<String>(HiveBoxNames.focusSessions);
      await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

      final focusBox = Hive.box<String>(HiveBoxNames.focusSessions);
      focusBox.put('s1', jsonEncode(createFocusSessionJson(id: 'f1')));

      await SessionMigrationService.migrateIfNeeded();
      await SessionMigrationService.migrateIfNeeded();

      final sessionsBox = Hive.box<Session>(HiveBoxNames.sessionsTyped);
      expect(sessionsBox.length, 1);
    });

    group('error-state: result return values', () {
      test('migrateIfNeeded returns success on clean migration', () async {
        await Hive.openBox<String>(HiveBoxNames.focusSessions);
        await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

        final focusBox = Hive.box<String>(HiveBoxNames.focusSessions);
        focusBox.put('s1', jsonEncode(createFocusSessionJson(id: 'ok-1')));

        final result = await SessionMigrationService.migrateIfNeeded();
        expect(result.isSuccess, isTrue);
      });

      test('migrateIfNeeded returns success for empty focus box', () async {
        await Hive.openBox<String>(HiveBoxNames.focusSessions);
        await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

        final result = await SessionMigrationService.migrateIfNeeded();
        expect(result.isSuccess, isTrue);
      });

      test('migrateIfNeeded is idempotent at Result level', () async {
        await Hive.openBox<String>(HiveBoxNames.focusSessions);
        await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);

        final result1 = await SessionMigrationService.migrateIfNeeded();
        final result2 = await SessionMigrationService.migrateIfNeeded();

        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
      });

      test('migrateIfNeeded returns failure when Hive throws', () async {
        // Do NOT open boxes - Hive will throw when trying to access them
        await Hive.openBox<Session>(HiveBoxNames.sessionsTyped);
        // focus_sessions box not opened -> Hive.box will throw

        final result = await SessionMigrationService.migrateIfNeeded();
        expect(result.isFailure, isTrue);
      });
    });
  });
}
