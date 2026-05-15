import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/services/session_export_service.dart';

void main() {
  group('SessionExportService', () {
    final startTime = DateTime(2025, 1, 15, 10, 0, 0);
    final endTime = DateTime(2025, 1, 15, 10, 45, 0);

    Session createSession({
      String id = 'session-1',
      String studentId = 'student-1',
      String? subjectId = 'subject-1',
      SessionType type = SessionType.tutoring,
      required DateTime start,
      DateTime? end,
      int plannedDurationMinutes = 45,
      int questionsAnswered = 0,
      int correctAnswers = 0,
    }) {
      return Session(
        id: id,
        studentId: studentId,
        subjectId: subjectId,
        type: type,
        startTime: start,
        endTime: end,
        plannedDurationMinutes: plannedDurationMinutes,
        questionsAnswered: questionsAnswered,
        correctAnswers: correctAnswers,
      );
    }

    group('sessionsToCSV', () {
      test('returns CSV header when sessions is empty', () {
        final csv = SessionExportService.sessionsToCSV([]);
        expect(csv, contains('Session ID'));
        expect(csv, contains('Student ID'));
        expect(csv, contains('Subject'));
      });

      test('includes session data in CSV', () {
        final sessions = [
          createSession(start: startTime, end: endTime, questionsAnswered: 10, correctAnswers: 8),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains('session-1'));
        expect(csv, contains('student-1'));
        expect(csv, contains('subject-1'));
        expect(csv, contains(startTime.toIso8601String()));
        expect(csv, contains(endTime.toIso8601String()));
      });

      test('handles optional fields being null', () {
        final sessions = [
          createSession(start: startTime, subjectId: null),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains('session-1'));
      });

      test('includes multiple sessions', () {
        final sessions = [
          createSession(id: 's1', start: startTime),
          createSession(id: 's2', start: startTime.add(const Duration(hours: 1))),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains('s1'));
        expect(csv, contains('s2'));
      });

      test('calculates accuracy correctly', () {
        final sessions = [
          createSession(start: startTime, questionsAnswered: 10, correctAnswers: 7),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains('70.0'));
      });

      test('shows 0.0 accuracy when no questions answered', () {
        final sessions = [
          createSession(start: startTime),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains('0.0'));
      });

      test('escapes commas in values', () {
        final sessions = [
          Session(
            id: 's1',
            studentId: 'student,1',
            type: SessionType.tutoring,
            startTime: startTime,
          ),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains('"student,1"'));
      });

      test('handles empty sessionId gracefully', () {
        final sessions = [
          Session(
            id: '',
            studentId: 'student-1',
            type: SessionType.tutoring,
            startTime: startTime,
          ),
        ];
        final csv = SessionExportService.sessionsToCSV(sessions);
        expect(csv, contains(''));
      });
    });

    group('sessionsToJSON', () {
      test('returns empty list when sessions is empty', () {
        final json = SessionExportService.sessionsToJSON([]);
        expect(json, isEmpty);
      });

      test('returns list of JSON maps', () {
        final sessions = [
          createSession(start: startTime, end: endTime),
        ];
        final json = SessionExportService.sessionsToJSON(sessions);
        expect(json.length, 1);
        expect(json.first['id'], 'session-1');
        expect(json.first['studentId'], 'student-1');
      });

      test('preserves all session fields', () {
        final sessions = [
          createSession(
            start: startTime,
            end: endTime,
            questionsAnswered: 10,
            correctAnswers: 8,
          ),
        ];
        final json = SessionExportService.sessionsToJSON(sessions);
        expect(json.first['questionsAnswered'], 10);
        expect(json.first['correctAnswers'], 8);
      });
    });

    group('writeCSVFile', () {
      test('writes CSV file to specified directory', () async {
        final dir = await Directory.systemTemp.createTemp('csv_test_');
        try {
          final sessions = [
            createSession(start: startTime, end: endTime),
          ];
          final file = await SessionExportService.writeCSVFile(
            sessions, 'test_export',
            directory: dir,
          );
          expect(file.existsSync(), isTrue);
          expect(file.path, contains('test_export.csv'));
          final content = await file.readAsString();
          expect(content, contains('session-1'));
        } finally {
          await dir.delete(recursive: true);
        }
      });

      test('writes CSV with empty sessions', () async {
        final dir = await Directory.systemTemp.createTemp('csv_empty_test_');
        try {
          final file = await SessionExportService.writeCSVFile([], 'empty_export', directory: dir);
          expect(file.existsSync(), isTrue);
          final content = await file.readAsString();
          expect(content, contains('Session ID'));
        } finally {
          await dir.delete(recursive: true);
        }
      });
    });

    group('writeJSONFile', () {
      test('writes JSON file to specified directory', () async {
        final dir = await Directory.systemTemp.createTemp('json_test_');
        try {
          final sessions = [
            createSession(start: startTime, end: endTime),
          ];
          final file = await SessionExportService.writeJSONFile(
            sessions, 'test_export',
            directory: dir,
          );
          expect(file.existsSync(), isTrue);
          expect(file.path, contains('test_export.json'));
          final content = jsonDecode(await file.readAsString()) as List;
          expect(content.length, 1);
          expect(content.first['id'], 'session-1');
        } finally {
          await dir.delete(recursive: true);
        }
      });

      test('writes JSON with empty sessions', () async {
        final dir = await Directory.systemTemp.createTemp('json_empty_test_');
        try {
          final file = await SessionExportService.writeJSONFile([], 'empty_export', directory: dir);
          expect(file.existsSync(), isTrue);
          final content = jsonDecode(await file.readAsString()) as List;
          expect(content, isEmpty);
        } finally {
          await dir.delete(recursive: true);
        }
      });
    });

  });
}
