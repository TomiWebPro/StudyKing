import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/data.dart';

void main() {
  group('core/data.dart barrel', () {
    test('DatabaseService class is accessible', () {
      // Verifies the barrel file exports its constituents without error.
      // Individual files have their own dedicated tests.
      expect(DatabaseService, isNotNull);
    });

    test('QuestionType enum is accessible', () {
      expect(QuestionType.values.length, greaterThan(0));
    });

    test('HiveBoxNames constants are accessible', () {
      expect(HiveBoxNames.settings, isNotEmpty);
    });

    test('HiveInitializer class is accessible', () {
      expect(HiveInitializer, isNotNull);
    });

    test('DatabaseMigration class is accessible', () {
      expect(DatabaseMigration, isNotNull);
    });
  });
}
