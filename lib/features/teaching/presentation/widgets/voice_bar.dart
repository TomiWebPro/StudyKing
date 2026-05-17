import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../services/voice_controller.dart';

class VoiceBar extends StatefulWidget {
  final VoiceController controller;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.requestPermission();
    });
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    if (!widget.isEnabled) return;
    if (widget.controller.isListening) {
      widget.controller.stopListening();
      _waveController.stop();
      if (_currentTranscription.isNotEmpty) {
        widget.onTranscriptionSubmitted(_currentTranscription);
        _currentTranscription = '';
      }
    } else {
      final l10n = AppLocalizations.of(context);
      final localeName = l10n?.localeName ?? 'en';
      widget.controller.startListening(localeName: localeName);
      if (!widget.reduceMotion) {
        _waveController.repeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = widget.controller.isListening;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isListening && _currentTranscription.isNotEmpty)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
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
        if (isListening)
          SizedBox(
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
        IconButton(
          icon: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: isListening ? Theme.of(context).colorScheme.error : null,
          ),
          onPressed: _toggleListening,
          tooltip: isListening ? l10n.voiceInput : l10n.voiceInput,
        ),
      ],
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
