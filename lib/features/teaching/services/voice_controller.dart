import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/utils/logger.dart';

class VoiceController {
  static final Logger _logger = const Logger('VoiceController');

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
      _logger.w('Failed to initialize voice controller', e);
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
    } catch (e) {
      _logger.w('Failed to check speech availability', e);
      _isAvailable = false;
    }
  }

  Future<bool> requestPermission() async {
    if (_speech == null) return false;
    try {
      final hasPermission = await _speech!.initialize();
      _isAvailable = hasPermission;
      return hasPermission;
    } catch (e) {
      _logger.w('Failed to request speech permission', e);
      return false;
    }
  }

  Future<void> startListening({String? localeName}) async {
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
        localeId: _localeForSpeech(localeName),
      );
      _isListening = true;
      _listeningStateController.add(true);
    } catch (e) {
      _logger.w('Failed to start listening', e);
      _isListening = false;
      _listeningStateController.add(false);
    }
  }

  String _localeForSpeech(String? localeName) {
    if (localeName == null || localeName.isEmpty) return 'en_US';
    switch (localeName) {
      case 'es':
      case 'es_ES':
        return 'es_ES';
      case 'fr':
      case 'fr_FR':
        return 'fr_FR';
      case 'de':
      case 'de_DE':
        return 'de_DE';
      case 'pt':
      case 'pt_BR':
        return 'pt_BR';
      case 'it':
      case 'it_IT':
        return 'it_IT';
      case 'ja':
      case 'ja_JP':
        return 'ja_JP';
      case 'zh':
      case 'zh_CN':
        return 'zh_CN';
      default:
        return 'en_US';
    }
  }

  String _localeForTts(String? localeName) {
    if (localeName == null || localeName.isEmpty) return 'en-US';
    final speechLocale = _localeForSpeech(localeName);
    return speechLocale.replaceAll('_', '-');
  }

  Future<void> stopListening() async {
    if (_speech == null || !_isListening) return;
    try {
      await _speech!.stop();
    } catch (e) {
      _logger.w('Failed to stop listening', e);
    }
    _isListening = false;
    _listeningStateController.add(false);
  }

  Future<void> speak(String text, {String? localeName}) async {
    if (_tts == null) return;
    if (text.isEmpty) return;
    _isSpeaking = true;
    try {
      await _tts!.setLanguage(_localeForTts(localeName));
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
    } catch (e) {
      _logger.w('Failed to speak text', e);
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    if (_tts == null) return;
    try {
      await _tts!.stop();
    } catch (e) {
      _logger.w('Failed to stop speaking', e);
    }
    _isSpeaking = false;
  }

  void dispose() {
    stopListening();
    stopSpeaking();
    _transcriptionController.close();
    _listeningStateController.close();
  }
}
