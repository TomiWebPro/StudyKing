import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
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

  Future<String> exportComprehensiveCSV(String studentId, AppLocalizations l10n) async {
    final overallStats = await _tracker.getOverallStats(studentId);
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attempts = await _attemptRepo.getByStudent(studentId);
    final badges = await _tracker.getBadges(studentId);
    final trend = await _tracker.getWeeklyTrend(4, studentId: studentId);

    final buffer = StringBuffer();

    buffer.writeln('=== ${l10n.csvOverallStats} ===');
    buffer.writeln(
        '${l10n.csvColTotalAttempts},${l10n.csvColCorrect},${l10n.csvColAccuracy},${l10n.csvColAvgTime},${l10n.csvColTotalHours},${l10n.csvColWeeklyActivity},${l10n.csvColDailyActivity},${l10n.csvColTopicsStudied}');
    buffer.writeln(
        '${overallStats['totalAttempts']},${overallStats['correctAttempts']},${overallStats['accuracy']},${overallStats['avgTimePerQuestion']},${overallStats['totalStudyTimeHours']},${overallStats['weeklyActivity']},${overallStats['dailyActivity']},${overallStats['topicsStudied']}');

    buffer.writeln();
    buffer.writeln('=== ${l10n.csvTopicMastery} ===');
    buffer.writeln(
        '${l10n.csvColTopicId},${l10n.csvColTotalAttempts},${l10n.csvColCorrect},${l10n.csvColAccuracy},${l10n.csvColMasteryLevel},${l10n.csvColLastPracticed},${l10n.csvColReviewUrgency}');
    for (final ms in masteryStates) {
      final level = switch (ms.masteryLevel) {
        MasteryLevel.novice => l10n.masteryLevelNovice,
        MasteryLevel.browsing => l10n.masteryLevelBrowsing,
        MasteryLevel.developing => l10n.masteryLevelDeveloping,
        MasteryLevel.proficient => l10n.masteryLevelProficient,
        MasteryLevel.expert => l10n.masteryLevelExpert,
      };
      buffer.writeln(
          '${ms.topicId},${ms.totalAttempts},${ms.correctAttempts},${(ms.accuracy * 100).toStringAsFixed(1)}%,$level,${ms.lastAttempt.toIso8601String()},${(ms.reviewUrgency * 100).toStringAsFixed(0)}%');
    }

    buffer.writeln();
    buffer.writeln('=== ${l10n.csvAllAttempts} ===');
    buffer.writeln(
        '${l10n.csvColQuestionId},${l10n.csvColSubjectId},${l10n.csvColCorrect},${l10n.csvColTime},${l10n.csvColTimestamp}');
    for (final a in attempts) {
      buffer.writeln(
          '${a.questionId},${a.subjectId},${a.isCorrect},${a.timeSpentMs ~/ 1000},${a.timestamp.toIso8601String()}');
    }

    buffer.writeln();
    buffer.writeln('=== ${l10n.csvWeeklyTrend} ===');
    buffer.writeln(
        '${l10n.csvColWeek},${l10n.csvColAttempts},${l10n.csvColAccuracy},${l10n.csvColImprovement}');
    for (final t in trend) {
      buffer.writeln(
          '${t['week']}-W${t['month']},${t['attempts']},${t['accuracy']},${t['improvement']}');
    }

    buffer.writeln();
    buffer.writeln('=== ${l10n.csvBadges} ===');
    buffer.writeln(
        '${l10n.csvColBadgeName},${l10n.csvColBadgeDescription},${l10n.csvColDateUnlocked}');
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
              l10n.pdfProgressReport,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.pdfGenerated(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.pdfStudentId(studentId),
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text(l10n.pdfOverallStatistics),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [l10n.pdfMetric, l10n.pdfValue],
            data: [
              [l10n.csvColTotalAttempts, '${overallStats['totalAttempts']}'],
              [l10n.correctAnswers, '${overallStats['correctAttempts']}'],
              [l10n.accuracy, '${overallStats['accuracy']}%'],
              [l10n.avgTime, '${overallStats['avgTimePerQuestion']}s'],
              [l10n.totalStudyTime, '${overallStats['totalStudyTimeHours']}h'],
              [l10n.csvColWeeklyActivity, '${overallStats['weeklyActivity']}'],
              [l10n.csvColDailyActivity, '${overallStats['dailyActivity']}'],
              [l10n.csvColTopicsStudied, '${overallStats['topicsStudied']}'],
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
            child: pw.Text(l10n.pdfTopicMasteryBreakdown),
          ),
          pw.SizedBox(height: 8),
          if (masteryStates.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.pdfTableTopic,
                l10n.pdfTableAttempts,
                l10n.csvColCorrect,
                l10n.accuracy,
                l10n.pdfTableLevel,
                l10n.csvColReviewUrgency,
              ],
              data: masteryStates.map((ms) {
                final level = switch (ms.masteryLevel) {
                  MasteryLevel.novice => l10n.masteryLevelNovice,
                  MasteryLevel.browsing => l10n.masteryLevelBrowsing,
                  MasteryLevel.developing => l10n.masteryLevelDeveloping,
                  MasteryLevel.proficient => l10n.masteryLevelProficient,
                  MasteryLevel.expert => l10n.masteryLevelExpert,
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
              l10n.pdfNoMasteryData,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey500,
              ),
            ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text(l10n.pdfBadgesEarned),
          ),
          pw.SizedBox(height: 8),
          if (badges.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.csvColBadgeName,
                l10n.csvColBadgeDescription,
                l10n.csvColDateUnlocked,
              ],
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
              l10n.pdfNoBadges,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey500,
              ),
            ),
          pw.SizedBox(height: 24),

          pw.Header(
            level: 1,
            child: pw.Text(l10n.pdfRecentActivitySummary),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.pdfTotalAttemptsRecorded(attempts.length),
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (attempts.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              l10n.pdfDateRange(
                attempts.last.timestamp.toLocal().toString().split(' ')[0],
                attempts.first.timestamp.toLocal().toString().split(' ')[0],
              ),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              l10n.pdfCorrectFraction(
                attempts.where((a) => a.isCorrect).length,
                attempts.length,
              ),
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> shareComprehensiveCSV(
    String studentId,
    String filename,
    AppLocalizations l10n,
  ) async {
    final csv = await exportComprehensiveCSV(studentId, l10n);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: l10n.pdfProgressReport,
    );
  }

  Future<void> shareComprehensiveJSON(
    String studentId,
    String filename,
    AppLocalizations l10n,
  ) async {
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
      text: l10n.pdfProgressReport,
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
      text: l10n.pdfProgressReport,
    );
  }
}
