import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SuggestedPromptsWidget extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onSelectPrompt;

  const SuggestedPromptsWidget({
    super.key,
    required this.prompts,
    required this.onSelectPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: ResponsiveUtils.listPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.verticalSpacing(context) * 0.75,
            ),
            child: Text(
              l10n.suggestedPrompts,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FocusTraversalGroup(
            child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts.map((prompt) {
              return Semantics(
                label: l10n.semanticsSendPrompt(prompt),
                button: true,
                child: ActionChip(
                  label: Text(
                    prompt,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  onPressed: () => onSelectPrompt(prompt),
                  backgroundColor: colorScheme.secondaryContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );
            }            ).toList(),
          ),
          ),
        ],
      ),
    );
  }
}
