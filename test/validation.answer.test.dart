import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/features/practice/services/answer_validation_service.dart';

void main() {
  group('AnswerValidationService.validateAnswer', () {
    final service = AnswerValidationService();
    final now = DateTime.utc(2024, 1, 1);

    Question buildQuestion({
      required String id,
      required QuestionType type,
      String? markscheme,
      List<String> options = const [],
    }) {
      return Question(
        id: id,
        text: 'Question $id',
        type: type,
        subjectId: 'sub-1',
        topicId: 'topic-1',
        markscheme: markscheme,
        options: options,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('typed answer is correct with markscheme match and wrong without markscheme', () {
      final withMarkscheme = buildQuestion(
        id: 'typed-1',
        type: QuestionType.typedAnswer,
        markscheme: 'Paris',
      );
      final withoutMarkscheme = buildQuestion(
        id: 'typed-2',
        type: QuestionType.typedAnswer,
        markscheme: null,
      );

      final correctResult = service.validateAnswer(withMarkscheme, 'paris');
      final missingResult = service.validateAnswer(withoutMarkscheme, 'anything');

      expect(correctResult.isCorrect, isTrue);
      expect(missingResult.isCorrect, isFalse);
    });

    test('single-choice uses exact answer validation', () {
      final question = buildQuestion(
        id: 'single-1',
        type: QuestionType.singleChoice,
        markscheme: 'B',
        options: const ['A', 'B', 'C'],
      );

      expect(service.validateAnswer(question, 'B').isCorrect, isTrue);
      expect(service.validateAnswer(question, 'A').isCorrect, isFalse);
    });

    test('multi-choice accepts equal sets and rejects partial answers', () {
      final question = buildQuestion(
        id: 'multi-1',
        type: QuestionType.multiChoice,
        markscheme: 'A,C',
        options: const ['A', 'B', 'C', 'D'],
      );

      expect(service.validateAnswer(question, 'C, A').isCorrect, isTrue);
      expect(service.validateAnswer(question, 'A').isCorrect, isFalse);
    });

    test('cache refreshes validator when same question id markscheme changes', () {
      final original = buildQuestion(
        id: 'cache-1',
        type: QuestionType.singleChoice,
        markscheme: 'A',
        options: const ['A', 'B'],
      );
      final updated = buildQuestion(
        id: 'cache-1',
        type: QuestionType.singleChoice,
        markscheme: 'B',
        options: const ['A', 'B'],
      );

      final first = service.validateAnswer(original, 'A');
      final second = service.validateAnswer(updated, 'B');
      final staleCheck = service.validateAnswer(updated, 'A');

      expect(first.isCorrect, isTrue);
      expect(second.isCorrect, isTrue);
      expect(staleCheck.isCorrect, isFalse);
    });
  });
}
