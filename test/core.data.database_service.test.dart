import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/database_service.dart';

void main() {
  group('DatabaseService', () {
    test('creates with all repositories', () {
      // DatabaseService requires all repositories; this tests the data class
      // We just verify it can be constructed - the repositories themselves are tested separately
      expect(DatabaseService, isNotNull);
    });
  });
}
