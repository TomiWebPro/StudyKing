import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 10)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? studentId;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final String? learningGoal;

  @HiveField(5)
  final String? preferredStudyTime;

  @HiveField(6)
  final bool notificationsEnabled;

  @HiveField(7)
  final String language;

  @HiveField(8)
  final String accessibilitySettings;

  UserProfile({
    required this.id,
    required this.name,
    this.studentId,
    this.avatarUrl,
    this.learningGoal,
    this.preferredStudyTime,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.accessibilitySettings = 'default',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'studentId': studentId,
        'avatarUrl': avatarUrl,
        'learningGoal': learningGoal,
        'preferredStudyTime': preferredStudyTime,
        'notificationsEnabled': notificationsEnabled,
        'language': language,
        'accessibilitySettings': accessibilitySettings,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        studentId: json['studentId'],
        avatarUrl: json['avatarUrl'],
        learningGoal: json['learningGoal'],
        preferredStudyTime: json['preferredStudyTime'],
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        language: json['language'] ?? 'en',
        accessibilitySettings: json['accessibilitySettings'] ?? 'default',
      );

  UserProfile copyWith({
    String? id,
    String? name,
    String? studentId,
    String? avatarUrl,
    String? learningGoal,
    String? preferredStudyTime,
    bool? notificationsEnabled,
    String? language,
    String? accessibilitySettings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      learningGoal: learningGoal ?? this.learningGoal,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      accessibilitySettings: accessibilitySettings ?? this.accessibilitySettings,
    );
  }
}
