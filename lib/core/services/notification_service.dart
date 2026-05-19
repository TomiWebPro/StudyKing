import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants/app_constants.dart';

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
    if (l10n == null) return;
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final channels = [
      AndroidNotificationChannel(
        NotificationChannelIds.general,
        l10n.notifChannelGeneral,
        description: l10n.notifChannelGeneralDesc,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.dailyReminder,
        l10n.notifChannelDailyReminder,
        description: l10n.notifChannelDailyReminderDesc,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.revision,
        l10n.notifChannelRevision,
        description: l10n.notifChannelRevisionDesc,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.wellbeing,
        l10n.notifChannelWellbeing,
        description: l10n.notifChannelWellbeingDesc,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.planning,
        l10n.notifChannelPlanning,
        description: l10n.notifChannelPlanningDesc,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.lessons,
        l10n.notifChannelLessons,
        description: l10n.notifChannelLessonsDesc,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.mastery,
        l10n.notifChannelMastery,
        description: l10n.notifChannelMasteryDesc,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.badges,
        l10n.notifChannelBadges,
        description: l10n.notifChannelBadgesDesc,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelIds.mentor,
        l10n.notifChannelMentor,
        description: l10n.notifChannelMentorDesc,
        importance: Importance.high,
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
    if (l10n == null) return;
    final androidDetails = AndroidNotificationDetails(
      channelId ?? NotificationChannelIds.general,
      channelName ?? l10n.notifChannelGeneral,
      channelDescription: l10n.notifChannelGeneralDesc,
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
    if (l10n == null) return;
    final androidDetails = AndroidNotificationDetails(
      NotificationChannelIds.dailyReminder,
      l10n.notifChannelDailyReminder,
      channelDescription: l10n.notifChannelDailyReminderDesc,
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
    if (l10n == null) return;
    await showNotification(
      id: id,
      title: l10n.notifTitleTimeToReview,
      body: l10n.notificationTimeToReviewBody(daysSinceLastPractice, topicName),
      payload: 'topic_$topicName',
      channelId: NotificationChannelIds.revision,
      channelName: l10n.notifChannelRevision,
    );
  }

  Future<void> showOverworkWarning({
    required int id,
    required double hoursStudied,
  }) async {
    final l10n = _l10n;
    if (l10n == null) return;
    await showNotification(
      id: id,
      title: l10n.notifTitleTakeBreak,
      body: l10n.notifBodyOverwork(hoursStudied.toInt()),
      payload: 'overwork_warning',
      channelId: NotificationChannelIds.wellbeing,
      channelName: l10n.notifChannelWellbeing,
    );
  }

  Future<void> showPlanAdjustmentSuggestion({
    required int id,
    required int consecutiveLowDays,
  }) async {
    final l10n = _l10n;
    if (l10n == null) return;
    await showNotification(
      id: id,
      title: l10n.notifTitlePlanAdjustment,
      body: l10n.notifBodyPlanAdjustment(consecutiveLowDays),
      payload: 'plan_adjustment',
      channelId: NotificationChannelIds.planning,
      channelName: l10n.notifChannelPlanning,
    );
  }

  Future<void> showLessonReminder({
    required int id,
    required String lessonTitle,
    required DateTime startTime,
  }) async {
    final l10n = _l10n;
    if (l10n == null) return;
    final localeName = l10n.localeName;
    final timeStr = DateFormat.jm(localeName).format(startTime);
    await showNotification(
      id: id,
      title: l10n.notifTitleUpcomingLesson,
      body: l10n.notificationUpcomingLessonBody(lessonTitle, timeStr),
      payload: 'lesson_${startTime.millisecondsSinceEpoch}',
      channelId: NotificationChannelIds.lessons,
      channelName: l10n.notifChannelLessons,
    );
  }

  Future<void> showLowMasteryWarning({
    required int id,
    required List<String> weakTopics,
  }) async {
    if (weakTopics.isEmpty) return;
    final l10n = _l10n;
    if (l10n == null) return;
    final topicList = weakTopics.take(3).join(', ');
    final suffix = weakTopics.length > 3 ? ' and ${weakTopics.length - 3} more' : '';
    await showNotification(
      id: id,
      title: l10n.notifTitleTopicsNeedAttention,
      body: l10n.notifBodyLowMastery('$topicList$suffix'),
      payload: 'weak_topics',
      channelId: NotificationChannelIds.mastery,
      channelName: l10n.notifChannelMastery,
    );
  }

  Future<void> showBadgeUnlocked({
    required int id,
    required String badgeName,
    required String badgeDescription,
  }) async {
    final l10n = _l10n;
    if (l10n == null) return;
    await showNotification(
      id: id,
      title: l10n.notifTitleBadgeUnlocked,
      body: l10n.notificationBadgeUnlockedBody(badgeName, badgeDescription),
      payload: 'badge_$badgeName',
      channelId: NotificationChannelIds.badges,
      channelName: l10n.notifChannelBadges,
    );
  }

  Future<void> showLessonReady({
    required int id,
    required String topicTitle,
    required String lessonId,
  }) async {
    final l10n = _l10n;
    if (l10n == null) return;
    await showNotification(
      id: id,
      title: l10n.readyToContinueLearning,
      body: l10n.lessonReadyBody(topicTitle),
      payload: 'lesson_$lessonId',
      channelId: NotificationChannelIds.lessons,
      channelName: l10n.notifChannelLessons,
    );
  }

  Future<void> showMentorMessage({
    required int id,
    required String title,
    required String body,
  }) async {
    await showNotification(
      id: id,
      title: title,
      body: body,
      payload: 'open_mentor',
      channelId: NotificationChannelIds.mentor,
      channelName: _l10n?.notifChannelMentor ?? 'Mentor Messages',
    );
  }

  Future<void> cancelNotification(int id) async {
    await plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }
}
