import 'dart:async';
import 'package:studyking/core/services/voice_service.dart';

class VoiceController {
  final VoiceService _service;

  Stream<String> get transcribedText => _service.transcribedText;
  Stream<bool> get listeningState => _service.listeningState;
  bool get isListening => _service.isListening;
  bool get isSpeaking => _service.isSpeaking;
  bool get isAvailable => _service.isAvailable;

  VoiceController() : _service = VoiceService();

  Future<bool> requestPermission() => _service.requestPermission();

  Future<void> startListening({String? localeName}) =>
      _service.startListening(localeName: localeName);

  Future<void> stopListening() => _service.stopListening();

  Future<void> speak(String text, {String? localeName}) =>
      _service.speak(text, localeName: localeName);

  Future<void> stopSpeaking() => _service.stopSpeaking();

  void dispose() => _service.dispose();
}
