import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/core.dart';

void main() {
  group('core barrel exports', () {
    test('exports SessionType', () {
      expect(SessionType, isA<Type>());
    });

    test('exports DatabaseService', () {
      expect(DatabaseService, isA<Type>());
    });

    test('exports Topic', () {
      expect(Topic, isA<Type>());
    });

    test('exports Question', () {
      expect(Question, isA<Type>());
    });

    test('exports Session', () {
      expect(Session, isA<Type>());
    });

    test('exports Subject', () {
      expect(Subject, isA<Type>());
    });

    test('exported firstOrNull extension works', () {
      final list = [1, 2, 3];
      expect(list.firstOrNull, equals(1));
      final empty = <int>[];
      expect(empty.firstOrNull, isNull);
    });
  });
}
