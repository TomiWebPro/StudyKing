import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/voice_service.dart';

void main() {
  group('VoiceService', () {
    late VoiceService service;

    setUp(() {
      service = VoiceService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not listening and not speaking', () {
      expect(service.isListening, isFalse);
      expect(service.isSpeaking, isFalse);
      expect(service.isAvailable, isFalse);
    });

    test('startListening does nothing when not available', () async {
      await service.startListening();
      expect(service.isListening, isFalse);
    });

    test('stopListening does nothing when not listening', () async {
      await service.stopListening();
      expect(service.isListening, isFalse);
    });

    test('speak completes without error when not available', () async {
      await service.speak('Hello');
      expect(service.isSpeaking, isFalse);
    });

    test('stopSpeaking does nothing', () async {
      await service.stopSpeaking();
      expect(service.isSpeaking, isFalse);
    });

    test('transcribedText stream is available', () {
      expect(service.transcribedText, isA<Stream<String>>());
    });

    test('listeningState stream is available', () {
      expect(service.listeningState, isA<Stream<bool>>());
    });

    test('requestPermission returns false in test environment', () async {
      final granted = await service.requestPermission();
      expect(granted, isFalse);
    });

    test('dispose can be called without error', () {
      service.dispose();
      expect(service.isListening, isFalse);
      expect(service.isSpeaking, isFalse);
    });

    test('multiple dispose calls do not throw', () {
      service.dispose();
      service.dispose();
    });

    test('startListening accepts localeName parameter', () async {
      await service.startListening(localeName: 'es');
      expect(service.isListening, isFalse);
    });

    test('speak accepts localeName parameter', () async {
      await service.speak('Hola', localeName: 'es');
      expect(service.isSpeaking, isFalse);
    });
  });
}
