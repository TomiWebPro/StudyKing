import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart'
    show SpeechRecognitionError;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

class VoiceService {
  static final Logger _logger = const Logger('VoiceService');

  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController =
      StreamController<bool>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  stt.SpeechToText? _speech;
  FlutterTts? _tts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isAvailable = false;
  bool _initialized = false;
  bool _isDisposed = false;
  final TargetPlatform _platform;

  Stream<String> get transcribedText => _transcriptionController.stream;
  Stream<bool> get listeningState => _listeningStateController.stream;
  Stream<String?> get lastError => _errorController.stream;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;

  VoiceService({TargetPlatform? platform})
      : _platform = platform ?? defaultTargetPlatform {
    if (!kIsWeb) {
      _initialize();
    }
  }

  bool get _isPlatformSupported {
    switch (_platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isPlatformSupported) {
      _logger.d(
        'VoiceService not supported on ${_platform.name}; skipping init',
      );
      _isAvailable = false;
      return;
    }

    try {
      _speech = stt.SpeechToText();
      _tts = FlutterTts();
      await _checkAvailability();
    } catch (e) {
      _logger.w('Failed to initialize voice service', e);
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
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
      _isAvailable = available;
      if (!available) {
        _emitError('Microphone permission is required.');
      }
    } catch (e) {
      _logger.w('Failed to check speech availability', e);
      _emitError('Failed to initialize speech recognition');
      _isAvailable = false;
    }
  }

  /// Shared speech recognition callbacks, registered on every
  /// [stt.SpeechToText.initialize] call. speech_to_text replaces
  /// its listeners with whatever the call provides, so every
  /// initialize call (including the [requestPermission] retry)
  /// must pass these along or recognition status updates are
  /// silently dropped.
  void _handleSpeechError(SpeechRecognitionError error) {
    _isAvailable = false;
    _emitError('Speech recognition error');
  }

  void _handleSpeechStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      _isListening = false;
      _emitListeningState(false);
    }
  }

  /// Stream emission helpers. Once [dispose] has run, late plugin
  /// callbacks (a final status event after stop(), an error, or a
  /// partial transcription) must not add to closed controllers.
  void _emitError(String message) {
    if (_isDisposed) return;
    _errorController.add(message);
  }

  void _emitListeningState(bool listening) {
    if (_isDisposed) return;
    _listeningStateController.add(listening);
  }

  void _emitTranscription(String text) {
    if (_isDisposed) return;
    _transcriptionController.add(text);
  }

  Future<bool> requestPermission() async {
    if (_speech == null) {
      _emitError('Speech engine not available');
      return false;
    }
    try {
      // speech_to_text replaces its status/error listeners with
      // whatever is passed to initialize(); omitting them here
      // would wipe the listeners registered in [_checkAvailability]
      // and silently drop every recognition status update (including
      // the "notListening" event that resets the listening state).
      final hasPermission = await _speech!.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );
      _isAvailable = hasPermission;
      if (!hasPermission) {
        _emitError('Microphone permission denied. Grant access in Settings.');
      }
      return hasPermission;
    } catch (e) {
      _logger.w('Failed to request speech permission', e);
      _emitError('Failed to request microphone permission');
      return false;
    }
  }

  Future<Result<void>> startListening({String? localeName}) async {
    if (_speech == null) {
      _emitError('Speech engine not available');
      return Result.failure('Speech engine not available');
    }
    if (!_isAvailable) {
      _emitError('Microphone permission is required. Please grant access.');
      return Result.failure('Microphone permission is required');
    }
    if (_isListening) return Result.success(null);

    if (_isSpeaking) {
      await stopSpeaking();
    }

    try {
      await _speech!.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _emitTranscription(result.recognizedWords);
          }
        },
        listenFor: Timeouts.voiceListen,
        pauseFor: Timeouts.voicePause,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
        localeId: _localeForSpeech(localeName),
      );
      _isListening = true;
      _emitListeningState(true);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to start listening', e);
      _emitError('Failed to start listening');
      _isListening = false;
      _emitListeningState(false);
      return Result.failure(e.toString());
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
    _emitListeningState(false);
  }

  Future<void> speak(String text, {String? localeName}) async {
    if (_tts == null) return;
    if (text.isEmpty) return;

    if (_isListening) {
      _logger.w('TTS blocked: voice input is active');
      return;
    }

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

  Future<void> stopAll() async {
    await stopListening();
    await stopSpeaking();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stopAll();
    _transcriptionController.close();
    _listeningStateController.close();
    _errorController.close();
  }
}


