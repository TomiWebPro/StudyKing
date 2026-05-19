class Timeouts {
  const Timeouts._();

  static const Duration second = Duration(seconds: 1);
  static const Duration ms100 = Duration(milliseconds: 100);
  static const Duration ms500 = Duration(milliseconds: 500);
  static const Duration hour = Duration(hours: 1);
  static const Duration fiveMinutes = Duration(minutes: 5);
  static const Duration thirtyMinutes = Duration(minutes: 30);
  static const Duration day = Duration(days: 1);
  static const Duration week = Duration(days: 7);
  static const Duration apiCall = Duration(seconds: 15);
  static const Duration apiHealthCheck = Duration(seconds: 10);
  // OpenRouter request timeouts by environment
  static const Duration openRouterTimeoutProduction = Duration(seconds: 45);
  static const Duration openRouterTimeoutStaging = Duration(seconds: 90);
  static const Duration openRouterTimeoutDevelopment = Duration(seconds: 60);
  // YouTube request timeouts by environment
  static const Duration youtubeTimeoutDefault = Duration(seconds: 30);
  static const Duration youtubeTimeoutDevelopment = Duration(seconds: 20);

  // Booking horizon for scheduling lessons (90 days out)
  static const Duration bookingHorizon = Duration(days: 90);
  // Default plan span for roadmap target completion (30 days)
  static const Duration defaultPlanSpan = Duration(days: 30);

  // Snackbar display duration for success messages
  static const Duration snackbarSuccess = Duration(seconds: 6);
  // Page route transition duration
  static const Duration routeTransition = Duration(milliseconds: 200);
  // Dashboard animation duration
  static const Duration dashboardAnimation = Duration(milliseconds: 1500);
  // Bar chart animation duration
  static const Duration barChartAnimation = Duration(milliseconds: 300);
  // Animation duration for LLM task manager
  static const Duration animationMedium = Duration(seconds: 4);
  // Voice listen duration (conversational)
  static const Duration voiceListen = Duration(seconds: 60);
  // Voice listen duration (practice answers - shorter for answer input)
  static const Duration voicePracticeListen = Duration(seconds: 15);
  // Voice pause duration
  static const Duration voicePause = Duration(seconds: 3);

  // How recent a session must be to count as "recent" for filtering
  static const Duration recentSessionWindow = Duration(hours: 1);

  // Default session duration for practice sessions
  static const Duration defaultSessionDuration = Duration(hours: 1);

  // Adaptive pace chunk delay for slow pace tutoring (conversation_manager)
  static const Duration adaptiveChunkDelay = Duration(milliseconds: 15);

  // Engagement check interval for idle executor
  static const Duration engagementCheckInterval = Duration(seconds: 30);

  // Settings screen timeouts
  static const Duration settingsBackupTimeout = Duration(seconds: 10);
}
