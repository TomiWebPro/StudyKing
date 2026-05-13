import 'package:hive_flutter/hive_flutter.dart';
import 'accessibility_preferences.dart';

part 'user_profile_model.g.dart';

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
  final AccessibilityPreferences? accessibilityPrefs;

  UserProfile({
    required this.id,
    required this.name,
    this.studentId,
    this.avatarUrl,
    this.learningGoal,
    this.preferredStudyTime,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.accessibilityPrefs,
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
        'accessibilityPrefs': accessibilityPrefs?.toJson(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] is String ? json['id'] as String : '',
        name: json['name'] is String ? json['name'] as String : '',
        studentId: json['studentId'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        learningGoal: json['learningGoal'] as String?,
        preferredStudyTime: json['preferredStudyTime'] as String?,
        notificationsEnabled: json['notificationsEnabled'] is bool
            ? json['notificationsEnabled'] as bool
            : true,
        language: json['language'] is String ? json['language'] as String : 'en',
        accessibilityPrefs: json['accessibilityPrefs'] is Map
            ? AccessibilityPreferences.fromJson(
                json['accessibilityPrefs'] as Map<String, dynamic>)
            : null,
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
    AccessibilityPreferences? accessibilityPrefs,
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
      accessibilityPrefs: accessibilityPrefs ?? this.accessibilityPrefs,
    );
  }
}
