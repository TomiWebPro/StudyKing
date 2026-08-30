import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double strokeWidth;
  final Color? color;
  final String? semanticsLabel;

  const LoadingIndicator({
    super.key,
    this.message,
    this.strokeWidth = 3,
    this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: semanticsLabel ?? message ?? l10n?.loading ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
