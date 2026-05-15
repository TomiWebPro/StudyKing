import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Semantics(
          headingLevel: 1,
          child: Text(
            l10n.studyDashboard,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
