import 'package:flutter/material.dart';
import 'package:studyking/features/subjects/data/models/subject_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/practice/presentation/widgets/practice_mode_option.dart';

class PracticeModeSheet extends StatelessWidget {
  final List<Subject> subjects;
  final void Function(Subject) onSubjectSelected;

  const PracticeModeSheet({
    super.key,
    required this.subjects,
    required this.onSubjectSelected,
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
              l10n.practiceModeTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (subjects.length == 1)
              PracticeModeOption(
                icon: Icons.auto_fix_high,
                title: l10n.autoSelect,
                subtitle: l10n.aiPicksOptimalQuestions,
                onTap: () {
                  Navigator.pop(context);
                  onSubjectSelected(subjects.first);
                },
              )
            else ...[
              Text(
                l10n.chooseSubject,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...subjects.map((subject) => PracticeModeOption(
                icon: Icons.school,
                title: subject.name,
                subtitle: subject.code ?? l10n.noCode,
                onTap: () {
                  Navigator.pop(context);
                  onSubjectSelected(subject);
                },
              )),
            ],
            const SizedBox(height: 16),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PracticeModeSheet(
        subjects: subjects,
        onSubjectSelected: onSubjectSelected,
      ),
    );
  }
}
