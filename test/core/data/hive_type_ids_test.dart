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

    test('throws StateError if duplicate ids were present', () {
      expect(
        () => validateHiveTypeIds(),
        returnsNormally,
      );
    });
  });
}
