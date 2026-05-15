import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/dashboard/data/models/badge_model.dart';

void main() {
  group('BadgeModel', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 12, 10, 0, 0);
    });

    group('constructor', () {
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
          name: 'N',
          description: 'D',
        );
        final after = DateTime.now().add(const Duration(seconds: 1));
        expect(badge.unlockedAt.isAfter(before), isTrue);
        expect(badge.unlockedAt.isBefore(after), isTrue);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final badge = BadgeModel(
          id: 'badge-1',
          studentId: 'student-1',
          name: 'First Step',
          description: 'Desc',
          iconName: 'star',
          category: 'milestone',
          unlockedAt: now,
          criteria: {'k': 'v'},
        );
        final json = badge.toJson();
        expect(json['id'], 'badge-1');
        expect(json['studentId'], 'student-1');
        expect(json['name'], 'First Step');
        expect(json['description'], 'Desc');
        expect(json['iconName'], 'star');
        expect(json['category'], 'milestone');
        expect(json['unlockedAt'], now.toIso8601String());
        expect(json['criteria'], {'k': 'v'});
      });

      test('serializes with null criteria', () {
        final badge = BadgeModel(
          id: 'b1',
          studentId: 's1',
          name: 'N',
          description: 'D',
        );
        final json = badge.toJson();
        expect(json['criteria'], isNull);
      });
    });

    group('equality', () {
      test('uses identity-based equality', () {
        final a = BadgeModel(id: 'b1', studentId: 's1', name: 'N', description: 'D');
        final b = BadgeModel(id: 'b1', studentId: 's1', name: 'N', description: 'D');
        expect(a == b, isFalse);
        expect(a == a, isTrue);
      });

      test('hashCode is consistent', () {
        final obj = BadgeModel(id: 'b1', studentId: 's1', name: 'N', description: 'D');
        final hash = obj.hashCode;
        expect(obj.hashCode, hash);
      });
    });

    group('toString', () {
      test('includes class name', () {
        final obj = BadgeModel(id: 'b1', studentId: 's1', name: 'N', description: 'D');
        expect(obj.toString(), contains('BadgeModel'));
      });
    });

    group('Hive type annotation', () {
      test('has correct Hive typeId', () {
        expect(BadgeModel, isNotNull);
      });
    });
  });

  group('BadgeDefinitions', () {
    group('all', () {
      test('contains all badge definitions', () {
        expect(BadgeDefinitions.all.length, 6);
        expect(BadgeDefinitions.all.map((b) => b.id), containsAll([
          'first_attempt',
          'century',
          'accuracy_gold',
          'daily_streak',
          'ten_hours',
          'week_streak',
        ]));
      });
    });

    group('getById', () {
      test('returns definition for valid id', () {
        final def = BadgeDefinitions.getById('first_attempt');
        expect(def, isNotNull);
        expect(def!.name, 'First Step');
      });

      test('returns null for unknown id', () {
        expect(BadgeDefinitions.getById('nonexistent'), isNull);
      });
    });
  });

  group('BadgeDefinition', () {
    group('isSatisfiedBy', () {
      late BadgeDefinition def;

      setUp(() {
        def = BadgeDefinition(
          id: 'test',
          name: 'Test',
          description: 'Test badge',
          iconName: 'star',
          category: 'general',
          checkKey: 'score',
          checkOperator: CheckOperator.greaterOrEqual,
          checkValue: 80,
        );
      });

      test('returns true when value meets threshold', () {
        expect(def.isSatisfiedBy({'score': 85}), isTrue);
      });

      test('returns true when value equals threshold', () {
        expect(def.isSatisfiedBy({'score': 80}), isTrue);
      });

      test('returns false when value is below threshold', () {
        expect(def.isSatisfiedBy({'score': 79}), isFalse);
      });

      test('returns false when key is missing', () {
        expect(def.isSatisfiedBy({}), isFalse);
      });

      test('handles string values', () {
        expect(def.isSatisfiedBy({'score': '85'}), isTrue);
      });

      test('treats non-numeric string as 0', () {
        expect(def.isSatisfiedBy({'score': 'abc'}), isFalse);
      });

      group('greaterThan', () {
        test('returns true when value exceeds threshold', () {
          final d = BadgeDefinition(
            id: 't', name: 'T', description: 'D', iconName: 'i',
            category: 'c', checkKey: 'k', checkOperator: CheckOperator.greaterThan, checkValue: 50,
          );
          expect(d.isSatisfiedBy({'k': 51}), isTrue);
          expect(d.isSatisfiedBy({'k': 50}), isFalse);
        });
      });

      group('lessOrEqual', () {
        test('returns true when value is at most threshold', () {
          final d = BadgeDefinition(
            id: 't', name: 'T', description: 'D', iconName: 'i',
            category: 'c', checkKey: 'k', checkOperator: CheckOperator.lessOrEqual, checkValue: 50,
          );
          expect(d.isSatisfiedBy({'k': 50}), isTrue);
          expect(d.isSatisfiedBy({'k': 49}), isTrue);
          expect(d.isSatisfiedBy({'k': 51}), isFalse);
        });
      });

      group('lessThan', () {
        test('returns true when value is below threshold', () {
          final d = BadgeDefinition(
            id: 't', name: 'T', description: 'D', iconName: 'i',
            category: 'c', checkKey: 'k', checkOperator: CheckOperator.lessThan, checkValue: 50,
          );
          expect(d.isSatisfiedBy({'k': 49}), isTrue);
          expect(d.isSatisfiedBy({'k': 50}), isFalse);
        });
      });
    });
  });
}
