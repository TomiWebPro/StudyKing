# VoiceService speech_to_text fails on Linux (no platform implementation)

**Severity:** minor
**Affected area:** Core — VoiceService / speech-to-text on Linux
**Reported by:** user

## Description

The `speech_to_text` package (version `^6.6.2`) does not provide a Linux platform implementation. When the app launches on Linux, `VoiceService._initialize()` creates a `stt.SpeechToText()` instance and calls `_speech!.initialize()`, which throws a `MissingPluginException`. This is caught by the error handler, `_isAvailable` is set to `false`, and a warning is logged: `Failed to check speech availability`. The feature degrades gracefully (voice input is disabled), but the error log is noisy and the initialization is wasted effort.

## Steps to reproduce

1. Run the app on Linux (`flutter run`)
2. Observe the runtime log:
   ```
   [2026-07-03T04:52:49.464915][W][VoiceService] Failed to check speech availability
   Error: MissingPluginException(No implementation found for method initialize on channel plugin.csdcorp.com/speech_to_text)
   ```

## Expected behavior

On Linux (and any other platform without a `speech_to_text` implementation), the `VoiceService` should detect the platform at initialization time and skip all speech-to-text setup without logging a warning. The `isAvailable` property should remain `false` without any error noise.

## Actual behavior

The app always attempts to initialize `speech_to_text` on Linux, which throws a `MissingPluginException`. The warning is logged, and an error is posted to the `_errorController` stream.

## Code analysis

- `lib/core/services/voice_service.dart:32-36` — The constructor only guards against web (`!kIsWeb`), not desktop Linux:
  ```dart
  VoiceService() {
    if (!kIsWeb) {
      _initialize();
    }
  }
  ```

- `lib/core/services/voice_service.dart:38-50` — `_initialize()` creates `stt.SpeechToText()` and calls `_checkAvailability()` regardless of platform:
  ```dart
  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _speech = stt.SpeechToText();
      _tts = FlutterTts();
      await _checkAvailability();
    } catch (e) {
      _logger.w('Failed to initialize voice service', e);
      _isAvailable = false;
    }
  }
  ```

- `lib/core/services/voice_service.dart:52-79` — `_checkAvailability()` calls `_speech!.initialize()` which triggers the `MissingPluginException` on Linux:
  ```dart
  Future<void> _checkAvailability() async {
    try {
      ...
      final available = await _speech!.initialize(
        onError: ...,
        onStatus: ...,
      );
      ...
    } catch (e) {
      _logger.w('Failed to check speech availability', e);
      ...
    }
  }
  ```

- The Linux platform has no `speech_to_text` entry in `linux/flutter/generated_plugins.cmake`, which only registers `file_selector_linux`, `flutter_secure_storage_linux`, `record_linux`, and `url_launcher_linux`.

- The project has no `macos/` or `windows/` directories — Linux is the only desktop target, so this platform gap affects desktop usage entirely.

## Suggested approach

Add a platform check in `_initialize()` to detect Linux (and other unsupported desktop platforms) and skip `speech_to_text` initialization:

```dart
import 'dart:io' show Platform;

Future<void> _initialize() async {
  if (_initialized) return;
  _initialized = true;

  // speech_to_text does not support Linux desktop
  if (!kIsWeb && Platform.isLinux) {
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
```

This cleanly avoids the `MissingPluginException` on Linux while preserving all existing behavior on supported platforms (Android, iOS, web).

An alternative is to use `Platform.isLinux` only (rather than a broader exclusion), since Linux is the project's only desktop target.
