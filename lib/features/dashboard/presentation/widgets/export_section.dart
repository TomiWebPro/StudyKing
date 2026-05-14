import 'package:flutter/material.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ExportSection extends StatelessWidget {
  final String studentId;
  final StudyProgressTracker tracker;
  final InstrumentationService instrumentation;

  const ExportSection({
    super.key,
    required this.studentId,
    required this.tracker,
    required this.instrumentation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _exportProgressCSV(context),
                  icon: const Icon(Icons.download),
                  label: Text(l10n.exportCsv),
                ),
                TextButton.icon(
                  onPressed: () => _exportSessionHistoryCSV(context),
                  icon: const Icon(Icons.history),
                  label: Text(l10n.sessionHistory),
                ),
                TextButton.icon(
                  onPressed: () => _exportInstrumentation(context),
                  icon: const Icon(Icons.analytics),
                  label: Text(l10n.instrumentation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProgressCSV(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await tracker.exportProgressCSV(studentId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.progressCsvGenerated(csv.length))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportSessionHistoryCSV(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await tracker.exportSessionHistoryCSV(studentId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sessionHistoryCsvGenerated(csv.length))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportInstrumentation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await instrumentation.exportInstrumentationData(studentId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.instrumentationDataExported)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }
}
