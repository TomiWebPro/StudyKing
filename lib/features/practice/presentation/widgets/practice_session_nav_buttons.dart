import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class PracticeSessionNavButtons extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  const PracticeSessionNavButtons({
    super.key,
    this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bp = ResponsiveUtils.breakpointOf(context);

    if (bp == ScreenBreakpoint.xs) {
      return Column(
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(5),
            child: Semantics(
              label: l10n.previous,
              child: ElevatedButton.icon(
                onPressed: onPrevious,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.previous),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FocusTraversalOrder(
            order: const NumericFocusOrder(6),
            child: Semantics(
              label: l10n.next,
              child: ElevatedButton.icon(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.next),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(5),
            child: Semantics(
              label: l10n.previous,
              child: ElevatedButton.icon(
                onPressed: onPrevious,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.previous),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(6),
            child: Semantics(
              label: l10n.next,
              child: ElevatedButton.icon(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.next),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
