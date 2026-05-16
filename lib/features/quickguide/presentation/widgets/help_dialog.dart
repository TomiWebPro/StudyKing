import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class QuickGuideHelpDialog extends StatelessWidget {
  const QuickGuideHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      semanticLabel: l10n.quickGuideHelpTitle,
      title: Text(l10n.quickGuideHelpTitle),
      content: Text(l10n.quickGuideHelpContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.gotIt),
        ),
      ],
    );
  }
}

void showQuickGuideHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const QuickGuideHelpDialog(),
  );
}
