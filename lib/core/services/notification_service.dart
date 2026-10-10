import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants/app_constants.dart';
import '../errors/result.dart';
import '../utils/logger.dart';

class NotificationService {
  static final _logger = const Logger('NotificationService');

  NotificationService();

  @visibleForTesting
  FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(String?)? _onNotificationTap;
  AppLocalizations? _l10n;

  void setAppLocalizations(AppLocalizations l10n) {
    _l10n = l10n;
  }

  Future<Result<void>> init({Function(String?)? onNotificationTap}) async {
    if (_initialized) return Result.success(null);
    return Result.capture(() async {
      _onNotificationTap = onNotificationTap;

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open',
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      );

      await plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      await _createNotificationChannels();

      _initialized = true;
    }, context: 'NotificationService.init');
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

  Future<Result<void>> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
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
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show notification $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay remindAt,
    String? payload,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
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
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show daily reminder $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showRevisionNudge({
    required int id,
    required String topicName,
    required int daysSinceLastPractice,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
      await showNotification(
        id: id,
        title: l10n.notifTitleTimeToReview,
        body: l10n.notificationTimeToReviewBody(daysSinceLastPractice, topicName),
        payload: 'topic_$topicName',
        channelId: NotificationChannelIds.revision,
        channelName: l10n.notifChannelRevision,
      );
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show revision nudge $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showOverworkWarning({
    required int id,
    required double hoursStudied,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
      await showNotification(
        id: id,
        title: l10n.notifTitleTakeBreak,
        body: l10n.notifBodyOverwork(hoursStudied.toInt()),
        payload: 'overwork_warning',
        channelId: NotificationChannelIds.wellbeing,
        channelName: l10n.notifChannelWellbeing,
      );
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show overwork warning $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showPlanAdjustmentSuggestion({
    required int id,
    required int consecutiveLowDays,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
      await showNotification(
        id: id,
        title: l10n.notifTitlePlanAdjustment,
        body: l10n.notifBodyPlanAdjustment(consecutiveLowDays),
        payload: 'plan_adjustment',
        channelId: NotificationChannelIds.planning,
        channelName: l10n.notifChannelPlanning,
      );
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show plan adjustment suggestion $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showLessonReminder({
    required int id,
    required String lessonTitle,
    required DateTime startTime,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
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
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show lesson reminder $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showLowMasteryWarning({
    required int id,
    required List<String> weakTopics,
  }) async {
    try {
      if (weakTopics.isEmpty) return Result.success(null);
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
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
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show low mastery warning $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showBadgeUnlocked({
    required int id,
    required String badgeName,
    required String badgeDescription,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
      await showNotification(
        id: id,
        title: l10n.notifTitleBadgeUnlocked,
        body: l10n.notificationBadgeUnlockedBody(badgeName, badgeDescription),
        payload: 'badge_$badgeName',
        channelId: NotificationChannelIds.badges,
        channelName: l10n.notifChannelBadges,
      );
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show badge unlocked notification $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showLessonReady({
    required int id,
    required String topicTitle,
    required String lessonId,
  }) async {
    try {
      final l10n = _l10n;
      if (l10n == null) return Result.failure('l10n not initialized');
      await showNotification(
        id: id,
        title: l10n.readyToContinueLearning,
        body: l10n.lessonReadyBody(topicTitle),
        payload: 'lesson_$lessonId',
        channelId: NotificationChannelIds.lessons,
        channelName: l10n.notifChannelLessons,
      );
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show lesson ready notification $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> showMentorMessage({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: 'open_mentor',
        channelId: NotificationChannelIds.mentor,
        channelName: _l10n?.notifChannelMentor ?? 'Mentor Messages',
      );
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to show mentor message $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> cancelNotification(int id) async {
    try {
      await plugin.cancel(id);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to cancel notification $id', e);
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> cancelAll() async {
    try {
      await plugin.cancelAll();
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to cancel all notifications', e);
      return Result.failure(e.toString());
    }
  }
}
