import 'app_build_config.dart';

class ApiSecrets {
  const ApiSecrets({
    required this.openRouterApiKey,
    required this.googleApiKey,
    required this.whisperApiKey,
  });

  final String openRouterApiKey;
  final String? googleApiKey;
  final String? whisperApiKey;

  factory ApiSecrets.fromEnvironment() {
    final openRouter = const String.fromEnvironment('OPENROUTER_API_KEY');
    final google = const String.fromEnvironment('GOOGLE_API_KEY');
    final whisper = const String.fromEnvironment('WHISPER_API_KEY');

    if (openRouter.isEmpty && BuildConfig.environment == AppEnvironment.production) {
      throw StateError('Missing OPENROUTER_API_KEY in production.');
    }

    return ApiSecrets(
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

  final Uri openRouterBaseUrl;
  final Duration openRouterRequestTimeout;
  final Uri youtubeBaseUrl;
  final Duration youtubeRequestTimeout;

  factory ApiConfig.forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.production:
        return ApiConfig(
          openRouterBaseUrl: Uri.parse('https://openrouter.ai/api/v1'),
          openRouterRequestTimeout: const Duration(seconds: 120),
          youtubeBaseUrl: Uri.parse('https://www.googleapis.com/youtube/v3'),
          youtubeRequestTimeout: const Duration(seconds: 30),
        );
      case AppEnvironment.staging:
        return ApiConfig(
          openRouterBaseUrl: Uri.parse('https://openrouter.ai/api/v1'),
          openRouterRequestTimeout: const Duration(seconds: 90),
          youtubeBaseUrl: Uri.parse('https://www.googleapis.com/youtube/v3'),
          youtubeRequestTimeout: const Duration(seconds: 30),
        );
      case AppEnvironment.development:
        return ApiConfig(
          openRouterBaseUrl: Uri.parse('https://openrouter.ai/api/v1'),
          openRouterRequestTimeout: const Duration(seconds: 60),
          youtubeBaseUrl: Uri.parse('https://www.googleapis.com/youtube/v3'),
          youtubeRequestTimeout: const Duration(seconds: 20),
        );
    }
  }
}
