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
}
