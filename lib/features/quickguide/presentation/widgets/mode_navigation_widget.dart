import 'package:flutter/material.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class ModeNavigationWidget extends StatelessWidget {
  const ModeNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: ResponsiveUtils.listPadding(context),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chooseStudyMode,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FocusTraversalGroup(
            child: Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  context,
                  icon: Icons.smart_toy,
                  title: l10n.aiTutor,
                  subtitle: l10n.interactiveConversationalLessons,
                  color: colorScheme.primary,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.tutor,
                      arguments: const TutorArgs(
                        topicId: '',
                        topicTitle: '',
                        subjectId: '',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  context,
                  icon: Icons.auto_awesome,
                  title: l10n.mentor,
                  subtitle: l10n.personalStudyAssistantPlanner,
                  color: colorScheme.secondary,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.mentor);
                  },
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title: $subtitle',
      explicitChildNodes: true,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: ResponsiveUtils.cardPadding(context),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
