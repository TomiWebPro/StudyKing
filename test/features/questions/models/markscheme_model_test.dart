import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';

void main() {
  group('Markscheme', () {
    test('creates with required field', () {
      final markscheme = Markscheme(correctAnswer: 'Paris');

      expect(markscheme.correctAnswer, 'Paris');
      expect(markscheme.acceptableAnswers, isEmpty);
      expect(markscheme.explanation, '');
      expect(markscheme.steps, isEmpty);
    });

    test('creates with all fields', () {
      final markscheme = Markscheme(
        correctAnswer: 'London',
        acceptableAnswers: ['london', 'england capital'],
        explanation: 'Capital of England',
        steps: ['step 1', 'step 2'],
      );

      expect(markscheme.correctAnswer, 'London');
      expect(markscheme.acceptableAnswers, ['london', 'england capital']);
      expect(markscheme.explanation, 'Capital of England');
      expect(markscheme.steps, ['step 1', 'step 2']);
    });

    test('toJson serializes correctly', () {
      final markscheme = Markscheme(
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris'],
        explanation: 'Capital of France',
        steps: ['First', 'Second'],
      );

      final json = markscheme.toJson();

      expect(json['correctAnswer'], 'Paris');
      expect(json['acceptableAnswers'], ['paris']);
      expect(json['explanation'], 'Capital of France');
      expect(json['steps'], ['First', 'Second']);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'correctAnswer': 'Berlin',
        'acceptableAnswers': ['berlin', 'germany capital'],
        'explanation': 'Capital of Germany',
        'steps': ['Step 1', 'Step 2'],
      };

      final markscheme = Markscheme.fromJson(json);

      expect(markscheme.correctAnswer, 'Berlin');
      expect(markscheme.acceptableAnswers, ['berlin', 'germany capital']);
      expect(markscheme.explanation, 'Capital of Germany');
      expect(markscheme.steps, ['Step 1', 'Step 2']);
    });

    test('fromJson handles empty acceptableAnswers', () {
      final json = {
        'correctAnswer': 'Madrid',
      };

      final markscheme = Markscheme.fromJson(json);

      expect(markscheme.acceptableAnswers, isEmpty);
    });

    test('fromJson handles null steps', () {
      final json = {
        'correctAnswer': 'Rome',
        'steps': null,
      };

      final markscheme = Markscheme.fromJson(json);

      expect(markscheme.steps, isEmpty);
    });

    test('fromJson handles missing steps key', () {
      final json = {
        'correctAnswer': 'Athens',
      };

      final markscheme = Markscheme.fromJson(json);

      expect(markscheme.steps, isEmpty);
    });

    test('default values are applied', () {
      final markscheme = Markscheme(correctAnswer: 'Test');

      expect(markscheme.acceptableAnswers, []);
      expect(markscheme.explanation, '');
      expect(markscheme.steps, []);
    });

    test('isMatch returns true for exact match', () {
      final markscheme = Markscheme(correctAnswer: 'Paris');

      expect(markscheme.isMatch('Paris'), isTrue);
    });

    test('isMatch returns true for case-insensitive match', () {
      final markscheme = Markscheme(correctAnswer: 'Paris');

      expect(markscheme.isMatch('paris'), isTrue);
      expect(markscheme.isMatch('PARIS'), isTrue);
    });

    test('isMatch returns true for whitespace trimmed match', () {
      final markscheme = Markscheme(correctAnswer: 'Paris');

      expect(markscheme.isMatch('  Paris  '), isTrue);
    });

    test('isMatch returns true for acceptable answer', () {
      final markscheme = Markscheme(
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'french capital'],
      );

      expect(markscheme.isMatch('paris'), isTrue);
      expect(markscheme.isMatch('french capital'), isTrue);
    });

    test('isMatch returns false for wrong answer', () {
      final markscheme = Markscheme(correctAnswer: 'Paris');

      expect(markscheme.isMatch('London'), isFalse);
    });

    test('isMatch returns false for partial acceptable match', () {
      final markscheme = Markscheme(
        correctAnswer: 'Paris',
        acceptableAnswers: ['paris', 'french capital'],
      );

      expect(markscheme.isMatch('french'), isFalse);
    });

    test('isMatch handles similar words', () {
      final markscheme = Markscheme(correctAnswer: 'hello world');

      expect(markscheme.isMatch('hello world test'), isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Markscheme(correctAnswer: 'Paris');
      final copy = original.copyWith(explanation: 'Updated explanation');

      expect(copy.correctAnswer, 'Paris');
      expect(copy.explanation, 'Updated explanation');
      expect(original.explanation, '');
    });

    test('copyWith preserves original values', () {
      final original = Markscheme(
        correctAnswer: 'London',
        acceptableAnswers: ['london'],
        explanation: 'Original',
      );
      final copy = original.copyWith();

      expect(copy.correctAnswer, original.correctAnswer);
      expect(copy.acceptableAnswers, original.acceptableAnswers);
      expect(copy.explanation, original.explanation);
    });
  });
}