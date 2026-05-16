import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => _exportProgressCSV(context, tracker),
              icon: const Icon(Icons.download),
              label: Text(l10n.exportCsv),
            ),
            TextButton.icon(
              onPressed: () => _exportSessionHistoryCSV(context, tracker),
              icon: const Icon(Icons.history),
              label: Text(l10n.sessionHistory),
            ),
            TextButton.icon(
              onPressed: () => _exportInstrumentation(context, instrumentation),
              icon: const Icon(Icons.analytics),
              label: Text(l10n.instrumentation),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportProgressCSV(BuildContext context, StudyProgressTracker tracker) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await tracker.exportProgressCSV(studentId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/studyking_progress_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'StudyKing Progress Report',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportSessionHistoryCSV(BuildContext context, StudyProgressTracker tracker) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await tracker.exportSessionHistoryCSV(studentId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/studyking_sessions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'StudyKing Session History',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportInstrumentation(BuildContext context, InstrumentationService instrumentation) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await instrumentation.getInstrumentationDashboard(studentId);
      if (result.isFailure) throw Exception(result.error);
      final data = result.data!;
      final jsonString = formatInstrumentation(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/studyking_instrumentation_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'StudyKing Instrumentation Data',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }

  @visibleForTesting
  String formatInstrumentation(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('=== Instrumentation Dashboard ===');
    buffer.writeln('Generated: ${data['generatedAt']}');
    buffer.writeln();

    final adherence = data['planAdherence'] as Map<String, dynamic>? ?? {};
    buffer.writeln('--- Plan Adherence ---');
    adherence.forEach((k, v) => buffer.writeln('$k: $v'));
    buffer.writeln();

    final mastery = data['masteryImprovement'] as Map<String, dynamic>? ?? {};
    buffer.writeln('--- Mastery Improvement ---');
    mastery.forEach((k, v) => buffer.writeln('$k: $v'));

    return buffer.toString();
  }
}
