import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/subjects/data/subjects_data.dart';

void main() {
  group('subjects_data barrel', () {
    test('exports TopicDependency', () {
      expect(TopicDependency, isNotNull);
    });

    test('exports registerSubjectsAdapters', () {
      expect(registerSubjectsAdapters, isNotNull);
    });
  });
}
