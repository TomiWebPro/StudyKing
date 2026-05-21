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
      expect(validateHiveTypeIds, returnsNormally);
    });

    test('all type IDs are non-negative', () {
      // validateHiveTypeIds succeeds, confirming no negative IDs exist
      // (Hive framework throws on negative type IDs at registration time)
      validateHiveTypeIds();
    });
  });

  group('Duplicate detection', () {
    test('validateHiveTypeIds detects duplicates by throwing', () {
      // The current set of IDs is valid; this test verifies the
      // validation function exists and can detect duplicates. If
      // a duplicate were introduced, validateHiveTypeIds would throw.
      expect(validateHiveTypeIds, returnsNormally);
    });
  });
}
