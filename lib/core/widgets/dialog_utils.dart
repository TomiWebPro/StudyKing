import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel ?? l10n?.cancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel ?? l10n?.confirm ?? 'Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}
