import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FocusTimerWidget extends StatefulWidget {
  final int plannedDurationMinutes;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isActive;
  final bool reduceMotion;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const FocusTimerWidget({
    super.key,
    required this.plannedDurationMinutes,
    required this.elapsedSeconds,
    this.isPaused = false,
    this.isActive = false,
    this.reduceMotion = false,
    this.onPause,
    this.onResume,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends State<FocusTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  int get totalSeconds => widget.plannedDurationMinutes * 60;
  int get remainingSeconds => (totalSeconds - widget.elapsedSeconds).clamp(0, totalSeconds);
  double get progress => totalSeconds > 0 ? widget.elapsedSeconds / totalSeconds : 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(FocusTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulseAnimation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulseAnimation();
  }

  void _syncPulseAnimation() {
    final isRunning = widget.isActive && !widget.isPaused;
    final disableAll = widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    if (isRunning) {
      if (disableAll) {
        _pulseController.stop();
        _pulseController.reset();
      } else if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final remaining = remainingSeconds;
    final isComplete = widget.isActive && remaining <= 0;
    final progressColor = AppTheme.progressColor(progress, context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth * 0.8;
              final bp = ResponsiveUtils.breakpointOf(context);
              final maxRingSize = bp.isLg ? 320.0 : bp.isMd ? 280.0 : 260.0;
              final size = maxWidth.clamp(200.0, maxRingSize);
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final disableAnimations = MediaQuery.disableAnimationsOf(context) || widget.reduceMotion;
                  if (widget.isPaused || disableAnimations) {
                    return child!;
                  }
                  final ringOpacity = _pulseController.value * 0.15;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      child!,
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: progressColor.withValues(alpha: ringOpacity),
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? cs.primary : progressColor,
                        ),
                      ),
                    ),
                    Semantics(
                      liveRegion: true,
                      label: widget.isPaused
                          ? '${l10n.timerPaused}, ${_formatTime(remaining)}'
                          : isComplete
                              ? '${l10n.timerDone}, ${_formatTime(remaining)}'
                              : '${l10n.timerRemaining}, ${_formatTime(remaining)}',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatTime(remaining),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isComplete ? cs.primary : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isPaused
                                ? l10n.timerPaused
                                : isComplete
                                    ? l10n.timerDone
                                    : l10n.timerRemaining,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: widget.isPaused
                                  ? cs.tertiary
                                  : isComplete
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
        ),
        const SizedBox(height: 32),
        if (widget.isActive) ...[
          ResponsiveUtils.breakpointOf(context).isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isPaused)
                      FilledButton.icon(
                        onPressed: widget.onResume,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.resume),
                      )
                    else
                      FilledButton.icon(
                        onPressed: widget.onPause,
                        icon: const Icon(Icons.pause),
                        label: Text(l10n.pause),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.stop),
                      label: Text(l10n.end),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isPaused)
                      FilledButton.icon(
                        onPressed: widget.onResume,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.resume),
                      )
                    else
                      FilledButton.icon(
                        onPressed: widget.onPause,
                        icon: const Icon(Icons.pause),
                        label: Text(l10n.pause),
                      ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.stop),
                      label: Text(l10n.end),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          if (!widget.isPaused && remaining > 0)
            TextButton.icon(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.markComplete),
            ),
        ],
      ],
    );
  }
}
