import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ProgressExportService {
  final StudyProgressTracker _tracker;
  final MasteryGraphService _masteryService;
  final AttemptRepository _attemptRepo;

  ProgressExportService({
    StudyProgressTracker? tracker,
    MasteryGraphService? masteryService,
    AttemptRepository? attemptRepo,
  })  : _tracker = tracker ??
            StudyProgressTracker(
              attemptRepo: AttemptRepository(),
              masteryService: MasteryGraphService(),
            ),
        _masteryService = masteryService ?? MasteryGraphService(),
        _attemptRepo = attemptRepo ?? AttemptRepository();

  Future<String> exportComprehensiveCSV(String studentId) async {
    final overallStats = await _tracker.getOverallStats(studentId);
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attempts = await _attemptRepo.getByStudent(studentId);
    final badges = await _tracker.getBadges(studentId);
    final trend = await _tracker.getWeeklyTrend(4, studentId: studentId);

    final buffer = StringBuffer();

    buffer.writeln('=== OVERALL STATS ===');
    buffer.writeln(
        'Total Attempts,Correct,Accuracy (%),Avg Time (s),Total Hours,Weekly Activity,Daily Activity,Topics Studied');
    buffer.writeln(
        '${overallStats['totalAttempts']},${overallStats['correctAttempts']},${overallStats['accuracy']},${overallStats['avgTimePerQuestion']},${overallStats['totalStudyTimeHours']},${overallStats['weeklyActivity']},${overallStats['dailyActivity']},${overallStats['topicsStudied']}');

    buffer.writeln();
    buffer.writeln('=== TOPIC MASTERY ===');
    buffer.writeln(
        'Topic ID,Total Attempts,Correct,Accuracy (%),Mastery Level,Last Practiced,Review Urgency');
    for (final ms in masteryStates) {
      final level = switch (ms.masteryLevel) {
        MasteryLevel.novice => 'Novice',
        MasteryLevel.browsing => 'Browsing',
        MasteryLevel.developing => 'Developing',
        MasteryLevel.proficient => 'Proficient',
        MasteryLevel.expert => 'Expert',
      };
      buffer.writeln(
          '${ms.topicId},${ms.totalAttempts},${ms.correctAttempts},${(ms.accuracy * 100).toStringAsFixed(1)}%,$level,${ms.lastAttempt.toIso8601String()},${(ms.reviewUrgency * 100).toStringAsFixed(0)}%');
    }

    buffer.writeln();
    buffer.writeln('=== ALL ATTEMPTS ===');
    buffer.writeln(
        'Question ID,Subject ID,Correct,Time (s),Timestamp');
    for (final a in attempts) {
      buffer.writeln(
          '${a.questionId},${a.subjectId},${a.isCorrect},${a.timeSpentMs ~/ 1000},${a.timestamp.toIso8601String()}');
    }

    buffer.writeln();
    buffer.writeln('=== WEEKLY TREND ===');
    buffer.writeln('Week,Attempts,Accuracy (%),Improvement');
    for (final t in trend) {
      buffer.writeln(
          '${t['week']}-W${t['month']},${t['attempts']},${t['accuracy']},${t['improvement']}');
    }

    buffer.writeln();
    buffer.writeln('=== BADGES ===');
    buffer.writeln('Badge Name,Description,Date Unlocked');
    for (final b in badges) {
      buffer.writeln(
          '"${b['name']}","${b['description']}","${b['unlockedAt']}"');
    }

    return buffer.toString();
  }

  Future<List<int>> exportComprehensivePDF(
    String studentId,
    AppLocalizations l10n,
  ) async {
    final overallStats = await _tracker.getOverallStats(studentId);
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attempts = await _attemptRepo.getByStudent(studentId);
    final badges = await _tracker.getBadges(studentId);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'StudyKing Progress Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Student ID: $studentId',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text('Overall Statistics'),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Attempts', '${overallStats['totalAttempts']}'],
              ['Correct Answers', '${overallStats['correctAttempts']}'],
              ['Accuracy', '${overallStats['accuracy']}%'],
              ['Avg Time Per Question', '${overallStats['avgTimePerQuestion']}s'],
              ['Total Study Time', '${overallStats['totalStudyTimeHours']} hours'],
              ['Weekly Activity', '${overallStats['weeklyActivity']} attempts'],
              ['Daily Activity', '${overallStats['dailyActivity']} attempts'],
              ['Topics Studied', '${overallStats['topicsStudied']}'],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text('Topic Mastery Breakdown'),
          ),
          pw.SizedBox(height: 8),
          if (masteryStates.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                'Topic',
                'Attempts',
                'Correct',
                'Accuracy',
                'Level',
                'Review Urgency',
              ],
              data: masteryStates.map((ms) {
                final level = switch (ms.masteryLevel) {
                  MasteryLevel.novice => 'Novice',
                  MasteryLevel.browsing => 'Browsing',
                  MasteryLevel.developing => 'Developing',
                  MasteryLevel.proficient => 'Proficient',
                  MasteryLevel.expert => 'Expert',
                };
                return [
                  ms.topicId,
                  '${ms.totalAttempts}',
                  '${ms.correctAttempts}',
                  '${(ms.accuracy * 100).toStringAsFixed(1)}%',
                  level,
                  '${(ms.reviewUrgency * 100).toStringAsFixed(0)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          if (masteryStates.isEmpty)
            pw.Text(
              'No mastery data available yet.',
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey500,
              ),
            ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text('Badges Earned'),
          ),
          pw.SizedBox(height: 8),
          if (badges.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Badge', 'Description', 'Unlocked'],
              data: badges.map((b) {
                return [
                  '${b['name']}',
                  '${b['description']}',
                  '${b['unlockedAt']}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          if (badges.isEmpty)
            pw.Text(
              'No badges earned yet. Keep studying!',
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey500,
              ),
            ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text('Recent Activity Summary'),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Total attempts recorded: ${attempts.length}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (attempts.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Date range: ${attempts.last.timestamp.toLocal().toString().split(' ')[0]} to ${attempts.first.timestamp.toLocal().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Correct: ${attempts.where((a) => a.isCorrect).length} / ${attempts.length}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> shareComprehensiveCSV(String studentId, String filename) async {
    final csv = await exportComprehensiveCSV(studentId);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'StudyKing Progress Report',
    );
  }

  Future<void> shareComprehensiveJSON(String studentId, String filename) async {
    final overallStats = await _tracker.getOverallStats(studentId);
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attempts = await _attemptRepo.getByStudent(studentId);
    final badges = await _tracker.getBadges(studentId);

    final json = jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'studentId': studentId,
      'overallStats': overallStats,
      'topicMastery': masteryStates.map((ms) => ms.toJson()).toList(),
      'attempts': attempts.map((a) => {
        'questionId': a.questionId,
        'subjectId': a.subjectId,
        'isCorrect': a.isCorrect,
        'timeSpentMs': a.timeSpentMs,
        'timestamp': a.timestamp.toIso8601String(),
      }).toList(),
      'badges': badges,
    });

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'StudyKing Progress Report',
    );
  }

  Future<void> shareComprehensivePDF(
    String studentId,
    String filename,
    AppLocalizations l10n,
  ) async {
    final pdfBytes = await exportComprehensivePDF(studentId, l10n);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'StudyKing Progress Report',
    );
  }
}
