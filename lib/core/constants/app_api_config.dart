import 'app_build_config.dart';
import 'timeouts.dart';
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
    // Runtime secrets: for production, inject via platform channels (keystore/native layer).
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

  static String get _ollamaUrlFromEnv => const String.fromEnvironment('OLLAMA_BASE_URL');
  static String get _openAIUrlFromEnv => const String.fromEnvironment('OPENAI_BASE_URL');

  static String get ollamaDefaultUrl =>
      _ollamaUrlFromEnv.isNotEmpty ? _ollamaUrlFromEnv : 'http://localhost:11434';
  static String get openAIDefaultUrl =>
      _openAIUrlFromEnv.isNotEmpty ? _openAIUrlFromEnv : 'https://api.openai.com/v1';
  static const String youtubetranscriptBaseUrl = 'https://youtubetranscript.com';
  static const String youtubetranscriptApiUrl = 'https://youtubetranscript.com/api/transcript';
  static const String userAgent = 'Mozilla/5.0 (compatible; StudyKing/1.0)';
  static const String bearerAuth = 'Bearer ';

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
          openRouterRequestTimeout: Timeouts.openRouterTimeoutProduction,
          youtubeBaseUrl: _youtubeBaseUrl,
          youtubeRequestTimeout: Timeouts.youtubeTimeoutDefault,
        );
      case AppEnvironment.staging:
        return ApiConfig(
          openRouterBaseUrl: _openRouterBaseUrl,
          openRouterRequestTimeout: Timeouts.openRouterTimeoutStaging,
          youtubeBaseUrl: _youtubeBaseUrl,
          youtubeRequestTimeout: Timeouts.youtubeTimeoutDefault,
        );
      case AppEnvironment.development:
        return ApiConfig(
          openRouterBaseUrl: _openRouterBaseUrl,
          openRouterRequestTimeout: Timeouts.openRouterTimeoutDevelopment,
          youtubeBaseUrl: _youtubeBaseUrl,
          youtubeRequestTimeout: Timeouts.youtubeTimeoutDevelopment,
        );
    }
  }
}
