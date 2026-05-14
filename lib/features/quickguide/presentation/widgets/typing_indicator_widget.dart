import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class TypingIndicatorWidget extends StatelessWidget {
  final bool isStreaming;

  const TypingIndicatorWidget({super.key, required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: AnimatedOpacity(
        opacity: isStreaming ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: ResponsiveUtils.listPadding(context),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.quickGuideIsThinking,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
