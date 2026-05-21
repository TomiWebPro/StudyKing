import 'package:hive_flutter/hive_flutter.dart';

part 'accessibility_preferences.g.dart';

@HiveType(typeId: 34)
class AccessibilityPreferences extends HiveObject {
  @HiveField(0)
  final bool boldText;

  @HiveField(1)
  final bool highContrast;

  @HiveField(2)
  final bool reduceMotion;

  @HiveField(3)
  final bool largeTouchTargets;

  AccessibilityPreferences({
    this.boldText = false,
    this.highContrast = false,
    this.reduceMotion = false,
    this.largeTouchTargets = false,
  });

  Map<String, dynamic> toJson() => {
        'boldText': boldText,
        'highContrast': highContrast,
        'reduceMotion': reduceMotion,
        'largeTouchTargets': largeTouchTargets,
      };

  factory AccessibilityPreferences.fromJson(Map<String, dynamic> json) =>
      AccessibilityPreferences(
        boldText: json['boldText'] is bool ? json['boldText'] as bool : false,
        highContrast:
            json['highContrast'] is bool ? json['highContrast'] as bool : false,
        reduceMotion:
            json['reduceMotion'] is bool ? json['reduceMotion'] as bool : false,
        largeTouchTargets: json['largeTouchTargets'] is bool
            ? json['largeTouchTargets'] as bool
            : false,
      );

  AccessibilityPreferences copyWith({
    bool? boldText,
    bool? highContrast,
    bool? reduceMotion,
    bool? largeTouchTargets,
  }) {
    return AccessibilityPreferences(
      boldText: boldText ?? this.boldText,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      largeTouchTargets: largeTouchTargets ?? this.largeTouchTargets,
    );
  }

  @override
  String toString() {
    return 'AccessibilityPreferences(boldText: $boldText, highContrast: $highContrast, '
        'reduceMotion: $reduceMotion, largeTouchTargets: $largeTouchTargets)';
  }
}
