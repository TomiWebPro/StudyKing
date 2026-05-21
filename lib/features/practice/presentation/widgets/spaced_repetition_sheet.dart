import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/color_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => SafeArea(
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
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: subjectsWithDue.map((subject) => Semantics(
                    label: '${l10n.selectSubject} ${subject.name}',
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ColorUtils.getSubjectColor(context, subject.name).withValues(alpha: 0.1),
                        child: Icon(
                          Icons.school,
                          color: ColorUtils.getSubjectColor(context, subject.name),
                        ),
                      ),
                      title: Text(subject.name),
                      subtitle: Text(l10n.dueQuestionsCount(dueCounts[subject.id] ?? 0)),
                      onTap: () {
                        Navigator.pop(context);
                        onSubjectSelected(subject);
                      },
                    ),
                  )).toList(),
                ),
              ),
              SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            ],
          ),
        ),
      ),
    );
  }

  static void showAllCaughtUp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppTheme.bottomSheetShape,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: ResponsiveUtils.screenPadding(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: ResponsiveUtils.emptyStateIconSize(sheetContext),
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(sheetContext) * 2),
                Text(
                  l10n.allCaughtUp,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(sheetContext)),
                Text(
                  l10n.noReviewsScheduled,
                  style: TextStyle(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(sheetContext) * 2),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(l10n.backToPractice),
                ),
                SizedBox(height: ResponsiveUtils.verticalSpacing(sheetContext)),
              ],
            ),
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
      isScrollControlled: true,
      shape: AppTheme.bottomSheetShape,
      builder: (_) => SpacedRepetitionSheet(
        subjectsWithDue: subjectsWithDue,
        dueCounts: dueCounts,
        onSubjectSelected: onSubjectSelected,
      ),
    );
  }
}
