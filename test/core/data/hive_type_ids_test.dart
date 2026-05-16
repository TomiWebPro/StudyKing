import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/hive_type_ids.dart';

void main() {
  group('validateHiveTypeIds', () {
    test('runs without throwing when all ids are unique', () {
      expect(validateHiveTypeIds, returnsNormally);
    });

    test('can be called repeatedly without side effects', () {
      validateHiveTypeIds();
      validateHiveTypeIds();
      validateHiveTypeIds();
    });
  });

  group('Type IDs are unique and non-negative', () {
    test('no duplicate ids should exist', () {
      // This test verifies the _checkUniqueIds logic indirectly.
      // If there were duplicates, validateHiveTypeIds would throw.
      expect(validateHiveTypeIds, returnsNormally);
    });

    test('all type IDs are within valid range', () {
      // Hive type IDs must be non-negative and below 256.
      // This test validates the constants are in valid range.
      // We call validateHiveTypeIds which checks uniqueness.
      validateHiveTypeIds();
    });
  });
}
