import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/features/sessions/services/session_export_service.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

Session _createSession({
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
    group('sessionsToCSV', () {
      test('produces correct header row', () {
        final csv = SessionExportService.sessionsToCSV([]);
        expect(csv, startsWith(
          'Session ID,Student ID,Subject,Type,Start Time,End Time,'
          'Duration (min),Planned Duration (min),Questions Answered,Correct,Accuracy (%)',
        ));
      });

      test('produces correct data row', () {
        final session = _createSession(
          id: 's1',
          studentId: 'stu1',
          subjectId: 'Math',
          startTime: DateTime(2025, 6, 15, 10, 0, 0),
          questionsAnswered: 10,
          correctAnswers: 7,
          actualDurationMs: 3600000,
          plannedDurationMinutes: 60,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        final rows = csv.split('\n').where((r) => r.isNotEmpty).toList();
        expect(rows, hasLength(2));
        expect(rows[1], contains('s1'));
        expect(rows[1], contains('stu1'));
        expect(rows[1], contains('Math'));
        expect(rows[1], contains('practice'));
        expect(rows[1], contains('60'));
        expect(rows[1], contains('10'));
        expect(rows[1], contains('7'));
        expect(rows[1], contains('70.0'));
        expect(rows[1], contains('60.0'));
      });

      test('includes empty planned duration when null', () {
        final session = _createSession(
          plannedDurationMinutes: null,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains(',,'));
      });

      test('CSV-escapes commas in fields', () {
        final session = _createSession(
          subjectId: 'Biology, Chemistry',
          questionsAnswered: 5,
          correctAnswers: 3,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains('"Biology, Chemistry"'));
      });

      test('CSV-escapes quotes in fields', () {
        final session = _createSession(
          subjectId: 'Math "Advanced"',
          questionsAnswered: 5,
          correctAnswers: 3,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains('"Math ""Advanced"""'));
      });

      test('CSV-escapes newlines in fields', () {
        final session = _createSession(
          subjectId: 'Line1\nLine2',
          questionsAnswered: 5,
          correctAnswers: 3,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        expect(csv, contains('"Line1\nLine2"'));
      });

      test('formats accuracy as 0.0 when questionsAnswered == 0', () {
        final session = _createSession(
          questionsAnswered: 0,
          correctAnswers: 0,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        final rows = csv.split('\n');
        expect(rows[1], contains(',0.0'));
      });

      test('rounds duration to 1 decimal place', () {
        final session = _createSession(
          actualDurationMs: 3661000,
        );
        final csv = SessionExportService.sessionsToCSV([session]);
        final rows = csv.split('\n');
        expect(rows[1], contains('61.0'));
      });

      test('handles empty session list', () {
        final csv = SessionExportService.sessionsToCSV([]);
        final rows = csv.split('\n').where((r) => r.isNotEmpty).toList();
        expect(rows, hasLength(1));
        expect(rows[0], contains('Session ID'));
      });
    });

    group('sessionsToJSON', () {
      test('returns correct List<Map<String, dynamic>> matching toJson()', () {
        final session = _createSession();
        final json = SessionExportService.sessionsToJSON([session]);
        expect(json, hasLength(1));
        expect(json[0]['id'], 's1');
        expect(json[0]['studentId'], 'stu1');
        expect(json[0]['subjectId'], 'Math');
        expect(json[0]['type'], 'practice');
        expect(json[0]['questionsAnswered'], 10);
        expect(json[0]['correctAnswers'], 7);
        expect(json[0]['actualDurationMs'], 3600000);
      });

      test('handles empty list', () {
        final json = SessionExportService.sessionsToJSON([]);
        expect(json, isEmpty);
      });

      test('matches session.toJson() output', () {
        final session = _createSession();
        final json = SessionExportService.sessionsToJSON([session]);
        expect(json[0], equals(session.toJson()));
      });
    });

    group('sessionsToPDF', () {
      final l10n = AppLocalizationsEn();

      test('produces non-empty bytes for non-empty session list', () async {
        final session = _createSession();
        final bytes = await SessionExportService.sessionsToPDF([session], l10n);
        expect(bytes, isNotEmpty);
      });

      test('produces non-empty bytes for empty session list', () async {
        final bytes = await SessionExportService.sessionsToPDF([], l10n);
        expect(bytes, isNotEmpty);
      });

      test('produces different bytes for different session lists', () async {
        final session = _createSession();
        final bytes1 = await SessionExportService.sessionsToPDF([session], l10n);
        final bytes2 = await SessionExportService.sessionsToPDF([], l10n);
        expect(bytes1, isNot(equals(bytes2)));
      });
    });

    group('writeCSVFile', () {
      late Directory tmpDir;

      setUp(() {
        tmpDir = Directory.systemTemp.createTempSync('export_csv_');
      });

      tearDown(() {
        tmpDir.deleteSync(recursive: true);
      });

      test('writes CSV file with correct extension', () async {
        final session = _createSession();
        final file = await SessionExportService.writeCSVFile(
          [session],
          'test-export',
          directory: tmpDir,
        );
        addTearDown(() => file.deleteSync());

        expect(file.path, endsWith('.csv'));
        expect(file.existsSync(), isTrue);
      });

      test('writes CSV content matching sessionsToCSV output', () async {
        final session = _createSession();
        final csv = SessionExportService.sessionsToCSV([session]);
        final file = await SessionExportService.writeCSVFile(
          [session],
          'test',
          directory: tmpDir,
        );
        addTearDown(() => file.deleteSync());

        final written = await file.readAsString();
        expect(written, equals(csv));
      });
    });

    group('writeJSONFile', () {
      late Directory tmpDir;

      setUp(() {
        tmpDir = Directory.systemTemp.createTempSync('export_json_');
      });

      tearDown(() {
        tmpDir.deleteSync(recursive: true);
      });

      test('writes JSON file with correct extension', () async {
        final session = _createSession();
        final file = await SessionExportService.writeJSONFile(
          [session],
          'test-export',
          directory: tmpDir,
        );
        addTearDown(() => file.deleteSync());

        expect(file.path, endsWith('.json'));
        expect(file.existsSync(), isTrue);
      });

      test('writes valid JSON matching sessionsToJSON output', () async {
        final session = _createSession();
        final expectedJson = jsonEncode(
          SessionExportService.sessionsToJSON([session]),
        );
        final file = await SessionExportService.writeJSONFile(
          [session],
          'test',
          directory: tmpDir,
        );
        addTearDown(() => file.deleteSync());

        final written = await file.readAsString();
        expect(written, equals(expectedJson));
      });
    });

    group('writePDFFile', () {
      late Directory tmpDir;
      final l10n = AppLocalizationsEn();

      setUp(() {
        tmpDir = Directory.systemTemp.createTempSync('export_pdf_');
      });

      tearDown(() {
        tmpDir.deleteSync(recursive: true);
      });

      test('writes PDF file with correct extension', () async {
        final session = _createSession();
        final file = await SessionExportService.writePDFFile(
          [session],
          'test-export',
          l10n,
          directory: tmpDir,
        );
        addTearDown(() => file.deleteSync());

        expect(file.path, endsWith('.pdf'));
        expect(file.existsSync(), isTrue);
      });

      test('writes non-empty PDF bytes', () async {
        final session = _createSession();
        final file = await SessionExportService.writePDFFile(
          [session],
          'test',
          l10n,
          directory: tmpDir,
        );
        addTearDown(() => file.deleteSync());

        final bytes = await file.readAsBytes();
        expect(bytes, isNotEmpty);
      });
    });
  });
}
