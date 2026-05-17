import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants/app_constants.dart';
import '../utils/number_format_utils.dart';

class NotificationService {
  NotificationService();

  @visibleForTesting
  FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(String?)? _onNotificationTap;
  AppLocalizations? _l10n;

  void setAppLocalizations(AppLocalizations l10n) {
    _l10n = l10n;
  }

  Future<void> init({Function(String?)? onNotificationTap}) async {
    if (_initialized) return;
    _onNotificationTap = onNotificationTap;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createNotificationChannels();

    _initialized = true;
  }

  Future<void> _createNotificationChannels() async {
    final l10n = _l10n;
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final channels = [
      AndroidNotificationChannel(
        NotificationChannelIds.general,
        l10n?.notifChannelGeneral ?? 'StudyKing Notifications',
        description: l10n?.notifChannelGeneralDesc ?? 'General StudyKing notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.dailyReminder,
        l10n?.notifChannelDailyReminder ?? 'Daily Study Reminders',
        description: l10n?.notifChannelDailyReminderDesc ?? 'Daily reminders to study',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.revision,
        l10n?.notifChannelRevision ?? 'Revision Reminders',
        description: l10n?.notifChannelRevisionDesc ?? 'Reminders to review topics',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.wellbeing,
        l10n?.notifChannelWellbeing ?? 'Wellbeing Alerts',
        description: l10n?.notifChannelWellbeingDesc ?? 'Wellbeing and break reminders',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.planning,
        l10n?.notifChannelPlanning ?? 'Planning Suggestions',
        description: l10n?.notifChannelPlanningDesc ?? 'Study plan adjustment suggestions',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.lessons,
        l10n?.notifChannelLessons ?? 'Lesson Notifications',
        description: l10n?.notifChannelLessonsDesc ?? 'Lesson reminders and updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.mastery,
        l10n?.notifChannelMastery ?? 'Mastery Alerts',
        description: l10n?.notifChannelMasteryDesc ?? 'Low mastery topic alerts',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.badges,
        l10n?.notifChannelBadges ?? 'Badge Notifications',
        description: l10n?.notifChannelBadgesDesc ?? 'Badge unlock notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    _onNotificationTap?.call(response.payload);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    final l10n = _l10n;
    final androidDetails = AndroidNotificationDetails(
      channelId ?? NotificationChannelIds.general,
      channelName ?? l10n?.notifChannelGeneral ?? 'StudyKing Notifications',
      channelDescription: l10n?.notifChannelGeneralDesc ?? 'General StudyKing notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay remindAt,
    String? payload,
  }) async {
    final l10n = _l10n;
    final androidDetails = AndroidNotificationDetails(
      NotificationChannelIds.dailyReminder,
      l10n?.notifChannelDailyReminder ?? 'Daily Study Reminders',
      channelDescription: l10n?.notifChannelDailyReminderDesc ?? 'Daily reminders to study',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      remindAt.hour,
      remindAt.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Timeouts.day);
    }

    await plugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showRevisionNudge({
    required int id,
    required String topicName,
    required int daysSinceLastPractice,
  }) async {
    final l10n = _l10n;
    await showNotification(
      id: id,
      title: l10n?.notifTitleTimeToReview ?? 'Time to Review!',
      body: l10n?.notificationTimeToReviewBody(daysSinceLastPractice, topicName)
          ?? 'It\'s been $daysSinceLastPractice days since you practiced "$topicName".',
      payload: 'topic_$topicName',
      channelId: NotificationChannelIds.revision,
      channelName: l10n?.notifChannelRevision ?? 'Revision Reminders',
    );
  }

  Future<void> showOverworkWarning({
    required int id,
    required double hoursStudied,
  }) async {
    final l10n = _l10n;
    final hoursStr = formatDecimal(hoursStudied, _l10n?.localeName ?? 'en', minFractionDigits: 1, maxFractionDigits: 1);
    await showNotification(
      id: id,
      title: l10n?.notifTitleTakeBreak ?? 'Take a Break',
      body: l10n?.notifBodyOverwork(hoursStr)
          ?? 'You\'ve studied $hoursStr hours today. Remember to rest!',
      payload: 'overwork_warning',
      channelId: NotificationChannelIds.wellbeing,
      channelName: l10n?.notifChannelWellbeing ?? 'Wellbeing Alerts',
    );
  }

  Future<void> showPlanAdjustmentSuggestion({
    required int id,
    required int consecutiveLowDays,
  }) async {
    final l10n = _l10n;
    await showNotification(
      id: id,
      title: l10n?.notifTitlePlanAdjustment ?? 'Plan Adjustment',
      body: l10n?.notifBodyPlanAdjustment(consecutiveLowDays)
          ?? 'You\'ve had $consecutiveLowDays days of low adherence. Shall we adjust your plan?',
      payload: 'plan_adjustment',
      channelId: NotificationChannelIds.planning,
      channelName: l10n?.notifChannelPlanning ?? 'Planning Suggestions',
    );
  }

  Future<void> showLessonReminder({
    required int id,
    required String lessonTitle,
    required DateTime startTime,
  }) async {
    final l10n = _l10n;
    final timeStr = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
    await showNotification(
      id: id,
      title: l10n?.notifTitleUpcomingLesson ?? 'Upcoming Lesson',
      body: l10n?.notificationUpcomingLessonBody(lessonTitle, timeStr)
          ?? 'Your lesson "$lessonTitle" starts at $timeStr',
      payload: 'lesson_${startTime.millisecondsSinceEpoch}',
      channelId: NotificationChannelIds.lessons,
      channelName: l10n?.notifChannelLessons ?? 'Lesson Notifications',
    );
  }

  Future<void> showLowMasteryWarning({
    required int id,
    required List<String> weakTopics,
  }) async {
    if (weakTopics.isEmpty) return;
    final l10n = _l10n;
    final topicList = weakTopics.take(3).join(', ');
    final suffix = weakTopics.length > 3 ? ' and ${weakTopics.length - 3} more' : '';
    await showNotification(
      id: id,
      title: l10n?.notifTitleTopicsNeedAttention ?? 'Topics Need Attention',
      body: l10n?.notifBodyLowMastery('$topicList$suffix')
          ?? 'Low mastery detected in: $topicList$suffix',
      payload: 'weak_topics',
      channelId: NotificationChannelIds.mastery,
      channelName: l10n?.notifChannelMastery ?? 'Mastery Alerts',
    );
  }

  Future<void> showBadgeUnlocked({
    required int id,
    required String badgeName,
    required String badgeDescription,
  }) async {
    final l10n = _l10n;
    await showNotification(
      id: id,
      title: l10n?.notifTitleBadgeUnlocked ?? 'Badge Unlocked!',
      body: l10n?.notificationBadgeUnlockedBody(badgeName, badgeDescription)
          ?? 'You earned the "$badgeName" badge: $badgeDescription',
      payload: 'badge_$badgeName',
      channelId: NotificationChannelIds.badges,
      channelName: l10n?.notifChannelBadges ?? 'Badge Notifications',
    );
  }

  Future<void> cancelNotification(int id) async {
    await plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }
}
