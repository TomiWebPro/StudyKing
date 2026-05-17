import 'package:flutter/material.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/core/utils/responsive.dart';

class SubjectPracticeCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const SubjectPracticeCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.getSubjectColor(context, subject.name);
    final bp = ResponsiveUtils.breakpointOf(context);
    final iconContainerSize = bp.isXs ? 48.0 : 56.0;
    return Semantics(
      button: true,
      label: subject.name,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: ResponsiveUtils.cardPadding(context),
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subject.code != null)
                        Text(
                          subject.code ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      SizedBox(height: ResponsiveUtils.verticalSpacing(context)),
                      Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.practiceAvailable,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
