import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyking/core/services/voice_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class VoiceBar extends StatefulWidget {
  final VoiceService controller;
  final ValueChanged<String> onTranscriptionSubmitted;
  final bool isEnabled;
  final bool reduceMotion;

  const VoiceBar({
    super.key,
    required this.controller,
    required this.onTranscriptionSubmitted,
    this.isEnabled = true,
    this.reduceMotion = false,
  });

  @override
  State<VoiceBar> createState() => _VoiceBarState();
}

class _VoiceBarState extends State<VoiceBar> with SingleTickerProviderStateMixin {
  StreamSubscription<String>? _transcriptionSubscription;
  String _currentTranscription = '';
  late AnimationController _waveController;
  Timer? _reviewTimer;
  bool _showReviewOverlay = false;

  static const Duration _reviewOverlayDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _transcriptionSubscription = widget.controller.transcribedText.listen(
      (text) {
        if (mounted) setState(() => _currentTranscription = text);
      },
    );
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _transcriptionSubscription?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!widget.isEnabled) return;
    if (widget.controller.isListening) {
      widget.controller.stopListening();
      _waveController.stop();
      if (!widget.reduceMotion && _currentTranscription.isNotEmpty) {
        setState(() => _showReviewOverlay = true);
        _reviewTimer?.cancel();
        _reviewTimer = Timer(_reviewOverlayDuration, () {
          if (mounted && _showReviewOverlay) {
            setState(() => _showReviewOverlay = false);
            widget.onTranscriptionSubmitted(_currentTranscription);
            _currentTranscription = '';
          }
        });
      } else {
        if (_currentTranscription.isNotEmpty) {
          widget.onTranscriptionSubmitted(_currentTranscription);
          _currentTranscription = '';
        }
      }
    } else {
      final granted = await widget.controller.requestPermission();
      if (!granted) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }
      if (!widget.controller.isAvailable) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.micPermissionDenied),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.retry,
                onPressed: _toggleListening,
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final localeName = l10n?.localeName ?? 'en';
      widget.controller.startListening(localeName: localeName);
      if (!widget.reduceMotion) {
        _waveController.repeat();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.microphonePermissionRequired),
        content: Text(l10n.micPermissionDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleListening();
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  void _cancelReview() {
    _reviewTimer?.cancel();
    _reviewTimer = null;
    setState(() {
      _showReviewOverlay = false;
      _currentTranscription = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = widget.controller.isListening;

    return Semantics(
      container: true,
      label: isListening ? l10n.voiceListeningHint : l10n.voiceInput,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isListening && _currentTranscription.isNotEmpty)
            Flexible(
              child: Semantics(
                liveRegion: true,
                label: _currentTranscription,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    _currentTranscription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          if (isListening && !widget.reduceMotion)
            Semantics(
              excludeSemantics: true,
              child: SizedBox(
                width: 24,
                height: 24,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(24, 24),
                      painter: _WaveformPainter(
                        value: _waveController.value,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                ),
              ),
            ),
          Semantics(
            button: true,
            label: isListening ? l10n.stopRecording : l10n.voiceInput,
            child: IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? Theme.of(context).colorScheme.error : null,
              ),
              onPressed: widget.isEnabled ? _toggleListening : null,
              tooltip: isListening ? l10n.stopRecording : l10n.voiceInput,
            ),
          ),
          if (_showReviewOverlay)
            Semantics(
              button: true,
              label: l10n.cancel,
              child: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                onPressed: _cancelReview,
                tooltip: l10n.cancel,
              ),
            ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double value;
  final Color color;

  _WaveformPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barCount = 5;
    final barWidth = size.width / (barCount * 2);
    for (int i = 0; i < barCount; i++) {
      final normalizedPhase = ((value + i / barCount) % 1.0);
      final height = 4 + 16 * normalizedPhase;
      final x = i * barWidth * 2 + barWidth / 2;
      final y = (size.height - height) / 2;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => oldDelegate.value != value;
}
