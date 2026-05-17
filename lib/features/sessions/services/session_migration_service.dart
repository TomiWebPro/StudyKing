import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/utils/logger.dart';

class SessionMigrationService {
  static final Logger _logger = const Logger('SessionMigrationService');
  static bool _migrated = false;

  static Future<void> migrateIfNeeded() async {
    if (_migrated) return;

    try {
      await _migrateFocusSessions();
      _migrated = true;
      _logger.i('Session migration completed successfully');
    } catch (e) {
      _logger.e('Session migration failed', e);
    }
  }

  static Future<void> _migrateFocusSessions() async {
    if (!Hive.isBoxOpen(HiveBoxNames.focusSessions)) return;

    final focusBox = Hive.box<String>(HiveBoxNames.focusSessions);
    if (focusBox.isEmpty) return;

    final sessionsBox = Hive.box<Session>(HiveBoxNames.sessionsTyped);
    int migrated = 0;
    int skipped = 0;

    for (final entry in focusBox.toMap().entries) {
      try {
        final json = jsonDecode(entry.value) as Map<String, dynamic>;
        final session = _convertFocusSession(json);

        if (sessionsBox.containsKey(session.id)) {
          skipped++;
          continue;
        }

        sessionsBox.put(session.id, session);
        migrated++;
      } catch (e) {
        _logger.e('Error migrating focus session ${entry.key}', e);
      }
    }

    _logger.i('Migrated $migrated focus sessions, skipped $skipped');
  }

  static Session _convertFocusSession(Map<String, dynamic> json) {
    final startTime = DateTime.parse(json['startTime']);
    final endTime = json['endTime'] != null
        ? DateTime.parse(json['endTime'])
        : null;
    final actualSeconds = json['actualDurationSeconds'] ?? 0;
    final plannedMinutes = json['plannedDurationMinutes'] ?? 25;

    return Session(
      id: json['id'],
      studentId: json['studentId'] ?? '',
      subjectId: json['subjectId'],
      topicId: json['topicId'],
      type: SessionType.focus,
      startTime: startTime,
      endTime: endTime,
      plannedDurationMinutes: plannedMinutes,
      actualDurationMs: (actualSeconds as int) * 1000,
      completed: json['completed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : startTime,
    );
  }
}
