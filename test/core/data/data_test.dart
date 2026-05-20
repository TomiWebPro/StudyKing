import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/data.dart';

void main() {
  test('core data barrel imports resolve', () {
    const _ = DatabaseMigration;
    expect(DatabaseService, isNotNull);
  });
}
