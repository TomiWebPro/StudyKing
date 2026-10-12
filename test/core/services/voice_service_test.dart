import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, StandardMethodCodec;
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(service.requestPermission(), completion(isFalse));
    });

    test('startListening does not throw', () async {
      final service = VoiceService();
      expect(service.startListening(), completes);
    });

    test('stopListening does not throw', () async {
      final service = VoiceService();
      expect(service.stopListening(), completes);
    });

    test('speak does not throw for non-empty text', () async {
      final service = VoiceService();
      expect(service.speak('Hello'), completes);
    });

    test('speak does nothing for empty text', () async {
      final service = VoiceService();
      await service.speak('');
      expect(service.isSpeaking, isFalse);
    });

    test('stopSpeaking does not throw', () async {
      final service = VoiceService();
      expect(service.stopSpeaking(), completes);
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

    test('initialization is skipped and isAvailable is false on Linux', () async {
      final service = VoiceService(platform: TargetPlatform.linux);
      expect(service.isAvailable, isFalse);
      expect(service.isListening, isFalse);
      expect(service.isSpeaking, isFalse);
      expect(service.startListening(), completes);
      expect(service.requestPermission(), completion(isFalse));
    });

    test('initialization is skipped and isAvailable is false on Windows', () async {
      final service = VoiceService(platform: TargetPlatform.windows);
      expect(service.isAvailable, isFalse);
    });

    test('initialization is attempted on supported platforms', () {
      final service = VoiceService(platform: TargetPlatform.android);
      expect(service, isA<VoiceService>());
    });

    group('speech recognition event wiring (platform channel)', () {
      const MethodChannel sttChannel =
          MethodChannel('plugin.csdcorp.com/speech_to_text');

      void mockStt(Future<dynamic> Function(MethodCall call) handler) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(sttChannel, handler);
      }

      Future<void> simulateSttEvent(String method, [String? arguments]) {
        return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          sttChannel.name,
          const StandardMethodCodec()
              .encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );
      }

      Future<void> settle() async {
        // Let constructor-triggered async initialization and
        // broadcast stream deliveries run to completion.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(sttChannel, null);
      });

      test('requestPermission keeps recognition status and error listeners wired',
          () async {
        // The first initialization attempt fails (e.g. recognition not
        // available yet). speech_to_text only re-registers its listeners
        // when initialize() runs while the first attempt failed, so this
        // is exactly the state where a bare initialize() call - like the
        // one requestPermission used to make - would wipe the
        // status/error listeners and silently drop all later events.
        var initializeSucceeds = false;
        mockStt((call) async {
          switch (call.method) {
            case 'initialize':
              return initializeSucceeds;
            case 'listen':
              return true;
            case 'stop':
              return null;
            default:
              return null;
          }
        });

        final service = VoiceService(platform: TargetPlatform.android);
        addTearDown(service.dispose);
        await settle();
        expect(service.isAvailable, isFalse);

        // Permission is granted and the retried initialization works.
        initializeSucceeds = true;
        expect(await service.requestPermission(), isTrue);
        expect(service.isAvailable, isTrue);

        final states = <bool>[];
        final errors = <String?>[];
        service.listeningState.listen(states.add);
        service.lastError.listen(errors.add);

        final started = await service.startListening();
        expect(started.isSuccess, isTrue);
        expect(service.isListening, isTrue);

        // Recognition ends: the plugin pushes a "notListening" status
        // event, which must reset the listening state.
        await simulateSttEvent('notifyStatus', 'notListening');
        await settle();
        expect(states, [true, false]);
        expect(service.isListening, isFalse);

        // A recognition error must still reach the error stream.
        await simulateSttEvent(
          'notifyError',
          '{"errorMsg": "error_audio", "permanent": false}',
        );
        await settle();
        expect(errors, contains('Speech recognition error'));
        expect(service.isAvailable, isFalse);
      });

      test('dispose drops late recognition events instead of crashing closed streams',
          () async {
        mockStt((call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'listen':
              return true;
            case 'stop':
              return null;
            default:
              return null;
          }
        });

        final service = VoiceService(platform: TargetPlatform.android);
        await settle();
        expect(service.isAvailable, isTrue);

        final started = await service.startListening();
        expect(started.isSuccess, isTrue);
        expect(service.isListening, isTrue);

        service.dispose();
        // Let the in-flight stop() settle: its final status handling
        // must not add to the closed streams.
        await settle();

        // A late plugin status event after dispose must be dropped
        // instead of throwing "Cannot add event after closing".
        await simulateSttEvent('notifyStatus', 'notListening');
        await settle();
        expect(service.isListening, isFalse);
      });
    });
  });
}
