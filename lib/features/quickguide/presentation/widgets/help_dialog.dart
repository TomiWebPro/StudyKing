import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

void showQuickGuideHelpDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.quickGuideHelpTitle),
      content: Text(l10n.quickGuideHelpContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.gotIt),
        ),
      ],
    ),
  );
}
