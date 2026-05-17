import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class WeakAreasSheet extends StatelessWidget {
  final List<Subject> subjects;
  final void Function(Subject) onSubjectSelected;

  const WeakAreasSheet({
    super.key,
    required this.subjects,
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
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
            ...subjects.map((subject) => Semantics(
              label: '${l10n.selectSubject} ${subject.name}',
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSubjectColor(context, subject.name).withValues(alpha: 0.1),
                  child: Icon(Icons.school, color: _getSubjectColor(context, subject.name)),
                ),
                title: Text(subject.name),
                onTap: () {
                  Navigator.pop(context);
                  onSubjectSelected(subject);
                },
              ),
            )),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, {
    required List<Subject> subjects,
    required void Function(Subject) onSubjectSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: AppTheme.bottomSheetShape,
      builder: (_) => WeakAreasSheet(
        subjects: subjects,
        onSubjectSelected: onSubjectSelected,
      ),
    );
  }
}
