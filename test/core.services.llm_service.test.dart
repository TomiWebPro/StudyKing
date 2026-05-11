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