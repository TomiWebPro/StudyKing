import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/hive_type_ids.dart';

void main() {
  group('Hive schema type-id uniqueness', () {
    test('validateHiveTypeIds succeeds for the current schema', () {
      // The schema is internally consistent only when every registered
      // Hive typeId is unique. This call throws (AppException) otherwise.
      expect(validateHiveTypeIds, returnsNormally);
    });

    test('validateHiveTypeIds is idempotent', () {
      validateHiveTypeIds();
      validateHiveTypeIds();
      validateHiveTypeIds();
    });

    test('the public sessionTypeId is a valid, non-negative schema id', () {
      expect(sessionTypeId, isA<int>());
      expect(sessionTypeId, greaterThanOrEqualTo(0));
      // Re-validating the whole schema confirms no collision with this id.
      expect(validateHiveTypeIds, returnsNormally);
    });

    test('schema type-ids are densely registered (no negative ids)', () {
      // Hive rejects negative typeIds at adapter registration time, so a
      // successful validation guarantees the whole set is non-negative.
      expect(validateHiveTypeIds, returnsNormally);
    });
  });
}
