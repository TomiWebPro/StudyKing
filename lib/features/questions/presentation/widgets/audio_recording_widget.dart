import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class AudioRecordingWidget extends StatefulWidget {
  final String? currentAnswer;
  final bool isSubmitted;
  final ValueChanged<String?> onAnswerChanged;

  const AudioRecordingWidget({
    super.key,
    this.currentAnswer,
    this.isSubmitted = false,
    required this.onAnswerChanged,
  });

  @override
  State<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends State<AudioRecordingWidget> {
  static final Logger _logger = const Logger('AudioRecordingWidget');
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  String? _localAnswer;

  @override
  void initState() {
    super.initState();
    _localAnswer = widget.currentAnswer;
  }

  @override
  void didUpdateWidget(covariant AudioRecordingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAnswer != widget.currentAnswer) {
      _localAnswer = widget.currentAnswer;
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        _amplitudeSubscription?.cancel();
        _amplitudeSubscription = null;
        setState(() => _isRecording = false);
        if (path != null && path.isNotEmpty) {
          setState(() => _localAnswer = path);
          widget.onAnswerChanged(path);
        }
      } catch (e) {
        _logger.w('Failed to stop audio recording', e);
        setState(() => _isRecording = false);
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          final path = '${Directory.systemTemp.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => _isRecording = true);
          _amplitudeSubscription = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen(
            (amplitude) {
              setState(() {});
            },
          );
        }
      } catch (e) {
        _logger.w('Failed to start audio recording', e);
        setState(() => _isRecording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasRecording = _localAnswer != null && _localAnswer!.isNotEmpty;
    return Semantics(
      button: true,
      label: _isRecording ? l10n.recordingInProgress : l10n.recordAudio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: widget.isSubmitted ? null : _toggleRecording,
            icon: _isRecording
                ? const Icon(Icons.stop)
                : Icon(hasRecording ? Icons.mic : Icons.mic_none),
            label: Text(
              _isRecording
                  ? l10n.stopRecording
                  : hasRecording
                      ? l10n.recordingComplete
                      : l10n.startRecording,
            ),
          ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.waves, size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    l10n.recordingInProgress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          if (hasRecording)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _localAnswer!.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
