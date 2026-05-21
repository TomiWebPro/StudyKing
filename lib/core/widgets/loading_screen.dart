import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  final double strokeWidth;
  final Color? color;
  final String? message;
  final String? semanticsLabel;

  const LoadingScreen({
    super.key,
    this.strokeWidth = 3,
    this.color,
    this.message,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveLabel = semanticsLabel ?? message ?? l10n.loading;

    return Semantics(
      label: effectiveLabel,
      liveRegion: true,
      child: LoadingIndicator(message: message),
    );
  }
}
