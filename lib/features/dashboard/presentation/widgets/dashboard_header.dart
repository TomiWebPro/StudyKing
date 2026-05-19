import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback? onExportTap;

  const DashboardHeader({super.key, this.onExportTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            headingLevel: 1,
            child: Text(
              l10n.studyDashboard,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: l10n.exportReports,
          child: IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.exportReports,
            onPressed: onExportTap ?? () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.backupAndRestore,
          child: IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: l10n.backupAndRestore,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.quickGuide,
          child: IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.quickGuide,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.quickGuide),
          ),
        ),
      ],
    );
  }
}
