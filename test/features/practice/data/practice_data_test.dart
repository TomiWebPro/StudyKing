import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/practice/data/practice_data.dart';

void main() {
  group('practice_data barrel', () {
    test('exports MasteryState', () {
      expect(MasteryState, isNotNull);
    });

    test('exports QuestionMasteryState', () {
      expect(QuestionMasteryState, isNotNull);
    });

    test('exports StudentAttempt', () {
      expect(StudentAttempt, isNotNull);
    });
  });
}
