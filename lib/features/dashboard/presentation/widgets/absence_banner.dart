import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/routes/app_router.dart';

class AbsenceBanner extends StatelessWidget {
  final int daysSinceLastActivity;

  const AbsenceBanner({
    super.key,
    required this.daysSinceLastActivity,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String message;
    IconData icon;
    Color bgColor;
    Color fgColor;

    if (daysSinceLastActivity >= 14) {
      message = l10n.welcomeBackDays(daysSinceLastActivity);
      icon = Icons.warning_amber_rounded;
      bgColor = Theme.of(context).colorScheme.errorContainer;
      fgColor = Theme.of(context).colorScheme.error;
    } else if (daysSinceLastActivity >= 7) {
      message = l10n.welcomeBackDays(daysSinceLastActivity);
      icon = Icons.warning_amber_rounded;
      bgColor = Theme.of(context).colorScheme.errorContainer;
      fgColor = Theme.of(context).colorScheme.error;
    } else if (daysSinceLastActivity >= 3) {
      message = l10n.welcomeBackDays(daysSinceLastActivity);
      icon = Icons.info_outline;
      bgColor = Theme.of(context).colorScheme.tertiaryContainer;
      fgColor = Theme.of(context).colorScheme.tertiary;
    } else {
      message = l10n.welcomeBackDays(daysSinceLastActivity);
      icon = Icons.info_outline;
      bgColor = Theme.of(context).colorScheme.tertiaryContainer;
      fgColor = Theme.of(context).colorScheme.tertiary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.absenceDetectedTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.planner),
            style: TextButton.styleFrom(foregroundColor: fgColor),
            child: Text(l10n.studyPlanner),
          ),
        ],
      ),
    );
  }
}
