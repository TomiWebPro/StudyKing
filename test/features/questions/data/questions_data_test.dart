import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/questions/data/questions_data.dart';

void main() {
  group('questions_data barrel', () {
    test('exports QuestionEvaluation', () {
      expect(QuestionEvaluation, isNotNull);
    });

    test('exports registerQuestionAdapters', () {
      expect(registerQuestionAdapters, isNotNull);
    });
  });
}
