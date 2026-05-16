import 'dart:async';

class VoiceController {
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  bool _isListening = false;
  bool _isSpeaking = false;

  Stream<String> get transcribedText => _transcriptionController.stream;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;
  bool _isAvailable = false;

  VoiceController() {
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      _isAvailable = false;
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<bool> requestPermission() async {
    return false;
  }

  Future<void> startListening() async {
    if (!_isAvailable) return;
    _isListening = true;
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
  }

  Future<void> speak(String text) async {
    if (!_isAvailable) return;
    _isSpeaking = true;
    try {
      await Future.delayed(Duration.zero);
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
  }

  void dispose() {
    _transcriptionController.close();
  }
}
