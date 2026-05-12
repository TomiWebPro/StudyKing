import 'package:flutter/material.dart';

class AnimatedBarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color accentColor;
  final double minBarHeight;
  final double maxBarHeight;
  final double barWidth;
  final double borderRadius;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.accentColor = Colors.blue,
    this.minBarHeight = 40,
    this.maxBarHeight = 120,
    this.barWidth = 32,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawMax = data.values.isNotEmpty
        ? data.values.reduce((a, b) => a > b ? a : b)
        : 0;
    final maxCount = rawMax > 0 ? rawMax : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.keys.map((day) {
          final count = data[day] ?? 0;
          final height = minBarHeight +
              (count / maxCount * (maxBarHeight - minBarHeight));

          return Column(
            key: ValueKey('bar_$day'),
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: height),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    width: barWidth,
                    height: value,
                    decoration: BoxDecoration(
                      color: count > 0
                          ? accentColor.withValues(
                              alpha: 0.7 + (count / maxCount * 0.3))
                          : theme.disabledColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? accentColor : (theme.textTheme.bodySmall?.color ?? Colors.grey),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
