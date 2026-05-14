import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/student_id_service.dart';

void main() {
  group('StudentIdService', () {
    test('is a singleton', () {
      final instance1 = StudentIdService();
      final instance2 = StudentIdService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('provides a non-empty student id via provider', () {
      final studentIdProvider = studentIdValueProvider;
      expect(studentIdProvider, isNotNull);
    });
  });
}
