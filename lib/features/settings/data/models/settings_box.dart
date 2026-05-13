import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_api_config.dart';

part 'settings_box.g.dart';

@HiveType(typeId: 4)
class SettingsBox {
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

  SettingsBox({
    this.apiKey = '',
    this.apiBaseUrl = ApiConfig.openRouterBaseUrlString,
    this.selectedModel = '',
    this.themeMode = 0,
    this.fontSize = 16.0,
    this.totalSessionCount = 0,
    this.totalStudyTimeMs = 0,
    this.totalQuestions = 0,
    this.studyRemindersEnabled = true,
    this.requestTimeoutSeconds = 120,
    this.sessionDurationMinutes = 30,
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
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      totalSessionCount: (json['totalSessionCount'] as num?)?.toInt() ?? 0,
      totalStudyTimeMs: (json['totalStudyTimeMs'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      studyRemindersEnabled: json['studyRemindersEnabled'] is bool
          ? json['studyRemindersEnabled'] as bool
          : true,
      requestTimeoutSeconds:
          (json['requestTimeoutSeconds'] as num?)?.toInt() ?? 120,
      sessionDurationMinutes:
          (json['sessionDurationMinutes'] as num?)?.toInt() ?? 30,
    );
  }

  @override
  String toString() {
    return 'SettingsBox(apiKey: (hidden), themeMode: $themeModeEnum, fontSize: ${fontSize.round()}px)';
  }
}

@HiveType(typeId: 5)
class ProfileData {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  final String? studentId;

  @HiveField(3)
  final String? avatarIcon;

  @HiveField(4)
  final String? learningGoal;

  @HiveField(5)
  final String? preferredStudyTime;

  @HiveField(6)
  late bool notificationsEnabled;

  @HiveField(7)
  late String language;

  ProfileData({
    required this.id,
    required this.name,
    this.studentId,
    this.avatarIcon,
    this.learningGoal,
    this.preferredStudyTime,
    this.notificationsEnabled = true,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
      'avatarIcon': avatarIcon,
      'learningGoal': learningGoal,
      'preferredStudyTime': preferredStudyTime,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
    };
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'] is String ? json['id'] as String : '',
      name: json['name'] is String ? json['name'] as String : '',
      studentId: json['studentId'] as String?,
      avatarIcon: json['avatarIcon'] as String?,
      learningGoal: json['learningGoal'] as String?,
      preferredStudyTime: json['preferredStudyTime'] as String?,
      notificationsEnabled: json['notificationsEnabled'] is bool
          ? json['notificationsEnabled'] as bool
          : true,
      language: json['language'] is String ? json['language'] as String : 'en',
    );
  }

  @override
  String toString() {
    return 'ProfileData(id: $id, name: $name, studentId: $studentId)';
  }
}
