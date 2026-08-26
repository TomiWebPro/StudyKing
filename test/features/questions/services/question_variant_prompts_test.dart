import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/questions/services/question_variant_prompts.dart';

Question _buildQuestion({
  required QuestionType type,
  required String id,
  required String text,
  List<String> options = const [],
  String? correctAnswer,
  String? explanation,
  List<String> tags = const [],
  int difficulty = 2,
}) {
  return Question(
    id: id,
    text: text,
    type: type,
    difficulty: difficulty,
    subjectId: 'sub-1',
    topicId: 'top-1',
    options: options,
    markscheme: correctAnswer != null
        ? Markscheme(questionId: id, correctAnswer: correctAnswer)
        : null,
    explanation: explanation,
    tags: tags,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('buildVariantGenerationPrompt', () {
    test('composes core instructions and the requested variant count', () {
      final source = _buildQuestion(
        type: QuestionType.singleChoice,
        id: 'q-1',
        text: 'What is 2 + 2?',
      );
      final prompt = buildVariantGenerationPrompt(source: source, count: 3);

      expect(prompt, contains('VARIANTS'));
      expect(prompt, contains('3 new versions'));
      expect(prompt, contains('Return ONLY a JSON array'));
      expect(prompt, contains('"text"'));
      expect(prompt, contains('"options"'));
      expect(prompt, contains('"correctAnswer"'));
      expect(prompt, contains('"explanation"'));
    });

    test('embeds the source question metadata', () {
      final source = _buildQuestion(
        type: QuestionType.singleChoice,
        id: 'q-7',
        text: 'Solve for x: 3x = 9',
        difficulty: 4,
      );
      final prompt = buildVariantGenerationPrompt(source: source, count: 1);

      expect(prompt, contains('id: q-7'));
      expect(prompt, contains('type: ${QuestionType.singleChoice.name}'));
      expect(prompt, contains('difficulty: 4'));
      expect(prompt, contains('stem: Solve for x: 3x = 9'));
    });

    test('includes source options for a multiple-choice question', () {
      final source = _buildQuestion(
        type: QuestionType.singleChoice,
        id: 'q-mc',
        text: 'Pick the prime.',
        options: ['2', '4', '6', '8'],
      );
      final prompt = buildVariantGenerationPrompt(source: source, count: 2);

      expect(prompt, contains('options: 2 | 4 | 6 | 8'));
      expect(
        prompt,
        contains(
          'provide a full `options` list, shuffle the position of the correct answer',
        ),
      );
    });

    test('includes the original correct answer and explanation when present',
        () {
      final source = _buildQuestion(
        type: QuestionType.typedAnswer,
        id: 'q-math',
        text: 'What is 7 * 6?',
        correctAnswer: '42',
        explanation: 'Multiply 7 by 6.',
      );
      final prompt = buildVariantGenerationPrompt(source: source, count: 2);

      expect(prompt, contains('original correct answer: 42'));
      expect(prompt, contains('original explanation: Multiply 7 by 6.'));
      expect(
        prompt,
        contains('`options` must be an empty list'),
      );
    });

    test('includes tags when the source has them', () {
      final source = _buildQuestion(
        type: QuestionType.typedAnswer,
        id: 'q-tag',
        text: 'State the capital of France.',
        correctAnswer: 'Paris',
        tags: ['geography', 'europe'],
      );
      final prompt = buildVariantGenerationPrompt(source: source, count: 1);

      expect(prompt, contains('tags: geography, europe'));
    });

    test('varies composition for an open-ended/numeric question', () {
      final numeric = _buildQuestion(
        type: QuestionType.typedAnswer,
        id: 'q-num',
        text: 'Calculate 12 / 4.',
        correctAnswer: '3',
      );
      final prompt = buildVariantGenerationPrompt(source: numeric, count: 4);

      expect(prompt, contains('4 new versions'));
      expect(prompt, contains('`correctAnswer` must be the exact expected answer'));
      expect(prompt, isNot(contains('options: ')));
    });

    test('handles multiple question types consistently', () {
      final cases = [
        _buildQuestion(
          type: QuestionType.singleChoice,
          id: 'a',
          text: 'MC question',
          options: ['x', 'y'],
        ),
        _buildQuestion(
          type: QuestionType.multiChoice,
          id: 'b',
          text: 'Multi question',
          options: ['p', 'q', 'r'],
        ),
        _buildQuestion(
          type: QuestionType.essay,
          id: 'c',
          text: 'Essay question',
        ),
      ];

      for (final source in cases) {
        final prompt = buildVariantGenerationPrompt(source: source, count: 2);
        expect(prompt, contains('type: ${source.type.name}'));
        expect(prompt, contains('stem: ${source.text}'));
        expect(prompt, contains('Return ONLY a JSON array'));
      }
    });
  });
}
