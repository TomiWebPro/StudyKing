import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/models/study_session_model.dart';
import '../../../l10n/generated/app_localizations.dart';

class SessionExportService {
  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String sessionsToCSV(List<StudySession> sessions) {
    final buffer = StringBuffer();
    buffer.writeln('Session ID,Student ID,Subject,Start Time,End Time,'
        'Duration (min),Questions Answered,Correct,Accuracy (%)');

    for (final s in sessions) {
      final startStr = s.startTime.toIso8601String();
      final endStr = s.endTime?.toIso8601String() ?? '';
      final durationMin = (s.timeSpentMs / 60000).toStringAsFixed(1);
      final accuracy = s.questionsAnswered > 0
          ? ((s.correctAnswers / s.questionsAnswered) * 100).toStringAsFixed(1)
          : '0.0';

      buffer.writeln(
        '${_csvEscape(s.id)},'
        '${_csvEscape(s.studentId)},'
        '${_csvEscape(s.subjectId)},'
        '$startStr,'
        '$endStr,'
        '$durationMin,'
        '${s.questionsAnswered},'
        '${s.correctAnswers},'
        '$accuracy',
      );
    }

    return buffer.toString();
  }

  static List<Map<String, dynamic>> sessionsToJSON(
      List<StudySession> sessions) {
    return sessions.map((s) => s.toJson()).toList();
  }

  static Future<List<int>> sessionsToPDF(
    List<StudySession> sessions,
    AppLocalizations l10n,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              l10n.sessionHistoryExport,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${l10n.total}: ${sessions.length}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${l10n.totalTime}: ${_formatTotalDuration(sessions)}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          if (sessions.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['#', l10n.subjects, l10n.date, l10n.duration,
                  l10n.correct, l10n.accuracy],
              data: sessions.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final s = entry.value;
                final date =
                    '${s.startTime.day}/${s.startTime.month}/${s.startTime.year}';
                final dur = _formatDuration(s.timeSpentMs);
                final accuracy = s.questionsAnswered > 0
                    ? '${((s.correctAnswers / s.questionsAnswered) * 100).toStringAsFixed(1)}%'
                    : '-';
                return [
                  '$i',
                  s.subjectId,
                  date,
                  dur,
                  '${s.correctAnswers}/${s.questionsAnswered}',
                  accuracy,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
          if (sessions.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 40),
                child: pw.Text(
                  l10n.noSessionsYet,
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _formatTotalDuration(List<StudySession> sessions) {
    final totalMs = sessions.fold<int>(0, (sum, s) => sum + s.timeSpentMs);
    final minutes = totalMs ~/ 60000;
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${remainingMin}m';
    }
    return '${remainingMin}m';
  }

  static String _formatDuration(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @visibleForTesting
  static Future<File> writeCSVFile(
    List<StudySession> sessions,
    String filename, {
    Directory? directory,
  }) async {
    final csv = sessionsToCSV(sessions);
    final dir = directory ?? await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.csv');
    await file.writeAsString(csv);
    return file;
  }

  @visibleForTesting
  static Future<File> writeJSONFile(
    List<StudySession> sessions,
    String filename, {
    Directory? directory,
  }) async {
    final json = jsonEncode(sessionsToJSON(sessions));
    final dir = directory ?? await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.json');
    await file.writeAsString(json);
    return file;
  }

  @visibleForTesting
  static Future<File> writePDFFile(
    List<StudySession> sessions,
    String filename,
    AppLocalizations l10n, {
    Directory? directory,
  }) async {
    final pdfBytes = await sessionsToPDF(sessions, l10n);
    final dir = directory ?? await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<void> shareCSV(
    List<StudySession> sessions,
    String filename,
  ) async {
    final file = await writeCSVFile(sessions, filename);
    await Share.shareXFiles([XFile(file.path)], text: 'Study Sessions');
  }

  static Future<void> shareJSON(
    List<StudySession> sessions,
    String filename,
  ) async {
    final file = await writeJSONFile(sessions, filename);
    await Share.shareXFiles([XFile(file.path)], text: 'Study Sessions');
  }

  static Future<void> sharePDF(
    List<StudySession> sessions,
    String filename,
    AppLocalizations l10n,
  ) async {
    final file = await writePDFFile(sessions, filename, l10n);
    await Share.shareXFiles([XFile(file.path)], text: 'Study Sessions');
  }
}
