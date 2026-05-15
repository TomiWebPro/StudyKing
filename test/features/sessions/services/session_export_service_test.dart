import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/services/session_export_service.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

Session _createExportSession({
  String id = 's1',
  String studentId = 'stu1',
  String? subjectId = 'Math',
  SessionType type = SessionType.practice,
  DateTime? startTime,
  int questionsAnswered = 10,
  int correctAnswers = 7,
  int actualDurationMs = 3600000,
  int? plannedDurationMinutes,
}) {
  final s = startTime ?? DateTime(2025, 1, 15, 10, 30);
  return Session(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    type: type,
    startTime: s,
    endTime: s.add(const Duration(minutes: 60)),
    actualDurationMs: actualDurationMs,
    questionsAnswered: questionsAnswered,
    correctAnswers: correctAnswers,
    plannedDurationMinutes: plannedDurationMinutes,
  );
}

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

      test('CSV-escapes quotes in fields', () {
        final session = _createExportSession(
          subjectId: 'Math "Advanced"',
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains('"Math ""Advanced"""'));
      });

      test('CSV-escapes newlines in fields', () {
        final session = _createExportSession(
          subjectId: 'Line1\nLine2',
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains('"Line1\nLine2"'));
      });

      test('rounds duration to 1 decimal place', () {
        final session = _createExportSession(
          actualDurationMs: 3661000,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        final rows = csv.split('\n');
        expect(rows[1], contains('61.0'));
      });

      test('includes empty planned duration when null', () {
        final session = _createExportSession(
          plannedDurationMinutes: null,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains(',,'));
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

      test('matches session.toJson() output', () {
        final session = createSession(start: startTime, end: endTime);
        final json = SessionExportService.sessionsToJSON([session]);
        expect(json[0], equals(session.toJson()));
      });
    });

    group('sessionsToPDF', () {
      final l10n = AppLocalizationsEn();

      test('produces non-empty bytes for non-empty session list', () async {
        final session = _createExportSession();
        final bytes = await SessionExportService.sessionsToPDF([session], l10n);
        expect(bytes, isNotEmpty);
      });

      test('produces non-empty bytes for empty session list', () async {
        final bytes = await SessionExportService.sessionsToPDF([], l10n);
        expect(bytes, isNotEmpty);
      });

      test('produces different bytes for different session lists', () async {
        final session = _createExportSession();
        final bytes1 = await SessionExportService.sessionsToPDF([session], l10n);
        final bytes2 = await SessionExportService.sessionsToPDF([], l10n);
        expect(bytes1, isNot(equals(bytes2)));
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

      test('writes CSV content matching sessionsToCSV output', () async {
        final dir = await Directory.systemTemp.createTemp('csv_match_');
        try {
          final session = _createExportSession();
          final csv = SessionExportService.sessionsToCSV([session]);
          final file = await SessionExportService.writeCSVFile(
            [session], 'test',
            directory: dir,
          );
          final written = await file.readAsString();
          expect(written, equals(csv));
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

      test('writes valid JSON matching sessionsToJSON output', () async {
        final dir = await Directory.systemTemp.createTemp('json_match_');
        try {
          final session = _createExportSession();
          final expectedJson = jsonEncode(
            SessionExportService.sessionsToJSON([session]),
          );
          final file = await SessionExportService.writeJSONFile(
            [session], 'test',
            directory: dir,
          );
          final written = await file.readAsString();
          expect(written, equals(expectedJson));
        } finally {
          await dir.delete(recursive: true);
        }
      });
    });

    group('writePDFFile', () {
      final l10n = AppLocalizationsEn();

      test('writes PDF file with correct extension', () async {
        final dir = await Directory.systemTemp.createTemp('pdf_test_');
        try {
          final session = _createExportSession();
          final file = await SessionExportService.writePDFFile(
            [session], 'test-export', l10n,
            directory: dir,
          );
          expect(file.path, endsWith('.pdf'));
          expect(file.existsSync(), isTrue);
        } finally {
          await dir.delete(recursive: true);
        }
      });

      test('writes non-empty PDF bytes', () async {
        final dir = await Directory.systemTemp.createTemp('pdf_bytes_');
        try {
          final session = _createExportSession();
          final file = await SessionExportService.writePDFFile(
            [session], 'test', l10n,
            directory: dir,
          );
          final bytes = await file.readAsBytes();
          expect(bytes, isNotEmpty);
        } finally {
          await dir.delete(recursive: true);
        }
      });
    });

  });
}
