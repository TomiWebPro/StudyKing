import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/teaching/services/voice_controller.dart';

void main() {
  group('VoiceController', () {
    late VoiceController controller;

    setUp(() {
      controller = VoiceController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is not listening and not speaking', () {
      expect(controller.isListening, isFalse);
      expect(controller.isSpeaking, isFalse);
      expect(controller.isAvailable, isFalse);
    });

    test('startListening does nothing when not available', () async {
      await controller.startListening();
      expect(controller.isListening, isFalse);
    });

    test('stopListening does nothing when not listening', () async {
      await controller.stopListening();
      expect(controller.isListening, isFalse);
    });

    test('speak completes without error when not available', () async {
      await controller.speak('Hello');
      expect(controller.isSpeaking, isFalse);
    });

    test('stopSpeaking does nothing', () async {
      await controller.stopSpeaking();
      expect(controller.isSpeaking, isFalse);
    });

    test('transcribedText stream is available', () {
      expect(controller.transcribedText, isA<Stream<String>>());
    });

    test('listeningState stream is available', () {
      expect(controller.listeningState, isA<Stream<bool>>());
    });

    test('requestPermission returns false in test environment', () async {
      final granted = await controller.requestPermission();
      expect(granted, isFalse);
    });

    test('dispose can be called without error', () {
      controller.dispose();
      expect(controller.isListening, isFalse);
      expect(controller.isSpeaking, isFalse);
    });

    test('multiple dispose calls do not throw', () {
      controller.dispose();
      controller.dispose();
    });

    test('startListening accepts localeName parameter', () async {
      await controller.startListening(localeName: 'es');
      expect(controller.isListening, isFalse);
    });

    test('speak accepts localeName parameter', () async {
      await controller.speak('Hola', localeName: 'es');
      expect(controller.isSpeaking, isFalse);
    });
  });
}
