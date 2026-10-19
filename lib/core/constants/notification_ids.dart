/// Numeric IDs for scheduled notifications.
///
/// Schedule and cancel paths must agree on the same ID: an alarm
/// registered with one ID cannot be removed with another, so the
/// daily-reminder alarm is registered and cancelled exclusively
/// through [NotificationIds.dailyReminder].
class NotificationIds {
  const NotificationIds._();

  /// ID of the recurring daily-study-reminder alarm.
  static const int dailyReminder = 9999;

  /// Base id for upcoming-lesson one-shot alarms. Derived from the session id
  /// (see `NotificationService.lessonNotificationId`) so the same lesson alarm
  /// can be cancelled/rescheduled consistently. Kept well above the scheduler's
  /// rolling `_notificationIdCounter` (1000+) and the daily-reminder id (9999)
  /// to avoid id collisions with recurring nudges.
  static const int lessonReminderBase = 1000000;
}
