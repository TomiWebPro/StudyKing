import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:studyking/services/question_engine.dart';

void main() {
  group('DynamicQuestionType', () {
    test('has multipleChoice value', () {
      expect(DynamicQuestionType.multipleChoice, isNotNull);
    });

    test('has input value', () {
      expect(DynamicQuestionType.input, isNotNull);
    });

    test('has graph value', () {
      expect(DynamicQuestionType.graph, isNotNull);
    });

    test('has calculation value', () {
      expect(DynamicQuestionType.calculation, isNotNull);
    });

    test('has trueFalse value', () {
      expect(DynamicQuestionType.trueFalse, isNotNull);
    });

    test('has match value', () {
      expect(DynamicQuestionType.match, isNotNull);
    });

    test('enum has correct number of values', () {
      expect(DynamicQuestionType.values.length, equals(6));
    });
  });

  group('McqOptionsConfig', () {
    group('constants', () {
      test('minOptions is 2', () {
        expect(McqOptionsConfig.minOptions, equals(2));
      });

      test('maxOptions is 10', () {
        expect(McqOptionsConfig.maxOptions, equals(10));
      });

      test('defaultOptions is 5', () {
        expect(McqOptionsConfig.defaultOptions, equals(5));
      });
    });

    group('validateOptions', () {
      test('returns true for valid option count', () {
        final config = McqOptionsConfig();
        expect(config.validateOptions(5), isTrue);
        expect(config.validateOptions(2), isTrue);
        expect(config.validateOptions(10), isTrue);
      });

      test('returns false for option count below minimum', () {
        final config = McqOptionsConfig();
        expect(config.validateOptions(1), isFalse);
        expect(config.validateOptions(0), isFalse);
      });

      test('returns false for option count above maximum', () {
        final config = McqOptionsConfig();
        expect(config.validateOptions(11), isFalse);
        expect(config.validateOptions(100), isFalse);
      });
    });

    group('adjustOptions', () {
      test('returns minOptions when below minimum', () {
        final config = McqOptionsConfig();
        expect(config.adjustOptions(1), equals(2));
        expect(config.adjustOptions(0), equals(2));
        expect(config.adjustOptions(-5), equals(2));
      });

      test('returns maxOptions when above maximum', () {
        final config = McqOptionsConfig();
        expect(config.adjustOptions(11), equals(10));
        expect(config.adjustOptions(100), equals(10));
      });

      test('returns original when within range', () {
        final config = McqOptionsConfig();
        expect(config.adjustOptions(5), equals(5));
        expect(config.adjustOptions(7), equals(7));
      });
    });
  });

  group('LessonQuestion', () {
    test('creates instance with constructor', () {
      final question = LessonQuestion();
      expect(question, isNotNull);
    });

    test('creates instance with all fields', () {
      final question = LessonQuestion(
        questionId: 'q1',
        questionText: 'Test question?',
        createdAt: DateTime(2024, 1, 1),
        questionType: 'multipleChoice',
        correctAnswer: 'A',
        options: ['A', 'B', 'C', 'D'],
        sourceMaterial: 'material1',
        difficulty: 3,
      );
      expect(question.questionId, equals('q1'));
      expect(question.questionText, equals('Test question?'));
      expect(question.questionType, equals('multipleChoice'));
      expect(question.correctAnswer, equals('A'));
      expect(question.options?.length, equals(4));
      expect(question.difficulty, equals(3));
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = {
          'question_id': 'q1',
          'question_text': 'Test?',
          'created_at': '2024-01-01T00:00:00.000Z',
          'question_type': 'input',
          'correct_answer': 'answer',
          'options': ['a', 'b'],
          'source_material_id': 'mat1',
          'difficulty': 2,
        };
        final question = LessonQuestion.fromJson(json);
        expect(question.questionId, equals('q1'));
        expect(question.questionText, equals('Test?'));
        expect(question.questionType, equals('input'));
      });

      test('handles null values in JSON', () {
        final json = <String, dynamic>{};
        final question = LessonQuestion.fromJson(json);
        expect(question.questionId, isNull);
        expect(question.questionText, isNull);
      });

      test('parses options as list', () {
        final json = {
          'question_id': 'q1',
          'options': ['a', 'b', 'c'],
        };
        final question = LessonQuestion.fromJson(json);
        expect(question.options?.length, equals(3));
      });

      test('handles non-list options', () {
        final json = {
          'question_id': 'q1',
          'options': 'not a list',
        };
        final question = LessonQuestion.fromJson(json);
        expect(question.options, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final question = LessonQuestion(
          questionId: 'q1',
          questionText: 'Test?',
          questionType: 'mcq',
          correctAnswer: 'A',
          options: ['A', 'B'],
          difficulty: 1,
        );
        final json = question.toJson();
        expect(json['question_id'], equals('q1'));
        expect(json['question_text'], equals('Test?'));
        expect(json['question_type'], equals('mcq'));
        expect(json['options'], hasLength(2));
      });

      test('includes null values in JSON', () {
        final question = LessonQuestion();
        final json = question.toJson();
        expect(json.containsKey('question_id'), isTrue);
      });
    });

    group('clone', () {
      test('creates copy with same values', () {
        final question = LessonQuestion(
          questionId: 'q1',
          questionText: 'Test?',
          questionType: 'mcq',
          correctAnswer: 'A',
          options: ['A', 'B'],
          difficulty: 2,
        );
        final clone = question.clone();
        expect(clone.questionId, equals(question.questionId));
        expect(clone.questionText, equals(question.questionText));
        expect(clone.options?.length, equals(question.options?.length));
      });

      test('returns independent copy', () {
        final question = LessonQuestion(questionText: 'Original');
        final clone = question.clone();
        expect(identical(question, clone), isFalse);
      });
    });

    group('hasValidMcqOptions', () {
      test('returns true for non-MCQ types', () {
        final question = LessonQuestion(questionType: 'input');
        expect(question.hasValidMcqOptions(), isTrue);
      });

      test('returns true for MCQ with valid options', () {
        final question = LessonQuestion(
          questionType: 'multipleChoice',
          options: ['A', 'B', 'C', 'D', 'E'],
        );
        expect(question.hasValidMcqOptions(), isTrue);
      });

      test('returns true for MCQ with minimum options', () {
        final question = LessonQuestion(
          questionType: 'multipleChoice',
          options: ['A', 'B'],
        );
        expect(question.hasValidMcqOptions(), isTrue);
      });

      test('returns false for MCQ with null options', () {
        final question = LessonQuestion(questionType: 'multipleChoice');
        expect(question.hasValidMcqOptions(), isFalse);
      });

      test('returns false for MCQ with too few options', () {
        final question = LessonQuestion(
          questionType: 'multipleChoice',
          options: ['A'],
        );
        expect(question.hasValidMcqOptions(), isFalse);
      });

      test('returns false for MCQ with too many options', () {
        final question = LessonQuestion(
          questionType: 'multipleChoice',
          options: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'],
        );
        expect(question.hasValidMcqOptions(), isFalse);
      });
    });
  });

  group('DynamicLessonQuestionGenerator', () {
    late DynamicLessonQuestionGenerator generator;

    setUp(() {
      generator = DynamicLessonQuestionGenerator();
    });

    test('creates instance with dio', () {
      expect(generator.dio, isNotNull);
    });

    test('creates instance with custom dio', () {
      final customDio = Dio();
      final customGenerator = DynamicLessonQuestionGenerator(dio: customDio);
      expect(customGenerator.dio, equals(customDio));
    });

    test('has mcqConfig', () {
      expect(generator.mcqConfig, isNotNull);
      expect(generator.mcqConfig, isA<McqOptionsConfig>());
    });

    group('fetchMcqOptionsByType', () {
      test('handles fetch without throwing', () async {
        expect(() => generator.fetchMcqOptionsByType(), returnsNormally);
      });
    });

    group('getMcqOptionsForType', () {
      test('returns default options for unknown type', () {
        final options = generator.getMcqOptionsForType('unknown');
        expect(options, equals(5));
      });

      test('returns configured options for known type', () async {
        await generator.fetchMcqOptionsByType();
        final options = generator.getMcqOptionsForType('test');
        expect(options, isA<int>());
      });
    });

    group('generateQuestionWithDynamicOptions', () {
      test('generates question with default options', () async {
        final question = await generator.generateQuestionWithDynamicOptions(
          questionText: 'What is 2+2?',
          questionType: 'input',
          sourceMaterial: 'math',
        );
        expect(question.questionText, equals('What is 2+2?'));
        expect(question.questionType, equals('input'));
      });

      test('generates question with custom options count', () async {
        final question = await generator.generateQuestionWithDynamicOptions(
          questionText: 'What is 2+2?',
          questionType: 'multipleChoice',
          customOptionsCount: 4,
          sourceMaterial: 'math',
        );
        expect(question.options?.length, greaterThanOrEqualTo(2));
        expect(question.options?.length, lessThanOrEqualTo(10));
      });

      test('adjusts options below minimum', () async {
        final question = await generator.generateQuestionWithDynamicOptions(
          questionText: 'Test',
          questionType: 'multipleChoice',
          customOptionsCount: 1,
          sourceMaterial: 'mat',
        );
        expect(question.options?.length, greaterThanOrEqualTo(2));
      });

      test('adjusts options above maximum', () async {
        final question = await generator.generateQuestionWithDynamicOptions(
          questionText: 'Test',
          questionType: 'multipleChoice',
          customOptionsCount: 50,
          sourceMaterial: 'mat',
        );
        expect(question.options?.length, lessThanOrEqualTo(10));
      });

      test('sets source material', () async {
        final question = await generator.generateQuestionWithDynamicOptions(
          questionText: 'Test?',
          questionType: 'input',
          sourceMaterial: 'my-material',
        );
        expect(question.sourceMaterial, equals('my-material'));
      });
    });

    group('generateOption', () {
      test('returns option string with index', () async {
        final option = await generator.generateOption(0, 'Question');
        expect(option, contains('0'));
      });

      test('returns different options for different indices', () async {
        final option0 = await generator.generateOption(0, 'Q');
        final option1 = await generator.generateOption(1, 'Q');
        expect(option0, isNot(equals(option1)));
      });
    });

    group('generateQuestionFromApi', () {
      test('handles API error gracefully', () async {
        try {
          await generator.generateQuestionFromApi(
            questionText: 'Test?',
            questionType: 'input',
          );
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('uses custom options count', () async {
        try {
          final question = await generator.generateQuestionFromApi(
            questionText: 'Test?',
            questionType: 'multipleChoice',
            customOptionsCount: 4,
          );
          expect(question, isNotNull);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('getQuestion', () {
      test('returns input type question', () {
        final question = generator.getQuestion();
        expect(question.questionType, equals('input'));
      });

      test('returns test question text', () {
        final question = generator.getQuestion();
        expect(question.questionText, equals('Test question'));
      });
    });
  });

  group('DynamicLessonQuestionPrompts', () {
    group('generateMcqPrompt', () {
      test('returns prompt string', () {
        final prompt = DynamicLessonQuestionPrompts.generateMcqPrompt(
          questionType: DynamicQuestionType.multipleChoice,
        );
        expect(prompt, isA<String>());
        expect(prompt.isNotEmpty, isTrue);
      });

      test('includes question type in prompt', () {
        final prompt = DynamicLessonQuestionPrompts.generateMcqPrompt(
          questionType: DynamicQuestionType.calculation,
        );
        expect(prompt.contains('calculation'), isTrue);
      });

      test('includes source material in prompt', () {
        final prompt = DynamicLessonQuestionPrompts.generateMcqPrompt(
          questionType: DynamicQuestionType.multipleChoice,
          sourceMaterial: 'my-material',
        );
        expect(prompt.contains('my-material'), isTrue);
      });

      test('generates different prompts for different types', () {
        final prompt1 = DynamicLessonQuestionPrompts.generateMcqPrompt(
          questionType: DynamicQuestionType.multipleChoice,
        );
        final prompt2 = DynamicLessonQuestionPrompts.generateMcqPrompt(
          questionType: DynamicQuestionType.trueFalse,
        );
        expect(prompt1, isNot(equals(prompt2)));
      });
    });

    group('generateInputPrompt', () {
      test('returns prompt string', () {
        final prompt = DynamicLessonQuestionPrompts.generateInputPrompt('content');
        expect(prompt, isA<String>());
        expect(prompt.isNotEmpty, isTrue);
      });

      test('includes content in prompt', () {
        final prompt = DynamicLessonQuestionPrompts.generateInputPrompt('my content');
        expect(prompt.contains('my content'), isTrue);
      });

      test('generates different prompts for different content', () {
        final prompt1 = DynamicLessonQuestionPrompts.generateInputPrompt('content1');
        final prompt2 = DynamicLessonQuestionPrompts.generateInputPrompt('content2');
        expect(prompt1, isNot(equals(prompt2)));
      });
    });
  });
}
