import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';

void main() {
  group('BadgeModel', () {
    test('creates with required fields', () {
      final badge = BadgeModel(
        id: 'badge-1',
        studentId: 'student-1',
        name: 'First Step',
        description: 'Answered your first question!',
      );

      expect(badge.id, 'badge-1');
      expect(badge.studentId, 'student-1');
      expect(badge.name, 'First Step');
      expect(badge.description, 'Answered your first question!');
      expect(badge.iconName, 'emoji_events');
      expect(badge.category, 'general');
      expect(badge.criteria, isNull);
    });

    test('creates with all fields', () {
      final now = DateTime(2026, 5, 15);
      final badge = BadgeModel(
        id: 'badge-2',
        studentId: 'student-1',
        name: 'Century Club',
        description: 'Answered 100+ questions!',
        iconName: 'military_tech',
        category: 'milestone',
        unlockedAt: now,
        criteria: {'totalAttempts': 100},
      );

      expect(badge.id, 'badge-2');
      expect(badge.name, 'Century Club');
      expect(badge.iconName, 'military_tech');
      expect(badge.category, 'milestone');
      expect(badge.unlockedAt, now);
      expect(badge.criteria, {'totalAttempts': 100});
    });

    test('defaults unlockedAt to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final badge = BadgeModel(
        id: 'b1',
        studentId: 's1',
        name: 'Test',
        description: 'Test badge',
      );
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(badge.unlockedAt.isAfter(before), isTrue);
      expect(badge.unlockedAt.isBefore(after), isTrue);
    });

    group('toJson', () {
      test('serializes all fields', () {
        final now = DateTime(2026, 5, 15);
        final badge = BadgeModel(
          id: 'badge-1',
          studentId: 'student-1',
          name: 'Test Badge',
          description: 'A test badge',
          iconName: 'star',
          category: 'performance',
          unlockedAt: now,
          criteria: {'score': 95},
        );

        final json = badge.toJson();
        expect(json['id'], 'badge-1');
        expect(json['studentId'], 'student-1');
        expect(json['name'], 'Test Badge');
        expect(json['description'], 'A test badge');
        expect(json['iconName'], 'star');
        expect(json['category'], 'performance');
        expect(json['unlockedAt'], now.toIso8601String());
        expect(json['criteria'], {'score': 95});
      });

      test('serializes with defaults', () {
        final badge = BadgeModel(
          id: 'b1',
          studentId: 's1',
          name: 'N',
          description: 'D',
        );

        final json = badge.toJson();
        expect(json['iconName'], 'emoji_events');
        expect(json['category'], 'general');
      });

      test('serializes with null criteria', () {
        final now = DateTime(2026, 5, 15);
        final badge = BadgeModel(
          id: 'b2',
          studentId: 's1',
          name: 'Test',
          description: 'Desc',
          unlockedAt: now,
          criteria: null,
        );

        final json = badge.toJson();
        expect(json['id'], 'b2');
        expect(json['criteria'], isNull);
      });

      test('serializes with empty criteria map', () {
        final badge = BadgeModel(
          id: 'b3',
          studentId: 's1',
          name: 'Empty',
          description: 'Empty criteria',
          criteria: {},
        );

        final json = badge.toJson();
        expect(json['criteria'], isEmpty);
      });

      test('criteria map defaults to null', () {
        final badge = BadgeModel(
          id: 'b4',
          studentId: 's1',
          name: 'Null Criteria',
          description: 'Should have null criteria',
        );

        expect(badge.criteria, isNull);
      });
    });

    group('Hive type annotation', () {
      test('class has HiveType annotation', () {
        expect(BadgeModel, isNotNull);
      });

      test('class implements HiveObject', () {
        final badge = BadgeModel(
          id: 'hive-test',
          studentId: 's1',
          name: 'Hive',
          description: 'Hive test',
        );
        expect(badge, isA<HiveObject>());
      });
    });
  });

  group('BadgeDefinition', () {
    test('creates with all fields', () {
      final def = const BadgeDefinition(
        id: 'test_badge',
        name: 'Test Badge',
        description: 'A test badge',
        iconName: 'star',
        category: 'milestone',
        checkKey: 'totalAttempts',
        checkOperator: CheckOperator.greaterOrEqual,
        checkValue: 10,
      );

      expect(def.id, 'test_badge');
      expect(def.name, 'Test Badge');
      expect(def.checkKey, 'totalAttempts');
      expect(def.checkOperator, CheckOperator.greaterOrEqual);
      expect(def.checkValue, 10);
    });

    group('isSatisfiedBy', () {
      test('returns true when condition met (greaterOrEqual)', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 80,
        );

        expect(def.isSatisfiedBy({'score': 80}), isTrue);
        expect(def.isSatisfiedBy({'score': 95}), isTrue);
      });

      test('returns false when condition not met (greaterOrEqual)', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 80,
        );

        expect(def.isSatisfiedBy({'score': 79}), isFalse);
      });

      test('returns true for greaterThan', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.greaterThan,
          checkValue: 80,
        );

        expect(def.isSatisfiedBy({'score': 81}), isTrue);
        expect(def.isSatisfiedBy({'score': 80}), isFalse);
      });

      test('returns true for lessOrEqual', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.lessOrEqual,
          checkValue: 50,
        );

        expect(def.isSatisfiedBy({'score': 30}), isTrue);
        expect(def.isSatisfiedBy({'score': 50}), isTrue);
        expect(def.isSatisfiedBy({'score': 70}), isFalse);
      });

      test('returns true for lessThan', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.lessThan,
          checkValue: 50,
        );

        expect(def.isSatisfiedBy({'score': 49}), isTrue);
        expect(def.isSatisfiedBy({'score': 50}), isFalse);
      });

      test('returns false when key is missing', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'missing_key',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 1,
        );

        expect(def.isSatisfiedBy({'score': 100}), isFalse);
      });

      test('handles string values (parses as num)', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'hours',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 10,
        );

        expect(def.isSatisfiedBy({'hours': '15'}), isTrue);
        expect(def.isSatisfiedBy({'hours': '5'}), isFalse);
      });

      test('handles invalid string value defaults to 0', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'hours',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 1,
        );

        expect(def.isSatisfiedBy({'hours': 'invalid'}), isFalse);
      });

      test('handles num value with lessThan operator exactly equal', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.lessThan,
          checkValue: 50,
        );

        expect(def.isSatisfiedBy({'score': 49}), isTrue);
        expect(def.isSatisfiedBy({'score': 50}), isFalse);
        expect(def.isSatisfiedBy({'score': 51}), isFalse);
      });

      test('handles empty stats map', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 1,
        );

        expect(def.isSatisfiedBy({}), isFalse);
      });

      test('handles key exists with null value', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'score',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 1,
        );

        expect(def.isSatisfiedBy({'score': null}), isFalse);
      });

      test('handles empty string for string value', () {
        final def = const BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'D',
          iconName: 'star',
          category: 'milestone',
          checkKey: 'hours',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 1,
        );

        expect(def.isSatisfiedBy({'hours': ''}), isFalse);
      });
    });
  });

  group('BadgeDefinitions', () {
    test('all contains predefined badge definitions', () {
      expect(BadgeDefinitions.all.length, greaterThan(0));
    });

    test('all definitions have required fields', () {
      for (final def in BadgeDefinitions.all) {
        expect(def.id, isNotEmpty);
        expect(def.name, isNotEmpty);
        expect(def.description, isNotEmpty);
        expect(def.iconName, isNotEmpty);
        expect(def.category, isNotEmpty);
        expect(def.checkKey, isNotEmpty);
      }
    });

    test('includes first_attempt', () {
      final firstAttempt = BadgeDefinitions.all.firstWhere(
        (b) => b.id == 'first_attempt',
      );
      expect(firstAttempt.name, 'First Step');
      expect(firstAttempt.checkValue, 1);
    });

    test('getById returns matching definition', () {
      final def = BadgeDefinitions.getById('century');
      expect(def, isNotNull);
      expect(def!.name, 'Century Club');
    });

    test('getById returns null for unknown id', () {
      expect(BadgeDefinitions.getById('non_existent'), isNull);
    });

    test('has all expected badges', () {
      final ids = BadgeDefinitions.all.map((b) => b.id).toSet();
      expect(ids, containsAll([
        'first_attempt',
        'century',
        'accuracy_gold',
        'daily_streak',
        'ten_hours',
        'week_streak',
      ]));
    });

    test('definitions use various operators', () {
      final operators = BadgeDefinitions.all.map((b) => b.checkOperator).toSet();
      expect(operators, contains(CheckOperator.greaterOrEqual));
    });

    test('getById returns null for empty string id', () {
      expect(BadgeDefinitions.getById(''), isNull);
    });

    test('all definitions have unique ids', () {
      final ids = BadgeDefinitions.all.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('each definition has unique checkKey values', () {
      for (final def in BadgeDefinitions.all) {
        expect(def.checkKey, anyOf(
          'totalAttempts', 'accuracy', 'dailyActivity',
          'totalStudyTimeHours', 'weeklyActivity',
        ));
      }
    });
  });

  group('CheckOperator', () {
    test('has four values', () {
      expect(CheckOperator.values, [
        CheckOperator.greaterOrEqual,
        CheckOperator.greaterThan,
        CheckOperator.lessOrEqual,
        CheckOperator.lessThan,
      ]);
    });
  });
}
