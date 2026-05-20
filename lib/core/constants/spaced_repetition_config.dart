/// Default and configurable parameters for the SM-2 spaced repetition system.
class SrConfig {
  SrConfig._();

  /// Minimum ease factor for the SM-2 algorithm (clamped in engine).
  static const double defaultMinEaseFactor = 1.3;

  /// Maximum ease factor for the SM-2 algorithm.
  static const double defaultMaxEaseFactor = 5.0;

  /// Default ease factor for new questions.
  static const double defaultEaseFactor = 2.5;

  /// Initial interval for a first-time correct review (days).
  static const int defaultInitialIntervalDays = 1;

  /// Interval for a second consecutive correct review (days).
  static const int defaultSecondIntervalDays = 6;

  /// Default minimum interval in days (clamped by settings).
  static const int defaultMinIntervalDays = 1;

  /// Default maximum interval in days (clamped by settings).
  static const int defaultMaxIntervalDays = 365;

  /// Default daily review limit (0 = unlimited).
  static const int defaultDailyReviewLimit = 0;

  /// Hive settings box keys for SR configuration.
  static const String keyMinIntervalDays = 'srMinIntervalDays';
  static const String keyMaxIntervalDays = 'srMaxIntervalDays';
  static const String keyDailyReviewLimit = 'srDailyReviewLimit';
  static const String keyMinEaseFactor = 'srMinEaseFactor';
}
