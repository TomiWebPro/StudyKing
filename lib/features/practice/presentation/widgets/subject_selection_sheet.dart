import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';

class SubjectSelectionSheet extends StatelessWidget {
  final List<Subject> subjects;
  final void Function(Subject) onSubjectSelected;
  final String? Function(Subject)? subtitleBuilder;

  const SubjectSelectionSheet({
    super.key,
    required this.subjects,
    required this.onSubjectSelected,
    this.subtitleBuilder,
  });

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
            ...subjects.map((subject) {
              final subtitle = subtitleBuilder?.call(subject) ?? subject.code;
              return Semantics(
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
                  subtitle: subtitle != null ? Text(subtitle) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSubjectSelected(subject);
                  },
                ),
              );
            }),
            SizedBox(height: ResponsiveUtils.verticalSpacing(context) * 2),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context, {
    required List<Subject> subjects,
    required void Function(Subject) onSubjectSelected,
    String? Function(Subject)? subtitleBuilder,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: AppTheme.bottomSheetShape,
      builder: (_) => SubjectSelectionSheet(
        subjects: subjects,
        onSubjectSelected: onSubjectSelected,
        subtitleBuilder: subtitleBuilder,
      ),
    );
  }
}
