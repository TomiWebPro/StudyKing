import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/progress_export_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/dashboard/providers/dashboard_providers.dart';
import 'package:studyking/core/utils/logger.dart';
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
    final exportService = ref.watch(dashboardExportServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.exportComprehensiveReport,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _exportPDF(context, exportService, studentId),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(l10n.exportComprehensiveReport),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _exportCSV(context, exportService, studentId),
              icon: const Icon(Icons.table_chart, size: 18),
              label: Text(l10n.exportCsv),
            ),
            TextButton.icon(
              onPressed: () => _exportPDF(context, exportService, studentId),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: Text(l10n.exportPdf),
            ),
            TextButton.icon(
              onPressed: () => _exportJSON(context, exportService, studentId),
              icon: const Icon(Icons.code, size: 18),
              label: Text(l10n.labelJson),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _exportProgressCSV(context, tracker, studentId),
              icon: Icon(Icons.download, size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              label: Text(
                l10n.exportProgressCsv,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.sessionHistory),
              icon: Icon(Icons.history, size: 16,
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
                  _exportInstrumentation(context, instrumentation, studentId),
              icon: Icon(Icons.analytics, size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              label: Text(
                l10n.instrumentation,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.settings),
              icon: Icon(Icons.backup, size: 16,
                  color: Theme.of(context).colorScheme.primary),
              label: Text(
                l10n.exportBackup,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.backupRestoreHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<bool> _showExportConfirmation(BuildContext context, String title, String description, String details) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                details,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.exportBackup),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _exportCSV(BuildContext context, ProgressExportService exportService, String studentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showExportConfirmation(
      context,
      l10n.exportCsv,
      l10n.comprehensiveReportExported,
      l10n.exportCsvDetail,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final csv = await exportService.exportComprehensiveCSV(studentId, l10n: l10n);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(utf8.encode(csv)), name: 'studyking_full_report_${DateTime.now().millisecondsSinceEpoch}.csv', mimeType: 'text/csv')],
        text: l10n.comprehensiveReportExported,
      );
    } catch (e) {
      if (!context.mounted) return;
      const Logger('ExportSection').e('CSV export failed', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(l10n.somethingWentWrong))),
      );
    }
  }

  Future<void> _exportPDF(BuildContext context, ProgressExportService exportService, String studentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showExportConfirmation(
      context,
      l10n.exportPdf,
      l10n.comprehensiveReportExported,
      l10n.exportPdfDetail,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final pdfBytes = await exportService.exportComprehensivePDF(studentId, l10n);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(pdfBytes), name: 'studyking_full_report_${DateTime.now().millisecondsSinceEpoch}.pdf', mimeType: 'application/pdf')],
        text: l10n.comprehensiveReportExported,
      );
    } catch (e) {
      if (!context.mounted) return;
      const Logger('ExportSection').e('PDF export failed', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(l10n.somethingWentWrong))),
      );
    }
  }

  Future<void> _exportJSON(BuildContext context, ProgressExportService exportService, String studentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showExportConfirmation(
      context,
      l10n.labelJson,
      l10n.comprehensiveReportExported,
      l10n.exportJsonDetail,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final jsonStr = await exportService.exportComprehensiveJSON(studentId, l10n);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(utf8.encode(jsonStr)), name: 'studyking_full_report_${DateTime.now().millisecondsSinceEpoch}.json', mimeType: 'application/json')],
        text: l10n.comprehensiveReportExported,
      );
    } catch (e) {
      if (!context.mounted) return;
      const Logger('ExportSection').e('JSON export failed', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(l10n.somethingWentWrong))),
      );
    }
  }

  Future<void> _exportProgressCSV(
      BuildContext context, StudyProgressTracker tracker, String studentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showExportConfirmation(
      context,
      l10n.exportProgressCsv,
      l10n.shareProgressReport,
      l10n.exportProgressCsvDetail,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final csv = await tracker.exportProgressCSV(studentId);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(utf8.encode(csv)), name: 'studyking_progress_${DateTime.now().millisecondsSinceEpoch}.csv', mimeType: 'text/csv')],
        text: l10n.shareProgressReport,
      );
    } catch (e) {
      if (!context.mounted) return;
      const Logger('ExportSection').e('Progress CSV export failed', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(l10n.somethingWentWrong))),
      );
    }
  }

  Future<void> _exportInstrumentation(
      BuildContext context, InstrumentationService instrumentation, String studentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showExportConfirmation(
      context,
      l10n.instrumentation,
      l10n.shareInstrumentationData,
      l10n.exportInstrumentationDetail,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final result = await instrumentation.getInstrumentationDashboard(studentId);
      if (result.isFailure) {
        if (!context.mounted) return;
        const Logger('ExportSection').e('Instrumentation fetch failed', result.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(l10n.somethingWentWrong))),
        );
        return;
      }
      final data = result.data!;
      final jsonString = formatInstrumentation(data, l10n);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(utf8.encode(jsonString)), name: 'studyking_instrumentation_${DateTime.now().millisecondsSinceEpoch}.json', mimeType: 'application/json')],
        text: l10n.shareInstrumentationData,
      );
    } catch (e) {
      if (!context.mounted) return;
      const Logger('ExportSection').e('Instrumentation export failed', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(l10n.somethingWentWrong))),
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
