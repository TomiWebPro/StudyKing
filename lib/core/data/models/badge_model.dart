import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 31)
class BadgeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String iconName;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final DateTime unlockedAt;

  @HiveField(7)
  final Map<String, dynamic>? criteria;

  BadgeModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.description,
    this.iconName = 'emoji_events',
    this.category = 'general',
    DateTime? unlockedAt,
    this.criteria,
  }) : unlockedAt = unlockedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'name': name,
        'description': description,
        'iconName': iconName,
        'category': category,
        'unlockedAt': unlockedAt.toIso8601String(),
        'criteria': criteria,
      };
}

class BadgeDefinitions {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_attempt',
      name: 'First Step',
      description: 'Answered your first question!',
      iconName: 'emoji_events',
      category: 'milestone',
      checkKey: 'totalAttempts',
      checkOperator: CheckOperator.greaterOrEqual,
      checkValue: 1,
    ),
    BadgeDefinition(
      id: 'century',
      name: 'Century Club',
      description: 'Answered 100+ questions!',
      iconName: 'military_tech',
      category: 'milestone',
      checkKey: 'totalAttempts',
      checkOperator: CheckOperator.greaterOrEqual,
      checkValue: 100,
    ),
    BadgeDefinition(
      id: 'accuracy_gold',
      name: 'Accuracy Gold',
      description: 'Achieved 90%+ accuracy!',
      iconName: 'workspace_premium',
      category: 'performance',
      checkKey: 'accuracy',
      checkOperator: CheckOperator.greaterOrEqual,
      checkValue: 90,
    ),
    BadgeDefinition(
      id: 'daily_streak',
      name: 'Daily Scholar',
      description: 'Studied consistently today!',
      iconName: 'local_fire_department',
      category: 'consistency',
      checkKey: 'dailyActivity',
      checkOperator: CheckOperator.greaterOrEqual,
      checkValue: 5,
    ),
    BadgeDefinition(
      id: 'ten_hours',
      name: 'Dedicated Learner',
      description: 'Studied 10+ hours total!',
      iconName: 'schedule',
      category: 'milestone',
      checkKey: 'totalStudyTimeHours',
      checkOperator: CheckOperator.greaterOrEqual,
      checkValue: 10,
    ),
    BadgeDefinition(
      id: 'week_streak',
      name: 'Weekly Warrior',
      description: 'Active for a full week!',
      iconName: 'calendar_month',
      category: 'consistency',
      checkKey: 'weeklyActivity',
      checkOperator: CheckOperator.greaterOrEqual,
      checkValue: 7,
    ),
  ];

  static BadgeDefinition? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

enum CheckOperator { greaterOrEqual, greaterThan, lessOrEqual, lessThan }

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String category;
  final String checkKey;
  final CheckOperator checkOperator;
  final num checkValue;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.category,
    required this.checkKey,
    required this.checkOperator,
    required this.checkValue,
  });

  bool isSatisfiedBy(Map<String, dynamic> stats) {
    final value = stats[checkKey];
    if (value == null) return false;

    final numValue = value is String ? num.tryParse(value) ?? 0 : value as num;

    return switch (checkOperator) {
      CheckOperator.greaterOrEqual => numValue >= checkValue,
      CheckOperator.greaterThan => numValue > checkValue,
      CheckOperator.lessOrEqual => numValue <= checkValue,
      CheckOperator.lessThan => numValue < checkValue,
    };
  }
}
