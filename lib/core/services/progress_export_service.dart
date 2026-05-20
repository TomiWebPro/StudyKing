import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/utils/date_utils.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/core/utils/study_utils.dart';
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
    required StudyProgressTracker tracker,
    required MasteryGraphService masteryService,
    required AttemptRepository attemptRepo,
  })  : _tracker = tracker,
        _masteryService = masteryService,
        _attemptRepo = attemptRepo;

  Future<String> exportComprehensiveJSON(String studentId, AppLocalizations l10n) async {
    final overallStatsResult = await _tracker.getOverallStats(studentId);
    final overallStats = overallStatsResult.data ?? <String, dynamic>{};
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];
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
    return json;
  }

  Future<String> exportComprehensiveCSV(
    String studentId, {
    AppLocalizations? l10n,
  }) async {
    final overallStatsResult = await _tracker.getOverallStats(studentId);
    final overallStats = overallStatsResult.data ?? <String, dynamic>{};
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];
    final badgesResult = await _tracker.getBadges(studentId);
    final badges = badgesResult.data ?? [];
    final trendResult = await _tracker.getWeeklyTrend(4, studentId: studentId);
    final trend = trendResult.data ?? [];

    final buffer = StringBuffer();

    buffer.writeln('=== Overall Statistics ===');
    buffer.writeln(
        'Total Attempts,Correct,Accuracy (%),Avg Time (s),Total Hours,Weekly Activity,Daily Activity,Topics Studied');
    buffer.writeln(
        '${overallStats['totalAttempts']},${overallStats['correctAttempts']},${overallStats['accuracy']},${overallStats['avgTimePerQuestion']},${(overallStats['totalStudyTimeHours'] as num).toStringAsFixed(1)},${overallStats['weeklyActivity']},${overallStats['dailyActivity']},${overallStats['topicsStudied']}');

    buffer.writeln();
    buffer.writeln('=== Topic Mastery ===');
    buffer.writeln(
        'Topic ID,Total Attempts,Correct,Accuracy (%),Mastery Level,Last Practiced,Review Urgency (%)');
    for (final ms in masteryStates) {
      final level = _masteryLevelLabel(ms.masteryLevel, l10n);
      buffer.writeln(
          '${ms.topicId},${ms.totalAttempts},${ms.correctAttempts},${(ms.accuracy * 100).toStringAsFixed(1)}%,$level,${ms.lastAttempt.toIso8601String()},${(ms.reviewUrgency * 100).toStringAsFixed(0)}%');
    }

    buffer.writeln();
    buffer.writeln('=== All Attempts ===');
    buffer.writeln(
        'Question ID,Subject ID,Correct,Time (s),Timestamp');
    for (final a in attempts) {
      buffer.writeln(
          '${a.questionId},${a.subjectId},${a.isCorrect},${a.timeSpentMs ~/ msPerSecond},${a.timestamp.toIso8601String()}');
    }

    buffer.writeln();
    buffer.writeln('=== Weekly Trend ===');
    buffer.writeln(
        'Week,Attempts,Accuracy (%),Improvement (%)');
    for (final t in trend) {
      buffer.writeln(
          '${t['week']}-W${t['month']},${t['attempts']},${t['accuracy']},${t['improvement']}');
    }

    buffer.writeln();
    buffer.writeln('=== Badges ===');
    buffer.writeln(
        'Badge Name,Description,Date Unlocked');
    for (final b in badges) {
      buffer.writeln(
          '"${b['name']}","${b['description']}","${b['unlockedAt']}"');
    }

    return buffer.toString();
  }

  String _masteryLevelLabel(MasteryLevel level, AppLocalizations? l10n) {
    return switch (level) {
      MasteryLevel.novice => l10n?.masteryLevelNovice ?? 'Novice',
      MasteryLevel.browsing => l10n?.masteryLevelBrowsing ?? 'Browsing',
      MasteryLevel.developing => l10n?.masteryLevelDeveloping ?? 'Developing',
      MasteryLevel.proficient => l10n?.masteryLevelProficient ?? 'Proficient',
      MasteryLevel.expert => l10n?.masteryLevelExpert ?? 'Expert',
    };
  }

  Future<List<int>> exportComprehensivePDF(
    String studentId,
    AppLocalizations l10n,
  ) async {
    final overallStatsResult = await _tracker.getOverallStats(studentId);
    final overallStats = overallStatsResult.data ?? <String, dynamic>{};
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];
    final badgesResult = await _tracker.getBadges(studentId);
    final badges = badgesResult.data ?? [];

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
            l10n.pdfGenerated(localizedDateTime(DateTime.now(), l10n.localeName)),
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
              [l10n.accuracy, formatPercent(double.tryParse('${overallStats['accuracy']}') ?? 0, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0)],
              [l10n.avgTime, '${overallStats['avgTimePerQuestion']}s'],
              [l10n.totalStudyTime, '${formatDecimal(double.tryParse(overallStats['totalStudyTimeHours'] as String? ?? '0') ?? 0, l10n.localeName, minFractionDigits: 1, maxFractionDigits: 1)}h'],
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
                  formatPercent(ms.accuracy * 100, l10n.localeName, minFractionDigits: 1, maxFractionDigits: 1),
                  level,
                  formatPercent(ms.reviewUrgency * 100, l10n.localeName, minFractionDigits: 0, maxFractionDigits: 0),
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
                DateFormat.yMd(l10n.localeName).format(attempts.last.timestamp.toLocal()),
                DateFormat.yMd(l10n.localeName).format(attempts.first.timestamp.toLocal()),
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
    final csv = await exportComprehensiveCSV(studentId, l10n: l10n);
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(utf8.encode(csv)), name: '$filename.csv', mimeType: 'text/csv')],
      text: l10n.pdfProgressReport,
    );
  }

  Future<void> shareComprehensiveJSON(
    String studentId,
    String filename,
    AppLocalizations l10n,
  ) async {
    final overallStatsResult = await _tracker.getOverallStats(studentId);
    final overallStats = overallStatsResult.data ?? <String, dynamic>{};
    final masteryResult = await _masteryService.getAllTopicMastery(studentId);
    final masteryStates =
        masteryResult.isSuccess ? masteryResult.data! : <MasteryState>[];
    final attemptsResult = await _attemptRepo.getByStudent(studentId);
    final attempts = attemptsResult.data ?? [];
    final badgesResult = await _tracker.getBadges(studentId);
    final badges = badgesResult.data ?? [];

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

    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(utf8.encode(json)), name: '$filename.json', mimeType: 'application/json')],
      text: l10n.pdfProgressReport,
    );
  }

  Future<void> shareComprehensivePDF(
    String studentId,
    String filename,
    AppLocalizations l10n,
  ) async {
    final pdfBytes = await exportComprehensivePDF(studentId, l10n);
    await Share.shareXFiles(
      [XFile.fromData(Uint8List.fromList(pdfBytes), name: '$filename.pdf', mimeType: 'application/pdf')],
      text: l10n.pdfProgressReport,
    );
  }
}
