import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(String?)? _onNotificationTap;

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
    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'studyking_general',
      channelName ?? 'StudyKing Notifications',
      channelDescription: 'General StudyKing notifications',
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
    final androidDetails = AndroidNotificationDetails(
      'studyking_daily_reminder',
      'Daily Study Reminders',
      channelDescription: 'Daily reminders to study',
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
    await showNotification(
      id: id,
      title: 'Time to Review!',
      body: 'It\'s been $daysSinceLastPractice days since you practiced "$topicName".',
      payload: 'topic_$topicName',
      channelId: 'studyking_revision',
      channelName: 'Revision Reminders',
    );
  }

  Future<void> showOverworkWarning({
    required int id,
    required double hoursStudied,
  }) async {
    await showNotification(
      id: id,
      title: 'Take a Break',
      body: 'You\'ve studied ${hoursStudied.toStringAsFixed(1)} hours today. Remember to rest!',
      payload: 'overwork_warning',
      channelId: 'studyking_wellbeing',
      channelName: 'Wellbeing Alerts',
    );
  }

  Future<void> showPlanAdjustmentSuggestion({
    required int id,
    required int consecutiveLowDays,
  }) async {
    await showNotification(
      id: id,
      title: 'Plan Adjustment',
      body: 'You\'ve had $consecutiveLowDays days of low adherence. Shall we adjust your plan?',
      payload: 'plan_adjustment',
      channelId: 'studyking_planning',
      channelName: 'Planning Suggestions',
    );
  }

  Future<void> showLessonReminder({
    required int id,
    required String lessonTitle,
    required DateTime startTime,
  }) async {
    await showNotification(
      id: id,
      title: 'Upcoming Lesson',
      body: 'Your lesson "$lessonTitle" starts at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
      payload: 'lesson_${startTime.millisecondsSinceEpoch}',
      channelId: 'studyking_lessons',
      channelName: 'Lesson Notifications',
    );
  }

  Future<void> showLowMasteryWarning({
    required int id,
    required List<String> weakTopics,
  }) async {
    if (weakTopics.isEmpty) return;
    final topicList = weakTopics.take(3).join(', ');
    final suffix = weakTopics.length > 3 ? ' and ${weakTopics.length - 3} more' : '';
    await showNotification(
      id: id,
      title: 'Topics Need Attention',
      body: 'Low mastery detected in: $topicList$suffix',
      payload: 'weak_topics',
      channelId: 'studyking_mastery',
      channelName: 'Mastery Alerts',
    );
  }

  Future<void> showBadgeUnlocked({
    required int id,
    required String badgeName,
    required String badgeDescription,
  }) async {
    await showNotification(
      id: id,
      title: 'Badge Unlocked!',
      body: 'You earned the "$badgeName" badge: $badgeDescription',
      payload: 'badge_$badgeName',
      channelId: 'studyking_badges',
      channelName: 'Badge Notifications',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
