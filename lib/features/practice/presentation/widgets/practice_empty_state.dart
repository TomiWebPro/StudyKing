import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/widgets/empty_state_widget.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticeEmptyState extends StatelessWidget {
  final VoidCallback? onAddSubject;

  const PracticeEmptyState({super.key, this.onAddSubject});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyStateWidget(
          icon: Icons.book_online_outlined,
          title: l10n.noPracticeSessionsYet,
          subtitle: l10n.addSubjectsAndQuestionsToStartPracticing,
          actionLabel: l10n.addSubject,
          onAction: onAddSubject ?? () => Navigator.pushNamed(context, AppRoutes.subjectSelection),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
          child: Text(l10n.uploadMaterial),
        ),
      ],
    );
  }
}
