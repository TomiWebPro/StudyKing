import 'package:flutter/material.dart';
import 'package:studyking/features/subjects/data/models/subject_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class SpacedRepetitionSheet extends StatelessWidget {
  final List<Subject> subjectsWithDue;
  final Map<String, int> dueCounts;
  final void Function(Subject) onSubjectSelected;

  const SpacedRepetitionSheet({
    super.key,
    required this.subjectsWithDue,
    required this.dueCounts,
    required this.onSubjectSelected,
  });

  Color _getSubjectColor(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.primary,
      cs.secondary,
    ];
    return colors[name.codeUnits.fold(0, (h, c) => h * 31 + c) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectSubject,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...subjectsWithDue.map((subject) => Semantics(
              label: '${l10n.selectSubject} ${subject.name}',
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSubjectColor(context, subject.name).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.school,
                    color: _getSubjectColor(context, subject.name),
                  ),
                ),
                title: Text(subject.name),
                subtitle: Text(l10n.dueQuestionsCount(dueCounts[subject.id] ?? 0)),
                onTap: () {
                  Navigator.pop(context);
                  onSubjectSelected(subject);
                },
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showAllCaughtUp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: ResponsiveUtils.screenPadding(sheetContext),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Theme.of(sheetContext).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.allCaughtUp,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noReviewsScheduled,
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> showSubjectPicker(BuildContext context, {
    required List<Subject> subjectsWithDue,
    required Map<String, int> dueCounts,
    required void Function(Subject) onSubjectSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SpacedRepetitionSheet(
        subjectsWithDue: subjectsWithDue,
        dueCounts: dueCounts,
        onSubjectSelected: onSubjectSelected,
      ),
    );
  }
}
