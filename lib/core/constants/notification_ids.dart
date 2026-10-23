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

  /// ID of the weekly accountability digest notification. A fixed ID (rather
  /// than the scheduler's rolling `_notificationIdCounter`) lets a later week's
  /// digest replace the previous one instead of stacking stale copies in the
  /// notification shade.
  static const int weeklyDigest = 9998;

  /// Base id for upcoming-lesson one-shot alarms. Derived from the session id
  /// (see `NotificationService.lessonNotificationId`) so the same lesson alarm
  /// can be cancelled/rescheduled consistently. Kept well above the scheduler's
  /// rolling `_notificationIdCounter` (1000+) and the daily-reminder id (9999)
  /// to avoid id collisions with recurring nudges.
  static const int lessonReminderBase = 1000000;

  /// Base id for "lesson ready" notifications. Derived from the lesson id
  /// (see `NotificationService.lessonReadyNotificationId`) so a re-run of
  /// prep for the same lesson replaces — rather than stacks — the previous
  /// notification (Vision Next-Term §4.1 prep-to-live handoff).
  static const int lessonReadyBase = 2000000;
}
