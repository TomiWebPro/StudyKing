/// Application constants and configuration
/// 
/// This file centralizes all configuration values, including:
/// - API keys and credentials
/// - App version and metadata
/// - Feature flags
/// - Default values

class AppConstants {
  // Application metadata
  static const String appName = 'StudyKing';
  static const String appVersion = '0.1.0';
  static const String appBuildNumber = '001';

  // API Keys (These should be loaded from secure storage or environment variables)
  // Currently hardcoded for development, replace with runtime configuration
  static String? openRouterApiKey;
  static String? googleApiKey;
  static String? whisperApiKey;

  // Configuration
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const int openRouterRequestTimeout = 120; // seconds
  // Models are fetched dynamically from API - no hardcoded models
  
  // YouTube API Configuration
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const int youtubeRequestTimeout = 30; // seconds

  // Database Configuration
  static const String databaseName = 'studyking.db';
  static const String hiveBoxName = 'studyking_storage';

  // Feature Flags
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  static const bool enableBetaFeatures = false;

  // Default Values
  static const int defaultQuestionsPerSession = 10;
  static const int maxQuestionsPerSession = 50;
  static const int minScoreForMastery = 80; // percentage
  static const int maxRetryAttempts = 3;

  // Theme Configuration
  static const String themeMode = 'system'; // system, light, dark
  static const bool useDarkTheme = true;

  // Study Settings
  static const int defaultStudySessionDuration = 45; // minutes
  static const int defaultBreakDuration = 10; // minutes
  static const int maxDailyStudyHours = 8;

  // Notification Settings
  static const bool defaultNotificationsEnabled = true;
  static const int notificationReminderTime = 10; // minutes before session
  static const String notificationChannelId = 'study_reminders';
  static const String notificationChannelName = 'Study Reminders';

  // PDF Processing
  static const int maxPdfPagesForSingleLoad = 50;
  static const int defaultPdfChunkSize = 10000; // bytes
  static const int pdfChunkOverlap = 500; // bytes

  // File Paths
  static const String defaultStoragePath = '/storage/emulated/0/Documents/StudyKing';
  static const String tempDirectory = 'temp';
  static const String cacheDirectory = 'cache';

  // Error Messages
  static const String defaultErrorMessage = 'An unexpected error occurred';
  static const String networkErrorMessage = 'Network connection failed';
  static const String authErrorMessage = 'Authentication failed';

  // Cache Configuration
  static const int cacheExpirationHours = 24;
  static const int maxCacheSizeMb = 100;

  // Performance Settings
  static const bool enablePerformanceOptimization = true;
  static const int imageCompressionQuality = 80; // 0-100
  static const int databaseCacheSize = 100; // MB

  // Privacy & Security
  static const bool requireAuthentication = false; // For future implementation
  static const int sessionTimeoutMinutes = 30;
  static const String encryptionKey = 'studyking_default_encryption_key'; // Change in production!
}
