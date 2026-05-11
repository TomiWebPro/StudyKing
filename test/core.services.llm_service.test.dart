import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm_service.dart';
import 'package:studyking/core/data/enums.dart';

void main() {
  group('LlmService', () {
    group('LlmConfiguration', () {
      test('creates configuration with required fields', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test_key',
        );

        expect(config.provider, equals(LlmProvider.openRouter));
        expect(config.apiKey, equals('test_key'));
      });

      test('creates configuration with custom baseUrl', () {
        const config = LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'test_key',
          baseUrl: 'http://localhost:11434',
        );

        expect(config.baseUrl, equals('http://localhost:11434'));
      });

      test('default baseUrl is empty', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test_key',
        );

        expect(config.baseUrl, equals(''));
      });
    });

    group('generateQuestions', () {
      test('returns mock questions when api key is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final questions = await service.generateQuestions(
          topicTitle: 'Algebra',
          syllabus: 'Basic algebra',
          subjectId: 'math',
          count: 5,
          difficulty: 2,
          modelId: 'gpt-3.5-turbo',
        );

        expect(questions.length, equals(5));
        expect(questions.first.subjectId, equals('math'));
      });

      test('returns mock questions on API error', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'invalid_key',
        );
        final service = LlmService(config: config);

        final questions = await service.generateQuestions(
          topicTitle: 'Algebra',
          syllabus: 'Basic algebra',
          subjectId: 'math',
          count: 3,
          difficulty: 1,
          modelId: 'gpt-3.5-turbo',
        );

        expect(questions.isNotEmpty, isTrue);
      });
    });

    group('generateLessonBlocks', () {
      test('returns mock lesson blocks when api key is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final blocks = await service.generateLessonBlocks(
          topicTitle: 'Algebra',
          subjectId: 'math',
          content: 'Introduction to algebra',
          modelId: 'gpt-3.5-turbo',
        );

        expect(blocks.isNotEmpty, isTrue);
        expect(blocks.first.subjectId, equals('math'));
      });

      test('returns mock lesson blocks on API error', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'invalid_key',
        );
        final service = LlmService(config: config);

        final blocks = await service.generateLessonBlocks(
          topicTitle: 'Algebra',
          subjectId: 'math',
          content: 'Introduction to algebra',
          modelId: 'gpt-3.5-turbo',
        );

        expect(blocks.isNotEmpty, isTrue);
      });
    });

    group('generateLesson', () {
      test('returns mock lesson when api key is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final lesson = await service.generateLesson(
          title: 'Introduction to Algebra',
          subjectId: 'math',
          topicId: 'topic1',
          content: 'Basic concepts',
          modelId: 'gpt-3.5-turbo',
        );

        expect(lesson.subjectId, equals('math'));
        expect(lesson.title, equals('Introduction to Algebra'));
        expect(lesson.generatedBy, equals(GeneratedBy.ai));
      });

      test('returns mock lesson on API error', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'invalid_key',
        );
        final service = LlmService(config: config);

        final lesson = await service.generateLesson(
          title: 'Introduction to Algebra',
          subjectId: 'math',
          topicId: 'topic1',
          content: 'Basic concepts',
          modelId: 'gpt-3.5-turbo',
        );

        expect(lesson.subjectId, equals('math'));
        expect(lesson.generatedBy, equals(GeneratedBy.ai));
      });

      test('allows custom difficulty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final lesson = await service.generateLesson(
          title: 'Advanced Algebra',
          subjectId: 'math',
          topicId: 'topic1',
          content: 'Advanced concepts',
          modelId: 'gpt-3.5-turbo',
          difficulty: 3,
        );

        expect(lesson.difficulty, equals(3));
      });
    });

    group('validateAnswer', () {
      test('returns mock validation when api key is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final result = await service.validateAnswer(
          questionText: 'What is 2+2?',
          userAnswer: '4',
          correctAnswer: '4',
          subjectId: 'math',
          modelId: 'gpt-3.5-turbo',
        );

        expect(result, contains('mock'));
      });

      test('returns mock validation on API error', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'invalid_key',
        );
        final service = LlmService(config: config);

        final result = await service.validateAnswer(
          questionText: 'What is 2+2?',
          userAnswer: '4',
          correctAnswer: '4',
          subjectId: 'math',
          modelId: 'gpt-3.5-turbo',
        );

        expect(result, isA<String>());
      });

      test('includes topicId in context when provided', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final result = await service.validateAnswer(
          questionText: 'What is 2+2?',
          userAnswer: '4',
          correctAnswer: '4',
          subjectId: 'math',
          topicId: 'algebra',
          modelId: 'gpt-3.5-turbo',
        );

        expect(result, isA<String>());
      });
    });

    group('generateStudyPlan', () {
      test('returns mock study plan when api key is empty', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: '',
        );
        final service = LlmService(config: config);

        final plan = await service.generateStudyPlan(
          subjectId: 'math',
          course: 'Mathematics',
          days: 7,
          hoursPerDay: 2,
          modelId: 'gpt-3.5-turbo',
        );

        expect(plan['subjectId'], equals('math'));
        expect(plan['course'], equals('Mathematics'));
        expect(plan['days'], equals(7));
      });

      test('returns mock study plan on API error', () async {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'invalid_key',
        );
        final service = LlmService(config: config);

        final plan = await service.generateStudyPlan(
          subjectId: 'math',
          course: 'Mathematics',
          days: 14,
          hoursPerDay: 3,
          modelId: 'gpt-3.5-turbo',
        );

        expect(plan['subjectId'], equals('math'));
      });
    });

    group('_parseQuestions', () {
      test('parses valid JSON array', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final response = '''
        [
          {"id": "q1", "text": "Question 1", "type": "singleChoice", "difficulty": 1},
          {"id": "q2", "text": "Question 2", "type": "multiChoice", "difficulty": 2}
        ]
        ''';

        final questions = service._parseQuestions(response, 'math');

        expect(questions.length, equals(2));
      });

      test('handles invalid JSON', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final questions = service._parseQuestions('invalid json', 'math');

        expect(questions, isEmpty);
      });

      test('handles non-array JSON', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final questions = service._parseQuestions('{"key": "value"}', 'math');

        expect(questions, isEmpty);
      });

      test('handles JSON with alternative keys', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final response = '''
        [
          {"id": "q1", "question": "Question 1", "answer": "Answer 1"}
        ]
        ''';

        final questions = service._parseQuestions(response, 'math');

        expect(questions.isNotEmpty, isTrue);
      });
    });

    group('_parseQuestionType', () {
      test('parses integer index', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseQuestionType(0), equals(QuestionType.singleChoice));
        expect(service._parseQuestionType(1), equals(QuestionType.multiChoice));
      });

      test('parses string with multiple choice', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseQuestionType('multiple choice'), equals(QuestionType.multiChoice));
      });

      test('parses string with short answer', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseQuestionType('short answer'), equals(QuestionType.typedAnswer));
      });

      test('parses string with essay', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseQuestionType('essay'), equals(QuestionType.essay));
      });

      test('defaults to single choice for unknown', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseQuestionType('unknown'), equals(QuestionType.singleChoice));
      });
    });

    group('_parseLessonBlocks', () {
      test('parses valid JSON array', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final response = '''
        [
          {"id": "b1", "type": "text", "content": "Content 1", "order": 1},
          {"id": "b2", "type": "example", "content": "Example 1", "order": 2}
        ]
        ''';

        final blocks = service._parseLessonBlocks(response, 'math');

        expect(blocks.length, equals(2));
      });

      test('handles invalid JSON', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final blocks = service._parseLessonBlocks('invalid json', 'math');

        expect(blocks, isEmpty);
      });
    });

    group('_parseLessonBlockType', () {
      test('parses integer index', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseLessonBlockType(0), equals(LessonBlockType.text));
        expect(service._parseLessonBlockType(1), equals(LessonBlockType.example));
      });

      test('parses string types', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseLessonBlockType('text'), equals(LessonBlockType.text));
        expect(service._parseLessonBlockType('example'), equals(LessonBlockType.example));
        expect(service._parseLessonBlockType('exercise'), equals(LessonBlockType.exercise));
        expect(service._parseLessonBlockType('slide'), equals(LessonBlockType.slide));
        expect(service._parseLessonBlockType('quiz'), equals(LessonBlockType.quiz));
        expect(service._parseLessonBlockType('summary'), equals(LessonBlockType.summary));
      });

      test('defaults to text for unknown', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        expect(service._parseLessonBlockType('unknown'), equals(LessonBlockType.text));
      });
    });

    group('_getMockQuestions', () {
      test('generates correct number of questions', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final questions = service._getMockQuestions('Algebra', 5, 2, 'math');

        expect(questions.length, equals(5));
      });

      test('all questions have correct subjectId', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final questions = service._getMockQuestions('Algebra', 3, 2, 'math');

        for (final q in questions) {
          expect(q.subjectId, equals('math'));
        }
      });
    });

    group('_getMockLessonBlocks', () {
      test('returns three blocks', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final blocks = service._getMockLessonBlocks('math');

        expect(blocks.length, equals(3));
      });

      test('blocks have different types', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final blocks = service._getMockLessonBlocks('math');

        final types = blocks.map((b) => b.type).toSet();
        expect(types.length, greaterThan(1));
      });
    });

    group('_getMockLesson', () {
      test('creates lesson with correct fields', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final lesson = service._getMockLesson('Test Title', 'math', 'topic1', 2);

        expect(lesson.title, equals('Test Title'));
        expect(lesson.subjectId, equals('math'));
        expect(lesson.topicId, equals('topic1'));
        expect(lesson.difficulty, equals(2));
        expect(lesson.generatedBy, equals(GeneratedBy.ai));
      });

      test('lesson has blocks', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final lesson = service._getMockLesson('Test Title', 'math', 'topic1', 2);

        expect(lesson.blocks.isNotEmpty, isTrue);
      });
    });

    group('_mockValidateAnswer', () {
      test('returns string containing subjectId', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final result = service._mockValidateAnswer('math');

        expect(result, contains('math'));
      });
    });

    group('_mockStudyPlan', () {
      test('returns plan with all fields', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final plan = service._mockStudyPlan('math', 'Algebra', 7, 2);

        expect(plan['subjectId'], equals('math'));
        expect(plan['course'], equals('Algebra'));
        expect(plan['days'], equals(7));
        expect(plan['hoursPerDay'], equals(2));
        expect(plan['schedule'], isA<List>());
      });

      test('schedule has entries', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final plan = service._mockStudyPlan('math', 'Algebra', 7, 2);

        expect((plan['schedule'] as List).isNotEmpty, isTrue);
      });
    });

    group('_getMockQuestionType', () {
      test('returns different types for different indices', () {
        const config = LlmConfiguration(
          provider: LlmProvider.openRouter,
          apiKey: 'test',
        );
        final service = LlmService(config: config);

        final type0 = service._getMockQuestionType(0);
        final type1 = service._getMockQuestionType(1);
        final type2 = service._getMockQuestionType(2);

        expect(type0, isA<QuestionType>());
        expect(type1, isA<QuestionType>());
        expect(type2, isA<QuestionType>());
      });
    });

    group('LlmProvider', () {
      test('has openRouter value', () {
        expect(LlmProvider.openRouter, isA<LlmProvider>());
      });

      test('has ollama value', () {
        expect(LlmProvider.ollama, isA<LlmProvider>());
      });
    });
  });
}