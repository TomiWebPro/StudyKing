import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';

class PracticeModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onTapDisabled;
  final int? badge;

  const PracticeModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.onTapDisabled,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = onTap != null;
    final semanticLabel = badge != null && badge! > 0
        ? '$title, $subtitle, $badge'
        : '$title, $subtitle';
    return Card(
      child: Semantics(
        button: true,
        label: semanticLabel,
        enabled: isAvailable,
        child: InkWell(
          onTap: isAvailable ? onTap : onTapDisabled,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                padding: ResponsiveUtils.cardPadding(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isAvailable ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isAvailable ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isAvailable ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null && badge! > 0)
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: 8,
                  end: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
