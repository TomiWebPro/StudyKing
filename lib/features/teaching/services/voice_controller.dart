import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceController {
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController =
      StreamController<bool>.broadcast();

  stt.SpeechToText? _speech;
  FlutterTts? _tts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isAvailable = false;
  bool _initialized = false;

  Stream<String> get transcribedText => _transcriptionController.stream;
  Stream<bool> get listeningState => _listeningStateController.stream;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;

  VoiceController() {
    if (!kIsWeb) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _speech = stt.SpeechToText();
      _tts = FlutterTts();
      await _checkAvailability();
    } catch (e) {
      _isAvailable = false;
    }
  }

  Future<void> _checkAvailability() async {
    try {
      if (_speech == null) {
        _isAvailable = false;
        return;
      }
      final available = await _speech!.initialize(
        onError: (error) {
          _isAvailable = false;
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            _listeningStateController.add(false);
          }
        },
      );
      _isAvailable = available;
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<bool> requestPermission() async {
    if (_speech == null) return false;
    try {
      final hasPermission = await _speech!.initialize();
      _isAvailable = hasPermission;
      return hasPermission;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening() async {
    if (_speech == null || !_isAvailable) return;
    if (_isListening) return;

    try {
      await _speech!.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _transcriptionController.add(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
        localeId: 'en_US',
      );
      _isListening = true;
      _listeningStateController.add(true);
    } catch (_) {
      _isListening = false;
      _listeningStateController.add(false);
    }
  }

  Future<void> stopListening() async {
    if (_speech == null || !_isListening) return;
    try {
      await _speech!.stop();
    } catch (_) {}
    _isListening = false;
    _listeningStateController.add(false);
  }

  Future<void> speak(String text) async {
    if (_tts == null) return;
    if (text.isEmpty) return;
    _isSpeaking = true;
    try {
      await _tts!.setLanguage('en-US');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);
      _tts!.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts!.setErrorHandler((_) {
        _isSpeaking = false;
      });
      await _tts!.speak(text);
    } catch (_) {
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    if (_tts == null) return;
    try {
      await _tts!.stop();
    } catch (_) {}
    _isSpeaking = false;
  }

  void dispose() {
    stopListening();
    stopSpeaking();
    _transcriptionController.close();
    _listeningStateController.close();
  }
}
