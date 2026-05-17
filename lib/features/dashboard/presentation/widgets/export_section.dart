import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ExportSection extends ConsumerWidget {
  final String studentId;

  const ExportSection({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(dashboardStudyProgressTrackerProvider);
    final instrumentation = ref.watch(dashboardInstrumentationServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exportComprehensiveReport,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _exportCSV(context),
              icon: const Icon(Icons.table_chart, size: 18),
              label: Text(l10n.exportCsv),
            ),
            TextButton.icon(
              onPressed: () => _exportPDF(context),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: Text(l10n.exportPdf),
            ),
            TextButton.icon(
              onPressed: () => _exportJSON(context),
              icon: const Icon(Icons.code, size: 18),
              label: Text(l10n.labelJson),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _exportProgressCSV(context, tracker),
              icon: Icon(Icons.download, size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              label: Text(
                l10n.sessionHistory,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () =>
                  _exportInstrumentation(context, instrumentation),
              icon: Icon(Icons.analytics, size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              label: Text(
                l10n.instrumentation,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = ProgressExportService();
      final csv = await service.exportComprehensiveCSV(studentId);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/studyking_full_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.comprehensiveReportExported,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportPDF(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = ProgressExportService();
      final pdfBytes = await service.exportComprehensivePDF(studentId, l10n);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/studyking_full_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.comprehensiveReportExported,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportJSON(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = ProgressExportService();
      final jsonStr = await service.exportComprehensiveJSON(studentId, l10n);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/studyking_full_report_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.comprehensiveReportExported,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportProgressCSV(
      BuildContext context, StudyProgressTracker tracker) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await tracker.exportProgressCSV(studentId);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/studyking_progress_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.shareProgressReport,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportInstrumentation(
      BuildContext context, InstrumentationService instrumentation) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await instrumentation.getInstrumentationDashboard(studentId);
      if (result.isFailure) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(result.error!))),
        );
        return;
      }
      final data = result.data!;
      final jsonString = formatInstrumentation(data, l10n);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/studyking_instrumentation_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.shareInstrumentationData,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  @visibleForTesting
  String formatInstrumentation(
      Map<String, dynamic> data, AppLocalizations l10n) {
    final buffer = StringBuffer();
    buffer.writeln(l10n.instrumentationDashboard);
    buffer.writeln(l10n.instrumentationGenerated(data['generatedAt'] ?? ''));
    buffer.writeln();

    final adherence = data['planAdherence'] as Map<String, dynamic>? ?? {};
    buffer.writeln(l10n.instrumentationPlanAdherence);
    adherence.forEach((k, v) => buffer.writeln('$k: $v'));
    buffer.writeln();

    final mastery = data['masteryImprovement'] as Map<String, dynamic>? ?? {};
    buffer.writeln(l10n.instrumentationMasteryImprovement);
    mastery.forEach((k, v) => buffer.writeln('$k: $v'));

    return buffer.toString();
  }
}
