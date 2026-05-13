import 'package:flutter/material.dart';
import 'package:studyking/core/utils/responsive.dart';

class AnimatedBarChart extends StatefulWidget {
  final Map<String, int> data;
  final Color accentColor;
  final double minBarHeight;
  final double maxBarHeight;
  final double barWidth;
  final double borderRadius;
  final String? yAxisLabel;
  final bool showValueTooltips;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.accentColor = Colors.blue,
    this.minBarHeight = 40,
    this.maxBarHeight = 120,
    this.barWidth = 32,
    this.borderRadius = 6,
    this.yAxisLabel,
    this.showValueTooltips = true,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> {
  bool _hasAnimated = false;

  @override
  void didUpdateWidget(AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _hasAnimated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawMax = widget.data.values.isNotEmpty
        ? widget.data.values.reduce((a, b) => a > b ? a : b)
        : 0;
    final maxCount = rawMax > 0 ? rawMax : 1;

    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.yAxisLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.yAxisLabel!,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.data.keys.map((day) {
              final count = widget.data[day] ?? 0;
              final height = widget.minBarHeight +
                  (count / maxCount * (widget.maxBarHeight - widget.minBarHeight));

              return Expanded(
                child: Column(
                  key: ValueKey('bar_$day'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showValueTooltips && count > 0)
                      Tooltip(
                        message: '$count',
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: count > 0
                                ? widget.accentColor
                                : (theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: _hasAnimated ? height : 0,
                        end: height,
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Container(
                          width: widget.barWidth,
                          height: value,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? widget.accentColor.withValues(
                                    alpha: 0.7 + (count / maxCount * 0.3))
                                : theme.disabledColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
