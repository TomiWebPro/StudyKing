import 'app_build_config.dart';
import 'package:studyking/core/errors/exceptions.dart';

class ApiSecrets {
  const ApiSecrets({
    required this.openRouterApiKey,
    required this.googleApiKey,
    required this.whisperApiKey,
  });

  final String openRouterApiKey;
  final String? googleApiKey;
  final String? whisperApiKey;

  factory ApiSecrets.fromRuntime({
    required String openRouterApiKey,
    String? googleApiKey,
    String? whisperApiKey,
  }) {
    if (openRouterApiKey.isEmpty && BuildConfig.environment == AppEnvironment.production) {
      throw AppException(message: 'Missing OPENROUTER_API_KEY in production.', type: ExceptionType.apiKeyMissing);
    }
    return ApiSecrets(
      openRouterApiKey: openRouterApiKey,
      googleApiKey: googleApiKey,
      whisperApiKey: whisperApiKey,
    );
  }

  factory ApiSecrets.fromEnvironment() {
    // TODO(v2.0): implement runtime secret injection (keystore/native layer) over compile-time embedding.
    final openRouter = const String.fromEnvironment('OPENROUTER_API_KEY');
    final google = const String.fromEnvironment('GOOGLE_API_KEY');
    final whisper = const String.fromEnvironment('WHISPER_API_KEY');

    if (openRouter.isEmpty && BuildConfig.environment == AppEnvironment.production) {
      throw AppException(message: 'Missing OPENROUTER_API_KEY in production.', type: ExceptionType.apiKeyMissing);
    }

    return ApiSecrets.fromRuntime(
      openRouterApiKey: openRouter,
      googleApiKey: google.isEmpty ? null : google,
      whisperApiKey: whisper.isEmpty ? null : whisper,
    );
  }
}

class ApiConfig {
  const ApiConfig({
    required this.openRouterBaseUrl,
    required this.openRouterRequestTimeout,
    required this.youtubeBaseUrl,
    required this.youtubeRequestTimeout,
  });

  static const String openRouterBaseUrlString = 'https://openrouter.ai/api/v1';
  static const String ollamaDefaultUrl = 'http://localhost:11434';
  static const String openAIDefaultUrl = 'https://api.openai.com/v1';
  static const String youtubetranscriptBaseUrl = 'https://youtubetranscript.com';
  static const String youtubetranscriptApiUrl = 'https://youtubetranscript.com/api/transcript';
  static const String userAgent = 'Mozilla/5.0 (compatible; StudyKing/1.0)';

  final Uri openRouterBaseUrl;
  final Duration openRouterRequestTimeout;
  final Uri youtubeBaseUrl;
  final Duration youtubeRequestTimeout;

  static final Uri _openRouterBaseUrl = Uri.parse(openRouterBaseUrlString);
  static final Uri _youtubeBaseUrl = Uri.parse('https://www.googleapis.com/youtube/v3');

  factory ApiConfig.forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.production:
        return ApiConfig(
          openRouterBaseUrl: _openRouterBaseUrl,
          openRouterRequestTimeout: const Duration(seconds: 45),
          youtubeBaseUrl: _youtubeBaseUrl,
          youtubeRequestTimeout: const Duration(seconds: 30),
        );
      case AppEnvironment.staging:
        return ApiConfig(
          openRouterBaseUrl: _openRouterBaseUrl,
          openRouterRequestTimeout: const Duration(seconds: 90),
          youtubeBaseUrl: _youtubeBaseUrl,
          youtubeRequestTimeout: const Duration(seconds: 30),
        );
      case AppEnvironment.development:
        return ApiConfig(
          openRouterBaseUrl: _openRouterBaseUrl,
          openRouterRequestTimeout: const Duration(seconds: 60),
          youtubeBaseUrl: _youtubeBaseUrl,
          youtubeRequestTimeout: const Duration(seconds: 20),
        );
    }
  }
}
