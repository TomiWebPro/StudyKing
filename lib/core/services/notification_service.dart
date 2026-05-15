import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../l10n/generated/app_localizations.dart';
import 'localization_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(String?)? _onNotificationTap;
  LocalizationService? _localizationService;

  void setLocalizationService(LocalizationService localizationService) {
    _localizationService = localizationService;
  }

  AppLocalizations? get _l10n => _localizationService?.l10n;

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

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
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
      channelId ?? 'studyking_general',
      channelName ?? l10n?.notificationChannelGeneralName ?? 'StudyKing Notifications',
      channelDescription: l10n?.notificationChannelGeneralDesc ?? 'General StudyKing notifications',
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

    await _plugin.show(id, title, body, details, payload: payload);
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
      'studyking_daily_reminder',
      l10n?.notificationChannelDailyReminderName ?? 'Daily Study Reminders',
      channelDescription: l10n?.notificationChannelDailyReminderDesc ?? 'Daily reminders to study',
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
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.periodicallyShow(
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
      title: l10n?.notificationTimeToReviewTitle ?? 'Time to Review!',
      body: l10n?.notificationTimeToReviewBody(daysSinceLastPractice, topicName)
          ?? 'It\'s been $daysSinceLastPractice days since you practiced "$topicName".',
      payload: 'topic_$topicName',
      channelId: 'studyking_revision',
      channelName: l10n?.notificationChannelRevisionName ?? 'Revision Reminders',
    );
  }

  Future<void> showOverworkWarning({
    required int id,
    required double hoursStudied,
  }) async {
    final l10n = _l10n;
    final hoursStr = hoursStudied.toStringAsFixed(1);
    await showNotification(
      id: id,
      title: l10n?.notificationTakeABreakTitle ?? 'Take a Break',
      body: l10n?.notificationTakeABreakBody(hoursStr)
          ?? 'You\'ve studied $hoursStr hours today. Remember to rest!',
      payload: 'overwork_warning',
      channelId: 'studyking_wellbeing',
      channelName: l10n?.notificationChannelWellbeingName ?? 'Wellbeing Alerts',
    );
  }

  Future<void> showPlanAdjustmentSuggestion({
    required int id,
    required int consecutiveLowDays,
  }) async {
    final l10n = _l10n;
    await showNotification(
      id: id,
      title: l10n?.notificationPlanAdjustmentTitle ?? 'Plan Adjustment',
      body: l10n?.notificationPlanAdjustmentBody(consecutiveLowDays)
          ?? 'You\'ve had $consecutiveLowDays days of low adherence. Shall we adjust your plan?',
      payload: 'plan_adjustment',
      channelId: 'studyking_planning',
      channelName: l10n?.notificationChannelPlanningName ?? 'Planning Suggestions',
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
      title: l10n?.notificationUpcomingLessonTitle ?? 'Upcoming Lesson',
      body: l10n?.notificationUpcomingLessonBody(lessonTitle, timeStr)
          ?? 'Your lesson "$lessonTitle" starts at $timeStr',
      payload: 'lesson_${startTime.millisecondsSinceEpoch}',
      channelId: 'studyking_lessons',
      channelName: l10n?.notificationChannelLessonsName ?? 'Lesson Notifications',
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
      title: l10n?.notificationTopicsNeedAttentionTitle ?? 'Topics Need Attention',
      body: l10n?.notificationTopicsNeedAttentionBody('$topicList$suffix')
          ?? 'Low mastery detected in: $topicList$suffix',
      payload: 'weak_topics',
      channelId: 'studyking_mastery',
      channelName: l10n?.notificationChannelMasteryName ?? 'Mastery Alerts',
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
      title: l10n?.notificationBadgeUnlockedTitle ?? 'Badge Unlocked!',
      body: l10n?.notificationBadgeUnlockedBody(badgeName, badgeDescription)
          ?? 'You earned the "$badgeName" badge: $badgeDescription',
      payload: 'badge_$badgeName',
      channelId: 'studyking_badges',
      channelName: l10n?.notificationChannelBadgesName ?? 'Badge Notifications',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
