import 'package:flutter/material.dart';
import 'package:studyking/core/theme/app_theme.dart';

class FocusTimerWidget extends StatefulWidget {
  final int plannedDurationMinutes;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isActive;
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
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FocusTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
    final remaining = remainingSeconds;
    final isComplete = widget.isActive && remaining <= 0;
    final progressColor = AppTheme.progressColor(progress, context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = widget.isPaused
                ? 1.0
                : 1.0 + (_pulseController.value * 0.03);
            return Transform.scale(
              scale: pulse,
              child: child,
            );
          },
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? Colors.green : progressColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(remaining),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isComplete ? Colors.green : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isPaused ? 'PAUSED' : isComplete ? 'DONE!' : 'remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.isPaused
                            ? Colors.orange
                            : isComplete
                                ? Colors.green
                                : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (widget.isActive) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isPaused)
                FilledButton.icon(
                  onPressed: widget.onResume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                )
              else
                FilledButton.icon(
                  onPressed: widget.onPause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.stop),
                label: const Text('End'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!widget.isPaused && remaining > 0)
            TextButton.icon(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark Complete'),
            ),
        ],
      ],
    );
  }
}
