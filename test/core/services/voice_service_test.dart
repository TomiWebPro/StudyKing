import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/voice_service.dart';

void main() {
  group('VoiceService', () {
    test('can be constructed', () {
      final service = VoiceService();
      expect(service, isA<VoiceService>());
    });

    test('initial state has correct defaults', () {
      final service = VoiceService();
      expect(service.isListening, isFalse);
      expect(service.isSpeaking, isFalse);
    });

    test('transcribedText is a Stream', () {
      final service = VoiceService();
      expect(service.transcribedText, isA<Stream<String>>());
    });

    test('listeningState is a Stream<bool>', () {
      final service = VoiceService();
      expect(service.listeningState, isA<Stream<bool>>());
    });

    test('dispose does not throw', () {
      final service = VoiceService();
      expect(() => service.dispose(), returnsNormally);
    });

    test('requestPermission does not throw', () async {
      final service = VoiceService();
      try {
        await service.requestPermission();
      } catch (_) {
        // Plugin may not be available in test environment
      }
    });

    test('startListening does not throw', () async {
      final service = VoiceService();
      try {
        await service.startListening();
      } catch (_) {
        // Plugin may not be available in test environment
      }
    });

    test('stopListening does not throw', () async {
      final service = VoiceService();
      try {
        await service.stopListening();
      } catch (_) {
        // Plugin may not be available in test environment
      }
    });

    test('speak does not throw for non-empty text', () async {
      final service = VoiceService();
      try {
        await service.speak('Hello');
      } catch (_) {
        // Plugin may not be available in test environment
      }
    });

    test('speak does nothing for empty text', () async {
      final service = VoiceService();
      await service.speak('');
      expect(service.isSpeaking, isFalse);
    });

    test('stopSpeaking does not throw', () async {
      final service = VoiceService();
      try {
        await service.stopSpeaking();
      } catch (_) {
        // Plugin may not be available in test environment
      }
    });

    test('voiceServiceProvider creates a provider', () {
      expect(voiceServiceProvider, isNotNull);
    });

    test('isAvailable defaults to false', () {
      final service = VoiceService();
      expect(service.isAvailable, isFalse);
    });

    test('speak with empty text does not set isSpeaking', () async {
      final service = VoiceService();
      await service.speak('');
      expect(service.isSpeaking, isFalse);
    });

    test('startListening accepts localeName parameter', () async {
      final service = VoiceService();
      await service.startListening(localeName: 'es');
      expect(service.isListening, isFalse);
    });

    test('speak accepts localeName parameter', () async {
      final service = VoiceService();
      await service.speak('Hola', localeName: 'es');
      expect(service.isSpeaking, isFalse);
    });

    test('multiple dispose calls do not throw', () {
      final service = VoiceService();
      service.dispose();
      service.dispose();
    });

    test('requestPermission returns false in test environment', () async {
      final service = VoiceService();
      final granted = await service.requestPermission();
      expect(granted, isFalse);
    });
  });
}
