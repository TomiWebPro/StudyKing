import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/hive_type_ids.dart';

void main() {
  group('HiveTypeIds', () {
    test('validateHiveTypeIds runs without error', () {
      expect(validateHiveTypeIds, isNotNull);
      // The function uses assert, so in release it's a no-op
      // Just verify it can be called
      validateHiveTypeIds();
    });
  });
}
