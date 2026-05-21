import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ConfidenceSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const ConfidenceSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static Color getConfidenceColor(int rating, ColorScheme cs) {
    switch (rating) {
      case 1:
        return cs.error;
      case 2:
      case 3:
        return cs.tertiary;
      case 4:
      case 5:
        return cs.primary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  static String getConfidenceLabel(AppLocalizations l10n, int rating) {
    switch (rating) {
      case 1:
        return l10n.notConfidentAtAll;
      case 2:
        return l10n.slightlyConfident;
      case 3:
        return l10n.moderatelyConfident;
      case 4:
        return l10n.quiteConfident;
      case 5:
        return l10n.veryConfident;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLabel = getConfidenceLabel(l10n, value);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howConfident,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context) / 2),
        Semantics(
          label: '${l10n.howConfident}: $value ${l10n.confidenceRatingOf} 5, $currentLabel',
          child: Wrap(
            spacing: ResponsiveUtils.horizontalSpacing(context),
            runSpacing: ResponsiveUtils.verticalSpacing(context) / 2,
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = value == rating;
              return Semantics(
                button: true,
                selected: isSelected,
                child: InkWell(
                  onTap: () => onChanged(rating),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.sizeOf(context).width / 6).clamp(32.0, ResponsiveUtils.minTouchTarget),
                    height: (MediaQuery.sizeOf(context).width / 6).clamp(32.0, ResponsiveUtils.minTouchTarget),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? getConfidenceColor(rating, cs).withValues(alpha: 0.2)
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? getConfidenceColor(rating, cs)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? getConfidenceColor(rating, cs)
                              : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: ResponsiveUtils.verticalSpacing(context) / 2),
        Center(
          child: Text(
            currentLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
