import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  SettingsBox({
    this.apiKey = '',
    this.apiBaseUrl = 'https://openrouter.ai/api/v1',
    this.selectedModel = '',
    this.themeMode = 0,
    this.fontSize = 16.0,
    this.totalSessionCount = 0,
    this.totalStudyTimeMs = 0,
    this.totalQuestions = 0,
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
    };
  }

  factory SettingsBox.fromJson(Map<String, dynamic> json) {
    return SettingsBox(
      apiKey: json['apiKey'] ?? '',
      apiBaseUrl: json['apiBaseUrl'] ?? 'https://openrouter.ai/api/v1',
      selectedModel: json['selectedModel'] ?? '',
      themeMode: json['themeMode'] ?? 0,
      fontSize: json['fontSize'] ?? 16.0,
      totalSessionCount: json['totalSessionCount'] ?? 0,
      totalStudyTimeMs: json['totalStudyTimeMs'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SettingsBox(apiKey: ${apiKey.isEmpty ? "(hidden)" : apiKey.substring(0, 8)}, themeMode: $themeModeEnum, fontSize: ${fontSize.round()}px)';
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      studentId: json['studentId'],
      avatarIcon: json['avatarIcon'],
      learningGoal: json['learningGoal'],
      preferredStudyTime: json['preferredStudyTime'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      language: json['language'] ?? 'en',
    );
  }

  @override
  String toString() {
    return 'ProfileData(id: $id, name: $name, studentId: $studentId)';
  }
}
