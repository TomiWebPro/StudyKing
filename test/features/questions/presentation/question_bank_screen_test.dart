import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';

void main() {
  group('Question model generated-by indicator', () {
    test('question with model field is AI-generated', () {
      final q = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: '',
        topicId: '',
        model: 'gpt-4',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(q.model, isNotNull);
    });

    test('question without model field is manual', () {
      final q = Question(
        id: 'q2',
        text: 'Manual?',
        type: QuestionType.typedAnswer,
        subjectId: '',
        topicId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(q.model, isNull);
    });

    test('question stores sourceIds for filtering', () {
      final q = Question(
        id: 'q3',
        text: 'Source question?',
        type: QuestionType.multiChoice,
        subjectId: '',
        topicId: '',
        sourceIds: ['src1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(q.sourceIds, contains('src1'));
    });

    test('question without sourceIds has empty list', () {
      final q = Question(
        id: 'q4',
        text: 'No source?',
        type: QuestionType.essay,
        subjectId: '',
        topicId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(q.sourceIds, isEmpty);
    });
  });

  group('Question filter fields', () {
    test('question stores subjectId for filtering', () {
      final q = Question(
        id: 'q1',
        text: 'Test?',
        type: QuestionType.singleChoice,
        subjectId: 'sub1',
        topicId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(q.subjectId, 'sub1');
    });

    test('question type name for filtering', () {
      expect(QuestionType.singleChoice.name, 'singleChoice');
      expect(QuestionType.multiChoice.name, 'multiChoice');
      expect(QuestionType.typedAnswer.name, 'typedAnswer');
    });
  });
}
