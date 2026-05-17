import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_api_config.dart';

part 'settings_box.g.dart';

@HiveType(typeId: 4)
class SettingsBox {
  static const double defaultFontSize = 16.0;
  static const int defaultRequestTimeoutSeconds = 120;
  static const int defaultSessionDurationMinutes = 30;
  static const int defaultBreakDurationSeconds = 300;
  static const int defaultDailyReminderHour = 9;

  @HiveField(0)
  late String apiKey;

  @HiveField(1)
  late String apiBaseUrl;

  @HiveField(2)
  late String selectedModel;

  @HiveField(3)
  late int themeMode;

  @HiveField(4)
  late double fontSize;

  @HiveField(5)
  late int totalSessionCount;

  @HiveField(6)
  late int totalStudyTimeMs;

  @HiveField(7)
  late int totalQuestions;

  @HiveField(8)
  late bool studyRemindersEnabled;

  @HiveField(9)
  late int requestTimeoutSeconds;

  @HiveField(10)
  late int sessionDurationMinutes;

  @HiveField(11)
  late bool highContrastEnabled;

  @HiveField(12)
  late bool largeTouchTargets;

  @HiveField(13)
  late bool reduceMotion;

  @HiveField(14)
  late bool revisionRemindersEnabled;

  @HiveField(15)
  late bool lessonNotificationsEnabled;

  @HiveField(16)
  late bool overworkAlertsEnabled;

  @HiveField(17)
  late bool planAdjustmentNotificationsEnabled;

  @HiveField(18)
  late int breakDurationSeconds;

  @HiveField(19)
  late int dailyReminderHour;

  @HiveField(20)
  late int dailyReminderMinute;

  @HiveField(21)
  late bool firstFocusVisit;

  @HiveField(22)
  late bool dailyReminderEnabled;

  SettingsBox({
    this.apiKey = '',
    this.apiBaseUrl = ApiConfig.openRouterBaseUrlString,
    this.selectedModel = '',
    this.themeMode = 0,
    this.fontSize = defaultFontSize,
    this.totalSessionCount = 0,
    this.totalStudyTimeMs = 0,
    this.totalQuestions = 0,
    this.studyRemindersEnabled = true,
    this.requestTimeoutSeconds = defaultRequestTimeoutSeconds,
    this.sessionDurationMinutes = defaultSessionDurationMinutes,
    this.highContrastEnabled = false,
    this.largeTouchTargets = false,
    this.reduceMotion = false,
    this.revisionRemindersEnabled = true,
    this.lessonNotificationsEnabled = true,
    this.overworkAlertsEnabled = true,
    this.planAdjustmentNotificationsEnabled = true,
    this.breakDurationSeconds = defaultBreakDurationSeconds,
    this.dailyReminderHour = defaultDailyReminderHour,
    this.dailyReminderMinute = 0,
    this.firstFocusVisit = true,
    this.dailyReminderEnabled = false,
  });

  ThemeMode get themeModeEnum => ThemeMode.values.firstWhere(
    (m) => m.index == themeMode,
    orElse: () => ThemeMode.light,
  );

  void setThemeMode(ThemeMode mode) {
    themeMode = mode.index;
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'apiBaseUrl': apiBaseUrl,
      'selectedModel': selectedModel,
      'themeMode': themeMode,
      'fontSize': fontSize,
      'totalSessionCount': totalSessionCount,
      'totalStudyTimeMs': totalStudyTimeMs,
      'totalQuestions': totalQuestions,
      'studyRemindersEnabled': studyRemindersEnabled,
      'requestTimeoutSeconds': requestTimeoutSeconds,
      'sessionDurationMinutes': sessionDurationMinutes,
      'highContrastEnabled': highContrastEnabled,
      'largeTouchTargets': largeTouchTargets,
      'reduceMotion': reduceMotion,
      'revisionRemindersEnabled': revisionRemindersEnabled,
      'lessonNotificationsEnabled': lessonNotificationsEnabled,
      'overworkAlertsEnabled': overworkAlertsEnabled,
      'planAdjustmentNotificationsEnabled': planAdjustmentNotificationsEnabled,
      'breakDurationSeconds': breakDurationSeconds,
      'dailyReminderHour': dailyReminderHour,
      'dailyReminderMinute': dailyReminderMinute,
      'firstFocusVisit': firstFocusVisit,
      'dailyReminderEnabled': dailyReminderEnabled,
    };
  }

  factory SettingsBox.fromJson(Map<String, dynamic> json) {
    return SettingsBox(
      apiKey: json['apiKey'] is String ? json['apiKey'] as String : '',
      apiBaseUrl: json['apiBaseUrl'] is String
          ? json['apiBaseUrl'] as String
          : ApiConfig.openRouterBaseUrlString,
      selectedModel:
          json['selectedModel'] is String ? json['selectedModel'] as String : '',
      themeMode: (json['themeMode'] as num?)?.toInt() ?? 0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaultFontSize,
      totalSessionCount: (json['totalSessionCount'] as num?)?.toInt() ?? 0,
      totalStudyTimeMs: (json['totalStudyTimeMs'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      studyRemindersEnabled: json['studyRemindersEnabled'] is bool
          ? json['studyRemindersEnabled'] as bool
          : true,
      requestTimeoutSeconds:
          (json['requestTimeoutSeconds'] as num?)?.toInt() ?? defaultRequestTimeoutSeconds,
      sessionDurationMinutes:
          (json['sessionDurationMinutes'] as num?)?.toInt() ?? defaultSessionDurationMinutes,
      highContrastEnabled: json['highContrastEnabled'] is bool
          ? json['highContrastEnabled'] as bool
          : false,
      largeTouchTargets: json['largeTouchTargets'] is bool
          ? json['largeTouchTargets'] as bool
          : false,
      reduceMotion: json['reduceMotion'] is bool
          ? json['reduceMotion'] as bool
          : false,
      revisionRemindersEnabled: json['revisionRemindersEnabled'] is bool
          ? json['revisionRemindersEnabled'] as bool
          : true,
      lessonNotificationsEnabled: json['lessonNotificationsEnabled'] is bool
          ? json['lessonNotificationsEnabled'] as bool
          : true,
      overworkAlertsEnabled: json['overworkAlertsEnabled'] is bool
          ? json['overworkAlertsEnabled'] as bool
          : true,
      planAdjustmentNotificationsEnabled:
          json['planAdjustmentNotificationsEnabled'] is bool
              ? json['planAdjustmentNotificationsEnabled'] as bool
              : true,
      breakDurationSeconds: (json['breakDurationSeconds'] as num?)?.toInt() ?? defaultBreakDurationSeconds,
      dailyReminderHour: (json['dailyReminderHour'] as num?)?.toInt() ?? defaultDailyReminderHour,
      dailyReminderMinute: (json['dailyReminderMinute'] as num?)?.toInt() ?? 0,
      firstFocusVisit: json['firstFocusVisit'] is bool
          ? json['firstFocusVisit'] as bool
          : true,
      dailyReminderEnabled: json['dailyReminderEnabled'] is bool
          ? json['dailyReminderEnabled'] as bool
          : false,
    );
  }

  SettingsBox copyWith({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeModeEnum,
    double? fontSize,
    int? totalSessionCount,
    int? totalStudyTimeMs,
    int? totalQuestions,
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
  }) {
    return SettingsBox(
      apiKey: apiKey ?? this.apiKey,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      selectedModel: selectedModel ?? this.selectedModel,
      themeMode: themeModeEnum?.index ?? themeMode,
      fontSize: fontSize ?? this.fontSize,
      totalSessionCount: totalSessionCount ?? this.totalSessionCount,
      totalStudyTimeMs: totalStudyTimeMs ?? this.totalStudyTimeMs,
      totalQuestions: totalQuestions ?? this.totalQuestions,
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
    );
  }

  @override
  String toString() {
    return 'SettingsBox(apiKey: (hidden), themeMode: $themeModeEnum, fontSize: ${fontSize.round()}px, highContrast: $highContrastEnabled)';
  }
}

