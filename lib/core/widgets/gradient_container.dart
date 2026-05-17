import 'package:flutter/material.dart';

class GradientContainer extends StatelessWidget {
  final Color accent;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GradientContainer({
    super.key,
    required this.accent,
    required this.child,
    this.borderRadius = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            accent.withValues(alpha: isDark ? 0.3 : 0.15),
            accent.withValues(alpha: isDark ? 0.1 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }
}
