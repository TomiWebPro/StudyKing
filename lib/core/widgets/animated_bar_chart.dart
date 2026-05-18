import 'package:flutter/material.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/utils/responsive.dart';

class AnimatedBarChart extends StatefulWidget {
  final Map<String, int> data;
  final Color? accentColor;
  final double minBarHeight;
  final double maxBarHeight;
  final double? barWidth;
  final double borderRadius;
  final String? yAxisLabel;
  final bool showValueTooltips;
  final bool reduceMotion;
  final double maxBarWidth;
  final String Function(String day, int count)? semanticsLabelBuilder;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.accentColor,
    this.minBarHeight = 40,
    this.maxBarHeight = 120,
    this.barWidth,
    this.borderRadius = 6,
    this.yAxisLabel,
    this.showValueTooltips = true,
    this.reduceMotion = false,
    this.maxBarWidth = 48,
    this.semanticsLabelBuilder,
  });

  static const double minBarWidth = 24;

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> {
  Map<String, double> _previousHeights = {};

  double _computeBarWidth(double availableWidth) {
    if (widget.barWidth != null) return widget.barWidth!;
    final count = widget.data.length;
    if (count == 0) return AnimatedBarChart.minBarWidth;
    final computed = (availableWidth - 8 * (count - 1)) / count;
    return computed.clamp(AnimatedBarChart.minBarWidth, widget.maxBarWidth);
  }

  Widget _buildBar(BuildContext context, double height, String day, int count, int maxCount, ThemeData theme, double barWidth, Color accentColor) {
    if (widget.reduceMotion) {
      return Container(
        width: barWidth,
        height: height,
        decoration: BoxDecoration(
          color: count > 0
              ? accentColor.withValues(alpha: 0.7 + (count / maxCount * 0.3))
              : theme.disabledColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }
    final previousHeight = _previousHeights[day] ?? widget.minBarHeight;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: previousHeight,
        end: height,
      ),
      duration: Timeouts.barChartAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          width: barWidth,
          height: value,
          decoration: BoxDecoration(
            color: count > 0
                ? accentColor.withValues(alpha: 0.7 + (count / maxCount * 0.3))
                : theme.disabledColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _previousHeights = Map.fromEntries(
        oldWidget.data.entries.map((e) => MapEntry(e.key, _computeHeight(e.value, oldWidget.data.values.isNotEmpty ? oldWidget.data.values.reduce((a, b) => a > b ? a : b) : 0))),
      );
    }
  }

  double _computeHeight(int count, int maxCount) {
    final rawMax = maxCount > 0 ? maxCount : 1;
    return widget.minBarHeight + (count / rawMax * (widget.maxBarHeight - widget.minBarHeight));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.accentColor ?? theme.colorScheme.primary;
    final rawMax = widget.data.values.isNotEmpty
        ? widget.data.values.reduce((a, b) => a > b ? a : b)
        : 0;
    final maxCount = rawMax > 0 ? rawMax : 1;

    return Container(
      padding: ResponsiveUtils.cardPadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
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
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = _computeBarWidth(constraints.maxWidth);
              final totalBarWidth = widget.data.length * barWidth + 8 * (widget.data.length - 1);
              final surplus = (constraints.maxWidth - totalBarWidth).clamp(0.0, double.infinity);
              return Row(
                mainAxisAlignment: surplus > 0 ? MainAxisAlignment.center : MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.data.keys.map((day) {
                  final count = widget.data[day] ?? 0;
                  final height = widget.minBarHeight +
                      (count / maxCount * (widget.maxBarHeight - widget.minBarHeight));

                  return Semantics(
                    label: widget.semanticsLabelBuilder != null
                        ? widget.semanticsLabelBuilder!(day, count)
                        : '$day: $count sessions',
                    value: '$count',
                    child: Column(
                      key: ValueKey('bar_$day'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showValueTooltips && count > 0)
                          Tooltip(
                            message: '$count',
                            child: Text(
                              '$count',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: count > 0 ? accentColor : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        _buildBar(context, height, day, count, maxCount, theme, barWidth, accentColor),
                        const SizedBox(height: 6),
                        Text(
                          day,
                          style: theme.textTheme.labelSmall?.copyWith(
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
              );
            },
          ),
        ],
      ),
    );
  }
}
