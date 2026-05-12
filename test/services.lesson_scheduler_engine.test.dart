import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/services/lesson_scheduler_engine.dart';
import 'package:studyking/services/graph_type_detector.dart';

void main() {
  group('LessonSchedulerCommands', () {
    late LessonSchedulerCommands commands;

    setUp(() {
      commands = LessonSchedulerCommands();
    });

    test('initializes with empty mcqOptionsRange', () {
      expect(commands.mcqOptionsRange, isEmpty);
    });

    group('getMcqOptionsCount', () {
      test('returns default 5 for unknown lesson type', () {
        final count = commands.getMcqOptionsCount('unknown');
        expect(count, equals(5));
      });

      test('returns configured count for known type', () async {
        await commands.fetchMcqOptionsRange();
        final count = commands.getMcqOptionsCount('test');
        expect(count, isA<int>());
      });
    });

    group('fetchMcqOptionsRange', () {
      test('handles fetch without throwing', () async {
        expect(() => commands.fetchMcqOptionsRange(), returnsNormally);
      });

      test('updates mcqOptionsRange after fetch', () async {
        await commands.fetchMcqOptionsRange();
        expect(commands.mcqOptionsRange, isA<Map<String, int>>());
      });
    });

    group('generateMcqQuestion', () {
      test('generates question with required fields', () async {
        final question = await commands.generateMcqQuestion(
          question: 'What is 2+2?',
          sourceMaterial: 'math',
        );
        expect(question['question'], equals('What is 2+2?'));
        expect(question.containsKey('options'), isTrue);
        expect(question.containsKey('answer'), isTrue);
        expect(question.containsKey('topic'), isTrue);
      });

      test('generates question with custom options count', () async {
        final question = await commands.generateMcqQuestion(
          question: 'Test?',
          sourceMaterial: 'mat',
          numOptions: 4,
        );
        expect(question['options'], isA<List>());
      });

      test('sets dynamic topic', () async {
        final question = await commands.generateMcqQuestion(
          question: 'Test?',
          sourceMaterial: 'source',
        );
        expect(question['topic'], equals('dynamic_topic'));
      });

      test('generates non-empty options', () async {
        final question = await commands.generateMcqQuestion(
          question: 'Test?',
          sourceMaterial: 'mat',
        );
        final options = question['options'] as List<String>;
        expect(options, isNotEmpty);
      });
    });

    group('generateOption', () {
      test('returns option with default text', () async {
        final option = await commands.generateOption();
        expect(option, equals('Option'));
      });

      test('returns option with custom text', () async {
        final option = await commands.generateOption(text: 'Custom Option');
        expect(option, equals('Custom Option'));
      });

      test('returns option with answer parameter', () async {
        final option = await commands.generateOption(answer: 'Answer');
        expect(option, isA<String>());
      });

      test('prefers text over answer', () async {
        final option = await commands.generateOption(text: 'Text', answer: 'Answer');
        expect(option, equals('Text'));
      });
    });
  });

  group('GraphRenderingService', () {
    late GraphRenderingService service;

    setUp(() {
      service = GraphRenderingService();
    });

    test('creates instance', () {
      expect(service, isNotNull);
    });

    group('generateGraphFromStory', () {
      test('handles API errors gracefully', () async {
        try {
          final graph = await service.generateGraphFromStory(
            story: 'A story about data',
            theme: 'science',
          );
          expect(graph, isA<Map<String, dynamic>>());
        } catch (e) {
          expect(e, isA<GraphError>());
        }
      });
    });
  });
}
