import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    });

    tearDown(() async {
      await Hive.close();
      if (hivePath.isNotEmpty) {
        await Directory(hivePath).delete(recursive: true);
      }
    });

    test('full migration lifecycle', () async {
      await Hive.openBox<String>('focus_sessions');
      await Hive.openBox<String>('sessions');

      final focusBox = Hive.box<String>('focus_sessions');
      final sessionsBox = Hive.box<String>('sessions');

      focusBox.put('s1', jsonEncode(createFocusSessionJson(
        id: 'f1', studentId: 'stu-1', subjectId: 'sub-1',
        topicId: 'topic-1', startTime: '2025-01-15T10:00:00',
        endTime: '2025-01-15T10:45:00', actualDurationSeconds: 2700,
        plannedDurationMinutes: 45, completed: true,
      )));
      focusBox.put('corrupt', 'not-json');

      sessionsBox.put('focus_f2', jsonEncode(createFocusSessionJson(id: 'f2')));
      focusBox.put('dup', jsonEncode(createFocusSessionJson(id: 'f2')));

      focusBox.put('s3', jsonEncode(createFocusSessionJson(
        id: 'f3', endTime: null, actualDurationSeconds: 0, completed: false,
      )));

      await SessionMigrationService.migrateIfNeeded();

      expect(sessionsBox.containsKey('focus_f1'), isTrue);
      expect(sessionsBox.containsKey('focus_f3'), isTrue);
      expect(sessionsBox.containsKey('focus_f2'), isTrue);
      expect(sessionsBox.length, 3);

      final decoded = jsonDecode(sessionsBox.get('focus_f1')!) as Map<String, dynamic>;
      expect(decoded['id'], 'f1');
      expect(decoded['studentId'], 'stu-1');
      expect(decoded['subjectId'], 'sub-1');
      expect(decoded['topicId'], 'topic-1');
      expect(decoded['type'], 'focus');
      expect(decoded['startTime'], DateTime(2025, 1, 15, 10, 0, 0).toIso8601String());
      expect(decoded['endTime'], DateTime(2025, 1, 15, 10, 45, 0).toIso8601String());
      expect(decoded['actualDurationMs'], 2700000);
      expect(decoded['plannedDurationMinutes'], 45);
      expect(decoded['completed'], isTrue);

      await SessionMigrationService.migrateIfNeeded();
      expect(sessionsBox.length, 3);
    });

    test('completes without error when focus_sessions box does not exist', () async {
      await Hive.openBox<String>('sessions');
      await expectLater(
        SessionMigrationService.migrateIfNeeded(),
        completes,
      );
    });

    test('skips migration when focus_sessions is empty', () async {
      await Hive.openBox<String>('focus_sessions');
      await Hive.openBox<String>('sessions');

      await SessionMigrationService.migrateIfNeeded();

      final sessionsBox = Hive.box<String>('sessions');
      expect(sessionsBox.isEmpty, isTrue);
    });
  });
}
