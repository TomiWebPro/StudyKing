import 'package:flutter/material.dart';

class SettingsUpdate {
  final String? apiKey;
  final String? apiBaseUrl;
  final String? selectedModel;
  final ThemeMode? themeMode;
  final double? fontSize;
  final bool? studyRemindersEnabled;
  final int? requestTimeoutSeconds;
  final int? sessionDurationMinutes;
  final bool? highContrastEnabled;
  final bool? largeTouchTargets;
  final bool? reduceMotion;
  final bool? revisionRemindersEnabled;
  final bool? lessonNotificationsEnabled;
  final bool? overworkAlertsEnabled;
  final bool? planAdjustmentNotificationsEnabled;
  final int? breakDurationSeconds;
  final int? dailyReminderHour;
  final int? dailyReminderMinute;
  final bool? firstFocusVisit;
  final bool? dailyReminderEnabled;
  final String? llmProviderName;
  final int? lastConnectionTestMs;
  final String? lastLlmError;

  const SettingsUpdate({
    this.apiKey,
    this.apiBaseUrl,
    this.selectedModel,
    this.themeMode,
    this.fontSize,
    this.studyRemindersEnabled,
    this.requestTimeoutSeconds,
    this.sessionDurationMinutes,
    this.highContrastEnabled,
    this.largeTouchTargets,
    this.reduceMotion,
    this.revisionRemindersEnabled,
    this.lessonNotificationsEnabled,
    this.overworkAlertsEnabled,
    this.planAdjustmentNotificationsEnabled,
    this.breakDurationSeconds,
    this.dailyReminderHour,
    this.dailyReminderMinute,
    this.firstFocusVisit,
    this.dailyReminderEnabled,
    this.llmProviderName,
    this.lastConnectionTestMs,
    this.lastLlmError,
  });

  SettingsUpdate copyWith({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
    bool? reduceMotion,
    bool? revisionRemindersEnabled,
    bool? lessonNotificationsEnabled,
    bool? overworkAlertsEnabled,
    bool? planAdjustmentNotificationsEnabled,
    int? breakDurationSeconds,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? firstFocusVisit,
    bool? dailyReminderEnabled,
    String? llmProviderName,
    int? lastConnectionTestMs,
    String? lastLlmError,
  }) {
    return SettingsUpdate(
      apiKey: apiKey ?? this.apiKey,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      selectedModel: selectedModel ?? this.selectedModel,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      studyRemindersEnabled: studyRemindersEnabled ?? this.studyRemindersEnabled,
      requestTimeoutSeconds: requestTimeoutSeconds ?? this.requestTimeoutSeconds,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      largeTouchTargets: largeTouchTargets ?? this.largeTouchTargets,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      revisionRemindersEnabled: revisionRemindersEnabled ?? this.revisionRemindersEnabled,
      lessonNotificationsEnabled: lessonNotificationsEnabled ?? this.lessonNotificationsEnabled,
      overworkAlertsEnabled: overworkAlertsEnabled ?? this.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: planAdjustmentNotificationsEnabled ?? this.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: breakDurationSeconds ?? this.breakDurationSeconds,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      firstFocusVisit: firstFocusVisit ?? this.firstFocusVisit,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      llmProviderName: llmProviderName ?? this.llmProviderName,
      lastConnectionTestMs: lastConnectionTestMs ?? this.lastConnectionTestMs,
      lastLlmError: lastLlmError ?? this.lastLlmError,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (apiKey != null) map['apiKey'] = apiKey;
    if (apiBaseUrl != null) map['apiBaseUrl'] = apiBaseUrl;
    if (selectedModel != null) map['selectedModel'] = selectedModel;
    if (themeMode != null) map['themeMode'] = themeMode!.index;
    if (fontSize != null) map['fontSize'] = fontSize;
    if (studyRemindersEnabled != null) map['studyRemindersEnabled'] = studyRemindersEnabled;
    if (requestTimeoutSeconds != null) map['requestTimeoutSeconds'] = requestTimeoutSeconds;
    if (sessionDurationMinutes != null) map['sessionDurationMinutes'] = sessionDurationMinutes;
    if (highContrastEnabled != null) map['highContrastEnabled'] = highContrastEnabled;
    if (largeTouchTargets != null) map['largeTouchTargets'] = largeTouchTargets;
    if (reduceMotion != null) map['reduceMotion'] = reduceMotion;
    if (revisionRemindersEnabled != null) map['revisionRemindersEnabled'] = revisionRemindersEnabled;
    if (lessonNotificationsEnabled != null) map['lessonNotificationsEnabled'] = lessonNotificationsEnabled;
    if (overworkAlertsEnabled != null) map['overworkAlertsEnabled'] = overworkAlertsEnabled;
    if (planAdjustmentNotificationsEnabled != null) map['planAdjustmentNotificationsEnabled'] = planAdjustmentNotificationsEnabled;
    if (breakDurationSeconds != null) map['breakDurationSeconds'] = breakDurationSeconds;
    if (dailyReminderHour != null) map['dailyReminderHour'] = dailyReminderHour;
    if (dailyReminderMinute != null) map['dailyReminderMinute'] = dailyReminderMinute;
    if (firstFocusVisit != null) map['firstFocusVisit'] = firstFocusVisit;
    if (dailyReminderEnabled != null) map['dailyReminderEnabled'] = dailyReminderEnabled;
    if (llmProviderName != null) map['llmProviderName'] = llmProviderName;
    if (lastConnectionTestMs != null) map['lastConnectionTestMs'] = lastConnectionTestMs;
    if (lastLlmError != null) map['lastLlmError'] = lastLlmError;
    return map;
  }
}
