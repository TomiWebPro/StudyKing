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
  // Voice listen duration
  static const Duration voiceListen = Duration(seconds: 60);
  // Voice pause duration
  static const Duration voicePause = Duration(seconds: 3);
}
